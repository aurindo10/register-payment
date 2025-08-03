package service

import (
	"database/sql"
	"errors"
	"register-payment/internal/dto"
	"register-payment/internal/entity"
	"register-payment/internal/repository"
)

type TransactionService interface {
	CreateTransaction(req *dto.TransactionRequest) (*dto.TransactionResponse, error)
	GetTransaction(id int) (*dto.TransactionResponse, error)
	GetTransactionByID(transactionID string) (*dto.TransactionResponse, error)
	GetTransactionsByCompany(externalCompanyID string) ([]*dto.TransactionResponse, error)
	ListTransactions(limit, offset int) ([]*dto.TransactionResponse, error)
	UpdateTransaction(id int, req *dto.TransactionRequest) (*dto.TransactionResponse, error)
	DeleteTransaction(id int) error
}

type transactionService struct {
	repo repository.TransactionRepository
}

func NewTransactionService(repo repository.TransactionRepository) TransactionService {
	return &transactionService{repo: repo}
}

func (s *transactionService) CreateTransaction(req *dto.TransactionRequest) (*dto.TransactionResponse, error) {
	existing, err := s.repo.GetByTransactionID(req.TransactionID)
	if err != nil && err != sql.ErrNoRows {
		return nil, err
	}
	if existing != nil {
		return nil, errors.New("transaction with this ID already exists")
	}

	transaction := &entity.Transaction{
		TransactionID:     req.TransactionID,
		Value:             req.Value,
		Type:              req.Type,
		ExternalCompanyID: req.ExternalCompanyID,
		Description:       req.Description,
	}

	if err := s.repo.Create(transaction); err != nil {
		return nil, err
	}

	return s.entityToResponse(transaction), nil
}

func (s *transactionService) GetTransaction(id int) (*dto.TransactionResponse, error) {
	transaction, err := s.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("transaction not found")
		}
		return nil, err
	}

	return s.entityToResponse(transaction), nil
}

func (s *transactionService) GetTransactionByID(transactionID string) (*dto.TransactionResponse, error) {
	transaction, err := s.repo.GetByTransactionID(transactionID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("transaction not found")
		}
		return nil, err
	}

	return s.entityToResponse(transaction), nil
}

func (s *transactionService) GetTransactionsByCompany(externalCompanyID string) ([]*dto.TransactionResponse, error) {
	transactions, err := s.repo.GetByExternalCompanyID(externalCompanyID)
	if err != nil {
		return nil, err
	}

	var responses []*dto.TransactionResponse
	for _, transaction := range transactions {
		responses = append(responses, s.entityToResponse(transaction))
	}

	return responses, nil
}

func (s *transactionService) ListTransactions(limit, offset int) ([]*dto.TransactionResponse, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	transactions, err := s.repo.List(limit, offset)
	if err != nil {
		return nil, err
	}

	var responses []*dto.TransactionResponse
	for _, transaction := range transactions {
		responses = append(responses, s.entityToResponse(transaction))
	}

	return responses, nil
}

func (s *transactionService) UpdateTransaction(id int, req *dto.TransactionRequest) (*dto.TransactionResponse, error) {
	existing, err := s.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("transaction not found")
		}
		return nil, err
	}

	if existing.TransactionID != req.TransactionID {
		duplicate, err := s.repo.GetByTransactionID(req.TransactionID)
		if err != nil && err != sql.ErrNoRows {
			return nil, err
		}
		if duplicate != nil {
			return nil, errors.New("transaction with this ID already exists")
		}
	}

	existing.TransactionID = req.TransactionID
	existing.Value = req.Value
	existing.Type = req.Type
	existing.ExternalCompanyID = req.ExternalCompanyID
	existing.Description = req.Description

	if err := s.repo.Update(existing); err != nil {
		return nil, err
	}

	return s.entityToResponse(existing), nil
}

func (s *transactionService) DeleteTransaction(id int) error {
	_, err := s.repo.GetByID(id)
	if err != nil {
		if err == sql.ErrNoRows {
			return errors.New("transaction not found")
		}
		return err
	}

	return s.repo.Delete(id)
}

func (s *transactionService) entityToResponse(transaction *entity.Transaction) *dto.TransactionResponse {
	return &dto.TransactionResponse{
		ID:                transaction.ID,
		TransactionID:     transaction.TransactionID,
		Value:             transaction.Value,
		Type:              transaction.Type,
		ExternalCompanyID: transaction.ExternalCompanyID,
		Description:       transaction.Description,
		CreatedAt:         transaction.CreatedAt,
		UpdatedAt:         transaction.UpdatedAt,
	}
}