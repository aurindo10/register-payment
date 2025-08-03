package entity

import (
	"register-payment/pkg/money"
	"time"
)

type Transaction struct {
	ID                int         `db:"id" json:"id"`
	TransactionID     string      `db:"transaction_id" json:"transaction_id"`
	Value             money.Money `db:"value" json:"value"`
	Type              string      `db:"type" json:"type"`
	ExternalCompanyID string      `db:"external_company_id" json:"external_company_id"`
	Description       string      `db:"description" json:"description"`
	CreatedAt         time.Time   `db:"created_at" json:"created_at"`
	UpdatedAt         time.Time   `db:"updated_at" json:"updated_at"`
}