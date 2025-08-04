package rabbitmq

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Publisher struct {
	conn     *Connection
	exchange string
}

func NewPublisher(conn *Connection, exchange string) *Publisher {
	return &Publisher{
		conn:     conn,
		exchange: exchange,
	}
}

func (p *Publisher) PublishJSON(ctx context.Context, routingKey string, message interface{}) error {
	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	return p.conn.ch.PublishWithContext(
		ctx,
		p.exchange,
		routingKey,
		false, // mandatory
		false, // immediate
		amqp.Publishing{
			ContentType:  "application/json",
			Body:         body,
			Timestamp:    time.Now(),
			DeliveryMode: amqp.Persistent, // Make message persistent
		},
	)
}

func (p *Publisher) Publish(ctx context.Context, routingKey string, body []byte, contentType string) error {
	return p.conn.ch.PublishWithContext(
		ctx,
		p.exchange,
		routingKey,
		false, // mandatory
		false, // immediate
		amqp.Publishing{
			ContentType:  contentType,
			Body:         body,
			Timestamp:    time.Now(),
			DeliveryMode: amqp.Persistent, // Make message persistent
		},
	)
}