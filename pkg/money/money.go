package money

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
)

// Money represents monetary values using integers to avoid floating-point precision issues
// Stores values in cents (smallest currency unit) as int64
type Money struct {
	cents int64
}

// NewMoney creates a new Money instance from a floating-point value (dollars)
func NewMoney(amount float64) Money {
	return Money{cents: int64(math.Round(amount * 100))}
}

// NewMoneyFromCents creates a new Money instance directly from cents
func NewMoneyFromCents(cents int64) Money {
	return Money{cents: cents}
}

// NewMoneyFromString creates a new Money instance from a string representation
func NewMoneyFromString(s string) (Money, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return Money{}, errors.New("empty string")
	}

	amount, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return Money{}, fmt.Errorf("invalid money format: %w", err)
	}

	return NewMoney(amount), nil
}

// Cents returns the value in cents
func (m Money) Cents() int64 {
	return m.cents
}

// Float64 returns the value as a float64 (dollars)
func (m Money) Float64() float64 {
	return float64(m.cents) / 100.0
}

// String returns a string representation of the money value
func (m Money) String() string {
	dollars := m.cents / 100
	cents := m.cents % 100
	if cents < 0 {
		cents = -cents
	}
	return fmt.Sprintf("%d.%02d", dollars, cents)
}

// Add adds another Money value to this one
func (m Money) Add(other Money) Money {
	return Money{cents: m.cents + other.cents}
}

// Subtract subtracts another Money value from this one
func (m Money) Subtract(other Money) Money {
	return Money{cents: m.cents - other.cents}
}

// Multiply multiplies the money value by a factor
func (m Money) Multiply(factor float64) Money {
	return Money{cents: int64(math.Round(float64(m.cents) * factor))}
}

// Divide divides the money value by a divisor
func (m Money) Divide(divisor float64) Money {
	if divisor == 0 {
		return Money{cents: 0}
	}
	return Money{cents: int64(math.Round(float64(m.cents) / divisor))}
}

// IsZero returns true if the money value is zero
func (m Money) IsZero() bool {
	return m.cents == 0
}

// IsPositive returns true if the money value is positive
func (m Money) IsPositive() bool {
	return m.cents > 0
}

// IsNegative returns true if the money value is negative
func (m Money) IsNegative() bool {
	return m.cents < 0
}

// Abs returns the absolute value of the money
func (m Money) Abs() Money {
	if m.cents < 0 {
		return Money{cents: -m.cents}
	}
	return m
}

// Equal checks if two Money values are equal
func (m Money) Equal(other Money) bool {
	return m.cents == other.cents
}

// GreaterThan checks if this Money is greater than another
func (m Money) GreaterThan(other Money) bool {
	return m.cents > other.cents
}

// LessThan checks if this Money is less than another
func (m Money) LessThan(other Money) bool {
	return m.cents < other.cents
}

// MarshalJSON implements json.Marshaler interface
func (m Money) MarshalJSON() ([]byte, error) {
	return json.Marshal(m.String())
}

// UnmarshalJSON implements json.Unmarshaler interface
func (m *Money) UnmarshalJSON(data []byte) error {
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return err
	}

	money, err := NewMoneyFromString(s)
	if err != nil {
		return err
	}

	*m = money
	return nil
}

// Value implements driver.Valuer interface for database storage
func (m Money) Value() (driver.Value, error) {
	return m.cents, nil
}

// Scan implements sql.Scanner interface for database retrieval
func (m *Money) Scan(value interface{}) error {
	if value == nil {
		m.cents = 0
		return nil
	}

	switch v := value.(type) {
	case int64:
		m.cents = v
	case int:
		m.cents = int64(v)
	case float64:
		m.cents = int64(math.Round(v))
	default:
		return fmt.Errorf("cannot scan %T into Money", value)
	}

	return nil
}