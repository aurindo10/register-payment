package handler

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/http"
	"register-payment/internal/dto"
	"register-payment/internal/service"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type QStashHandler struct {
	transactionService service.TransactionService
	currentSigningKey  string
	nextSigningKey     string
}

func NewQStashHandler(transactionService service.TransactionService, currentKey, nextKey string) *QStashHandler {
	return &QStashHandler{
		transactionService: transactionService,
		currentSigningKey:  currentKey,
		nextSigningKey:     nextKey,
	}
}

func (h *QStashHandler) HandleTransaction(c *gin.Context) {
	if !h.verifySignature(c) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid signature"})
		return
	}

	var payload dto.QStashWebhookPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	transaction, err := h.transactionService.CreateTransaction(&payload.Data)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

	c.JSON(http.StatusCreated, transaction)
}

func (h *QStashHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"timestamp": time.Now().UTC(),
		"service":   "register-payment",
	})
}

func (h *QStashHandler) verifySignature(c *gin.Context) bool {
	signature := c.GetHeader("Upstash-Signature")
	if signature == "" {
		return false
	}

	body, err := c.GetRawData()
	if err != nil {
		return false
	}

	c.Set("body", body)

	return h.verifyJWTSignature(signature, body) || h.verifyHMACSignature(signature, body)
}

func (h *QStashHandler) verifyJWTSignature(signature string, body []byte) bool {
	token, err := jwt.Parse(signature, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(h.currentSigningKey), nil
	})

	if err != nil && h.nextSigningKey != "" {
		token, err = jwt.Parse(signature, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(h.nextSigningKey), nil
		})
	}

	if err != nil || !token.Valid {
		return false
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return false
	}

	bodyHash, ok := claims["body"].(string)
	if !ok {
		return false
	}

	expectedHash := h.sha256Hash(body)
	return bodyHash == expectedHash
}

func (h *QStashHandler) verifyHMACSignature(signature string, body []byte) bool {
	parts := strings.Split(signature, ",")
	for _, part := range parts {
		if strings.HasPrefix(part, "v1=") {
			providedSignature := strings.TrimPrefix(part, "v1=")
			
			expectedSignature := h.computeHMAC(body, h.currentSigningKey)
			if hmac.Equal([]byte(providedSignature), []byte(expectedSignature)) {
				return true
			}

			if h.nextSigningKey != "" {
				expectedSignature = h.computeHMAC(body, h.nextSigningKey)
				if hmac.Equal([]byte(providedSignature), []byte(expectedSignature)) {
					return true
				}
			}
		}
	}
	return false
}

func (h *QStashHandler) computeHMAC(body []byte, key string) string {
	mac := hmac.New(sha256.New, []byte(key))
	mac.Write(body)
	return base64.StdEncoding.EncodeToString(mac.Sum(nil))
}

func (h *QStashHandler) sha256Hash(body []byte) string {
	hash := sha256.Sum256(body)
	return base64.StdEncoding.EncodeToString(hash[:])
}