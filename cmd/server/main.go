package main

import (
	"log"
	"register-payment/internal/config"
	"register-payment/internal/handler"
	"register-payment/internal/repository"
	"register-payment/internal/service"
	"register-payment/pkg/database"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	cfg := config.Load()

	if cfg.QStash.CurrentSigningKey == "" {
		log.Fatal("QSTASH_CURRENT_SIGNING_KEY is required")
	}

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

	transactionRepo := repository.NewTransactionRepository(db.DB)
	transactionService := service.NewTransactionService(transactionRepo)
	qstashHandler := handler.NewQStashHandler(
		transactionService,
		cfg.QStash.CurrentSigningKey,
		cfg.QStash.NextSigningKey,
	)

	router := gin.New()
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	api := router.Group("/api/v1")
	{
		webhooks := api.Group("/webhooks/qstash")
		{
			webhooks.POST("/transaction", qstashHandler.HandleTransaction)
			webhooks.GET("/health", qstashHandler.HealthCheck)
		}
	}

	log.Printf("Server starting on port %s", cfg.Server.Port)
	if err := router.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}