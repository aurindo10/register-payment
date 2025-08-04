package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"register-payment/internal/config"
	"register-payment/internal/handler"
	"register-payment/internal/repository"
	"register-payment/internal/service"
	"register-payment/pkg/database"
	"register-payment/pkg/rabbitmq"
	"syscall"
	"time"
)

func main() {
	log.Println("Starting Transaction Consumer Worker...")

	cfg := config.Load()

	// Connect to database
	dbConfig := database.Config{
		Host:     cfg.Database.Host,
		Port:     cfg.Database.Port,
		User:     cfg.Database.User,
		Password: cfg.Database.Password,
		DBName:   cfg.Database.DBName,
		SSLMode:  cfg.Database.SSLMode,
	}

	db, err := database.NewPostgresDB(dbConfig)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Connect to RabbitMQ for consuming
	rabbitConfig := rabbitmq.Config{
		URL:        cfg.RabbitMQ.URL,
		MaxRetries: 5,
		RetryDelay: 5 * time.Second,
	}

	rabbitConn, err := rabbitmq.NewConnection(rabbitConfig)
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %v", err)
	}
	defer rabbitConn.Close()

	// Ensure queue exists (idempotent)
	_, err = rabbitConn.DeclareQueue(cfg.RabbitMQ.Queue, true, false, false, false, nil)
	if err != nil {
		log.Fatalf("Failed to declare queue: %v", err)
	}

	// Initialize services (Consumer only needs write operations)
	transactionRepo := repository.NewTransactionRepository(db.DB)
	transactionService := service.NewTransactionService(transactionRepo)
	consumerHandler := handler.NewConsumerHandler(transactionService)

	// Start RabbitMQ consumer
	consumer := rabbitmq.NewConsumer(rabbitConn, cfg.RabbitMQ.Queue, consumerHandler.ProcessTransaction)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err := consumer.Start(ctx); err != nil {
		log.Fatalf("Failed to start consumer: %v", err)
	}

	log.Printf("Consumer started, processing transactions from queue: %s", cfg.RabbitMQ.Queue)

	// Optional: Start health check server
	go startHealthServer(consumerHandler, cfg.Server.Port)

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down consumer...")
	cancel() // Stop RabbitMQ consumer
	
	// Allow graceful shutdown
	time.Sleep(2 * time.Second)
	log.Println("Consumer stopped")
}

func startHealthServer(handler *handler.ConsumerHandler, port string) {
	// Simple health check server for the consumer
	// This allows monitoring tools to check if the consumer is alive
	log.Printf("Consumer health server starting on port %s", port)
	
	// This would start a minimal HTTP server for health checks
	// Implementation depends on your monitoring requirements
}