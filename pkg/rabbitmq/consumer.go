package rabbitmq

import (
	"context"
	"encoding/json"
	"log"

	amqp "github.com/rabbitmq/amqp091-go"
)

type MessageHandler func(ctx context.Context, body []byte) error

type Consumer struct {
	conn    *Connection
	queue   string
	handler MessageHandler
}

func NewConsumer(conn *Connection, queue string, handler MessageHandler) *Consumer {
	return &Consumer{
		conn:    conn,
		queue:   queue,
		handler: handler,
	}
}

func (c *Consumer) Start(ctx context.Context) error {
	msgs, err := c.conn.ch.Consume(
		c.queue,
		"",    // consumer tag
		false, // auto-ack (we'll manually ack after processing)
		false, // exclusive
		false, // no-local
		false, // no-wait
		nil,   // args
	)
	if err != nil {
		return err
	}

	log.Printf("Consumer started for queue: %s", c.queue)

	go func() {
		for {
			select {
			case <-ctx.Done():
				log.Printf("Consumer stopping for queue: %s", c.queue)
				return
			case delivery, ok := <-msgs:
				_ = amqp.Delivery{} // Force usage of amqp import
				if !ok {
					log.Printf("Consumer channel closed for queue: %s", c.queue)
					return
				}

				if err := c.handler(ctx, delivery.Body); err != nil {
					log.Printf("Error processing message: %v", err)
					if nackErr := delivery.Nack(false, true); nackErr != nil {
						log.Printf("Failed to nack message: %v", nackErr)
					}
				} else {
					if ackErr := delivery.Ack(false); ackErr != nil {
						log.Printf("Failed to ack message: %v", ackErr)
					}
				}
			}
		}
	}()

	return nil
}

func (c *Consumer) StartJSONConsumer(ctx context.Context, handler func(ctx context.Context, message interface{}) error, messageType interface{}) error {
	jsonHandler := func(ctx context.Context, body []byte) error {
		if err := json.Unmarshal(body, messageType); err != nil {
			return err
		}
		return handler(ctx, messageType)
	}

	c.handler = jsonHandler
	return c.Start(ctx)
}