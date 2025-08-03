package repository

import (
	"database/sql"
	"register-payment/internal/entity"
	"time"
)

type TransactionRepository interface {
	Create(transaction *entity.Transaction) error
	GetByID(id int) (*entity.Transaction, error)
	GetByTransactionID(transactionID string) (*entity.Transaction, error)
	GetByExternalCompanyID(externalCompanyID string) ([]*entity.Transaction, error)
	List(limit, offset int) ([]*entity.Transaction, error)
	Update(transaction *entity.Transaction) error
	Delete(id int) error
}

type transactionRepository struct {
	db *sql.DB
}

func NewTransactionRepository(db *sql.DB) TransactionRepository {
	return &transactionRepository{db: db}
}

func (r *transactionRepository) Create(transaction *entity.Transaction) error {
	query := `
		INSERT INTO transactions (transaction_id, value, type, external_company_id, description, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at`

	now := time.Now()
	transaction.CreatedAt = now
	transaction.UpdatedAt = now

	return r.db.QueryRow(
		query,
		transaction.TransactionID,
		transaction.Value,
		transaction.Type,
		transaction.ExternalCompanyID,
		transaction.Description,
		transaction.CreatedAt,
		transaction.UpdatedAt,
	).Scan(&transaction.ID, &transaction.CreatedAt, &transaction.UpdatedAt)
}

func (r *transactionRepository) GetByID(id int) (*entity.Transaction, error) {
	query := `
		SELECT id, transaction_id, value, type, external_company_id, description, created_at, updated_at
		FROM transactions
		WHERE id = $1`

	transaction := &entity.Transaction{}
	err := r.db.QueryRow(query, id).Scan(
		&transaction.ID,
		&transaction.TransactionID,
		&transaction.Value,
		&transaction.Type,
		&transaction.ExternalCompanyID,
		&transaction.Description,
		&transaction.CreatedAt,
		&transaction.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return transaction, nil
}

func (r *transactionRepository) GetByTransactionID(transactionID string) (*entity.Transaction, error) {
	query := `
		SELECT id, transaction_id, value, type, external_company_id, description, created_at, updated_at
		FROM transactions
		WHERE transaction_id = $1`

	transaction := &entity.Transaction{}
	err := r.db.QueryRow(query, transactionID).Scan(
		&transaction.ID,
		&transaction.TransactionID,
		&transaction.Value,
		&transaction.Type,
		&transaction.ExternalCompanyID,
		&transaction.Description,
		&transaction.CreatedAt,
		&transaction.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return transaction, nil
}

func (r *transactionRepository) GetByExternalCompanyID(externalCompanyID string) ([]*entity.Transaction, error) {
	query := `
		SELECT id, transaction_id, value, type, external_company_id, description, created_at, updated_at
		FROM transactions
		WHERE external_company_id = $1
		ORDER BY created_at DESC`

	rows, err := r.db.Query(query, externalCompanyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []*entity.Transaction
	for rows.Next() {
		transaction := &entity.Transaction{}
		err := rows.Scan(
			&transaction.ID,
			&transaction.TransactionID,
			&transaction.Value,
			&transaction.Type,
			&transaction.ExternalCompanyID,
			&transaction.Description,
			&transaction.CreatedAt,
			&transaction.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, transaction)
	}

	return transactions, nil
}

func (r *transactionRepository) List(limit, offset int) ([]*entity.Transaction, error) {
	query := `
		SELECT id, transaction_id, value, type, external_company_id, description, created_at, updated_at
		FROM transactions
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2`

	rows, err := r.db.Query(query, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var transactions []*entity.Transaction
	for rows.Next() {
		transaction := &entity.Transaction{}
		err := rows.Scan(
			&transaction.ID,
			&transaction.TransactionID,
			&transaction.Value,
			&transaction.Type,
			&transaction.ExternalCompanyID,
			&transaction.Description,
			&transaction.CreatedAt,
			&transaction.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, transaction)
	}

	return transactions, nil
}

func (r *transactionRepository) Update(transaction *entity.Transaction) error {
	query := `
		UPDATE transactions
		SET value = $2, type = $3, external_company_id = $4, description = $5, updated_at = $6
		WHERE id = $1
		RETURNING updated_at`

	transaction.UpdatedAt = time.Now()

	return r.db.QueryRow(
		query,
		transaction.ID,
		transaction.Value,
		transaction.Type,
		transaction.ExternalCompanyID,
		transaction.Description,
		transaction.UpdatedAt,
	).Scan(&transaction.UpdatedAt)
}

func (r *transactionRepository) Delete(id int) error {
	query := `DELETE FROM transactions WHERE id = $1`
	_, err := r.db.Exec(query, id)
	return err
}