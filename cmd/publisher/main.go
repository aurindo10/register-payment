package main

import (
	"log"
	"register-payment/internal/config"
	"register-payment/internal/handler"
	"register-payment/pkg/money"
	"register-payment/pkg/rabbitmq"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"
	"github.com/joho/godotenv"
)

func main() {
	log.Println("Starting Transaction Publisher API...")

	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	cfg := config.Load()

	// Register custom Money validators
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		money.RegisterValidators(v)
	}

	// Setup HTTP server first to pass health checks
	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// Initialize publisher handler with nil publisher initially
	var publisherHandler *handler.PublisherHandler

	// Connect to RabbitMQ for publishing only (with retry in background)
	rabbitConfig := rabbitmq.Config{
		URL:        cfg.RabbitMQ.URL,
		MaxRetries: 10,
		RetryDelay: 10 * time.Second,
	}

	// Try to connect to RabbitMQ, but don't fail startup if unavailable
	rabbitConn, err := rabbitmq.NewConnection(rabbitConfig)
	if err != nil {
		log.Printf("Warning: Failed to connect to RabbitMQ on startup: %v", err)
		log.Println("Publisher will retry connection in background...")
		publisherHandler = handler.NewPublisherHandler(nil) // Start with nil publisher
	} else {
		// Declare exchange and queue (idempotent operations)
		err = rabbitConn.DeclareExchange(cfg.RabbitMQ.Exchange, "direct", true, false, false, false, nil)
		if err != nil {
			log.Printf("Warning: Failed to declare exchange: %v", err)
		}

		_, err = rabbitConn.DeclareQueue(cfg.RabbitMQ.Queue, true, false, false, false, nil)
		if err != nil {
			log.Printf("Warning: Failed to declare queue: %v", err)
		}

		err = rabbitConn.BindQueue(cfg.RabbitMQ.Queue, "transaction.register", cfg.RabbitMQ.Exchange, false, nil)
		if err != nil {
			log.Printf("Warning: Failed to bind queue: %v", err)
		}

		// Initialize publisher
		publisher := rabbitmq.NewPublisher(rabbitConn, cfg.RabbitMQ.Exchange)
		publisherHandler = handler.NewPublisherHandler(publisher)
		defer rabbitConn.Close()
	}

	// Publisher API routes
	api := router.Group("/api/v1")
	{
		transactions := api.Group("/transactions")
		{
			// Only publishing endpoint - no database reads
			transactions.POST("/", publisherHandler.PublishTransaction)
		}
		api.GET("/health", publisherHandler.HealthCheck)
		api.GET("/metrics", publisherHandler.GetMetrics)
	}

	log.Printf("Transaction Publisher API starting on 0.0.0.0:%s", cfg.Server.Port)
	if err := router.Run("0.0.0.0:" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start publisher API: %v", err)
	}
}