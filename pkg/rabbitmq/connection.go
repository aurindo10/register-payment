package rabbitmq

import (
	"fmt"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Config struct {
	URL          string
	MaxRetries   int
	RetryDelay   time.Duration
}

type Connection struct {
	conn *amqp.Connection
	ch   *amqp.Channel
	cfg  Config
}

func NewConnection(cfg Config) (*Connection, error) {
	if cfg.MaxRetries == 0 {
		cfg.MaxRetries = 5
	}
	if cfg.RetryDelay == 0 {
		cfg.RetryDelay = 5 * time.Second
	}

	var conn *amqp.Connection
	var err error

	for i := 0; i < cfg.MaxRetries; i++ {
		conn, err = amqp.Dial(cfg.URL)
		if err == nil {
			break
		}
		log.Printf("Failed to connect to RabbitMQ (attempt %d/%d): %v", i+1, cfg.MaxRetries, err)
		time.Sleep(cfg.RetryDelay)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ after %d attempts: %w", cfg.MaxRetries, err)
	}

	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to open channel: %w", err)
	}

	log.Println("Successfully connected to RabbitMQ")

	return &Connection{
		conn: conn,
		ch:   ch,
		cfg:  cfg,
	}, nil
}

func (c *Connection) Close() error {
	if c.ch != nil {
		c.ch.Close()
	}
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

func (c *Connection) Channel() *amqp.Channel {
	return c.ch
}

func (c *Connection) IsClosed() bool {
	return c.conn.IsClosed()
}

func (c *Connection) DeclareQueue(name string, durable, autoDelete, exclusive, noWait bool, args amqp.Table) (amqp.Queue, error) {
	return c.ch.QueueDeclare(name, durable, autoDelete, exclusive, noWait, args)
}

func (c *Connection) DeclareExchange(name, kind string, durable, autoDelete, internal, noWait bool, args amqp.Table) error {
	return c.ch.ExchangeDeclare(name, kind, durable, autoDelete, internal, noWait, args)
}

func (c *Connection) BindQueue(queueName, key, exchange string, noWait bool, args amqp.Table) error {
	return c.ch.QueueBind(queueName, key, exchange, noWait, args)
}