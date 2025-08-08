package main

import (
	"database/sql"
	"flag"
	"log"
    "os"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

func main() {
	var direction = flag.String("direction", "up", "Migration direction: up or down")
	flag.Parse()

    // Prefer DATABASE_URL; fallback to POSTGRES_* vars
    dsn := os.Getenv("DATABASE_URL")
    if dsn == "" {
        host := getEnv("POSTGRES_HOST", "localhost")
        port := getEnv("POSTGRES_PORT", "5432")
        user := getEnv("POSTGRES_USER", "postgres")
        pass := getEnv("POSTGRES_PASSWORD", "")
        dbname := getEnv("POSTGRES_DB", "register_payment")
        sslmode := getEnv("POSTGRES_SSL_MODE", "disable")
        dsn = "postgres://" + user + ":" + pass + "@" + host + ":" + port + "/" + dbname + "?sslmode=" + sslmode
    }

    db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatal(err)
	}

	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatal(err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres", driver)
	if err != nil {
		log.Fatal(err)
	}

	switch *direction {
	case "up":
		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
			log.Fatal(err)
		}
		log.Println("Migrations applied successfully")
	case "down":
		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
			log.Fatal(err)
		}
		log.Println("Migrations rolled back successfully")
	default:
		log.Fatal("Invalid direction. Use 'up' or 'down'")
	}
}

func getEnv(key, def string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return def
}