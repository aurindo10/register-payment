package handler

import (
	"context"
	"encoding/json"
	"log"
	"register-payment/internal/dto"
	"register-payment/internal/service"
	"sync/atomic"
	"time"
)

type ConsumerHandler struct {
	transactionService service.TransactionService
	metrics           ConsumerMetrics
	startTime         time.Time
}

type ConsumerMetrics struct {
	TotalProcessed     int64 `json:"total_processed"`
	SuccessCount       int64 `json:"success_count"`
	ErrorCount         int64 `json:"error_count"`
	LastProcessedTime  int64 `json:"last_processed_time"`
	ProcessingErrors   []ProcessingError `json:"recent_errors"`
}

type ProcessingError struct {
	Timestamp   time.Time `json:"timestamp"`
	Error       string    `json:"error"`
	MessageData string    `json:"message_data,omitempty"`
}

func NewConsumerHandler(transactionService service.TransactionService) *ConsumerHandler {
	return &ConsumerHandler{
		transactionService: transactionService,
		metrics: ConsumerMetrics{
			ProcessingErrors: make([]ProcessingError, 0, 10), // Keep last 10 errors
		},
		startTime: time.Now(),
	}
}

// ProcessTransaction handles RabbitMQ messages for transaction processing
func (h *ConsumerHandler) ProcessTransaction(ctx context.Context, body []byte) error {
	atomic.AddInt64(&h.metrics.TotalProcessed, 1)
	atomic.StoreInt64(&h.metrics.LastProcessedTime, time.Now().Unix())

	var req dto.TransactionRequest
	if err := json.Unmarshal(body, &req); err != nil {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		h.addError("Failed to unmarshal message", err.Error(), string(body))
		log.Printf("Failed to unmarshal transaction message: %v", err)
		return err
	}

	// Validate the transaction request
	if req.TransactionID == "" {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		h.addError("Invalid transaction", "Transaction ID is required", string(body))
		log.Printf("Invalid transaction: missing transaction ID")
		return nil // Don't requeue invalid messages
	}

	if req.Value.IsZero() {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		h.addError("Invalid transaction", "Transaction value must be greater than zero", string(body))
		log.Printf("Invalid transaction: zero value for transaction %s", req.TransactionID)
		return nil // Don't requeue invalid messages
	}

	// Process the transaction
	transaction, err := h.transactionService.CreateTransaction(&req)
	if err != nil {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		h.addError("Database error", err.Error(), req.TransactionID)
		log.Printf("Failed to create transaction %s: %v", req.TransactionID, err)
		return err // This will cause the message to be requeued
	}

	atomic.AddInt64(&h.metrics.SuccessCount, 1)
	log.Printf("Successfully processed transaction %s (ID: %d, Value: %s, Type: %s)", 
		transaction.TransactionID, 
		transaction.ID, 
		transaction.Value.String(), 
		transaction.Type)

	return nil
}

// GetMetrics returns processing metrics
func (h *ConsumerHandler) GetMetrics() ConsumerMetrics {
	return ConsumerMetrics{
		TotalProcessed:    atomic.LoadInt64(&h.metrics.TotalProcessed),
		SuccessCount:      atomic.LoadInt64(&h.metrics.SuccessCount),
		ErrorCount:        atomic.LoadInt64(&h.metrics.ErrorCount),
		LastProcessedTime: atomic.LoadInt64(&h.metrics.LastProcessedTime),
		ProcessingErrors:  h.metrics.ProcessingErrors,
	}
}

// GetUptime returns how long the consumer has been running
func (h *ConsumerHandler) GetUptime() time.Duration {
	return time.Since(h.startTime)
}

// IsHealthy returns true if the consumer is processing messages within a reasonable time
func (h *ConsumerHandler) IsHealthy() bool {
	lastProcessed := atomic.LoadInt64(&h.metrics.LastProcessedTime)
	if lastProcessed == 0 {
		// Haven't processed any messages yet, but that might be normal
		return time.Since(h.startTime) < 5*time.Minute
	}
	
	// Considered healthy if we processed a message in the last 5 minutes
	return time.Since(time.Unix(lastProcessed, 0)) < 5*time.Minute
}

func (h *ConsumerHandler) addError(errorType, errorMsg, context string) {
	error := ProcessingError{
		Timestamp:   time.Now(),
		Error:       errorType + ": " + errorMsg,
		MessageData: context,
	}

	// Keep only the last 10 errors (simple circular buffer)
	if len(h.metrics.ProcessingErrors) >= 10 {
		h.metrics.ProcessingErrors = h.metrics.ProcessingErrors[1:]
	}
	h.metrics.ProcessingErrors = append(h.metrics.ProcessingErrors, error)
}