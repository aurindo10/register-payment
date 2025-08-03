package dto

import (
	"time"
)

type TransactionRequest struct {
	TransactionID       string  `json:"transaction_id" binding:"required"`
	Value              float64 `json:"value" binding:"required,gt=0"`
	Type               string  `json:"type" binding:"required,oneof=in out"`
	ExternalCompanyID  string  `json:"external_company_id" binding:"required"`
	Description        string  `json:"description,omitempty"`
}

type TransactionResponse struct {
	ID                 int       `json:"id"`
	TransactionID      string    `json:"transaction_id"`
	Value              float64   `json:"value"`
	Type               string    `json:"type"`
	ExternalCompanyID  string    `json:"external_company_id"`
	Description        string    `json:"description,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

type QStashWebhookPayload struct {
	Data TransactionRequest `json:"data"`
}