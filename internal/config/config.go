package config

import (
	"os"
	"strconv"
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	QStash   QStashConfig
}

type ServerConfig struct {
	Port string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

type QStashConfig struct {
	CurrentSigningKey string
	NextSigningKey    string
}

func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("POSTGRES_HOST", "localhost"),
			Port:     getEnv("POSTGRES_PORT", "5432"),
			User:     getEnv("POSTGRES_USER", "postgres"),
			Password: getEnv("POSTGRES_PASSWORD", "optica123"),
			DBName:   getEnv("POSTGRES_DB", "optica-db"),
			SSLMode:  getEnv("POSTGRES_SSL_MODE", "disable"),
		},
		QStash: QStashConfig{
			CurrentSigningKey: getEnv("QSTASH_CURRENT_SIGNING_KEY", ""),
			NextSigningKey:    getEnv("QSTASH_NEXT_SIGNING_KEY", ""),
		},
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}