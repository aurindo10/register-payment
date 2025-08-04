package handler

import (
	"context"
	"net/http"
	"register-payment/internal/dto"
	"register-payment/pkg/rabbitmq"
	"sync/atomic"
	"time"

	"github.com/gin-gonic/gin"
)

type PublisherHandler struct {
	publisher *rabbitmq.Publisher
	metrics   PublisherMetrics
}

type PublisherMetrics struct {
	TotalRequests   int64 `json:"total_requests"`
	SuccessCount    int64 `json:"success_count"`
	ErrorCount      int64 `json:"error_count"`
	LastRequestTime int64 `json:"last_request_time"`
}

func NewPublisherHandler(publisher *rabbitmq.Publisher) *PublisherHandler {
	return &PublisherHandler{
		publisher: publisher,
		metrics:   PublisherMetrics{},
	}
}

// PublishTransaction publishes a transaction to RabbitMQ for processing
func (h *PublisherHandler) PublishTransaction(c *gin.Context) {
	atomic.AddInt64(&h.metrics.TotalRequests, 1)
	atomic.StoreInt64(&h.metrics.LastRequestTime, time.Now().Unix())

	var req dto.TransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid request payload",
			"details": err.Error(),
		})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Check if publisher is available
	if h.publisher == nil {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Message queue is currently unavailable",
			"status": "service_unavailable",
		})
		return
	}

	// Publish to RabbitMQ
	if err := h.publisher.PublishJSON(ctx, "transaction.register", req); err != nil {
		atomic.AddInt64(&h.metrics.ErrorCount, 1)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to publish transaction",
		})
		return
	}

	atomic.AddInt64(&h.metrics.SuccessCount, 1)

	c.JSON(http.StatusAccepted, gin.H{
		"message":        "Transaction queued for processing",
		"transaction_id": req.TransactionID,
		"status":         "queued",
		"timestamp":      time.Now().UTC(),
	})
}

// HealthCheck returns the health status of the publisher service
func (h *PublisherHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"service":   "transaction-publisher",
		"timestamp": time.Now().UTC(),
		"version":   "1.0.0",
	})
}

// GetMetrics returns publisher metrics
func (h *PublisherHandler) GetMetrics(c *gin.Context) {
	metrics := PublisherMetrics{
		TotalRequests:   atomic.LoadInt64(&h.metrics.TotalRequests),
		SuccessCount:    atomic.LoadInt64(&h.metrics.SuccessCount),
		ErrorCount:      atomic.LoadInt64(&h.metrics.ErrorCount),
		LastRequestTime: atomic.LoadInt64(&h.metrics.LastRequestTime),
	}

	c.JSON(http.StatusOK, gin.H{
		"metrics":   metrics,
		"uptime":    time.Since(time.Unix(metrics.LastRequestTime, 0)).String(),
		"timestamp": time.Now().UTC(),
	})
}