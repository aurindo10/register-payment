package money

import (
	"encoding/json"
	"testing"
)

func TestNewMoney(t *testing.T) {
	tests := []struct {
		name     string
		amount   float64
		expected int64
	}{
		{"positive amount", 123.45, 12345},
		{"negative amount", -123.45, -12345},
		{"zero amount", 0.0, 0},
		{"large amount", 999999.99, 99999999},
		{"rounding", 123.456, 12346},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money := NewMoney(tt.amount)
			if money.Cents() != tt.expected {
				t.Errorf("NewMoney(%f) = %d, want %d", tt.amount, money.Cents(), tt.expected)
			}
		})
	}
}

func TestMoneyString(t *testing.T) {
	tests := []struct {
		name     string
		cents    int64
		expected string
	}{
		{"positive", 12345, "123.45"},
		{"negative", -12345, "-123.45"},
		{"zero", 0, "0.00"},
		{"single cent", 1, "0.01"},
		{"dollars only", 10000, "100.00"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			money := NewMoneyFromCents(tt.cents)
			if money.String() != tt.expected {
				t.Errorf("Money(%d).String() = %s, want %s", tt.cents, money.String(), tt.expected)
			}
		})
	}
}

func TestMoneyOperations(t *testing.T) {
	m1 := NewMoney(100.50)
	m2 := NewMoney(50.25)

	// Addition
	result := m1.Add(m2)
	expected := NewMoney(150.75)
	if !result.Equal(expected) {
		t.Errorf("Add failed: %s + %s = %s, want %s", m1.String(), m2.String(), result.String(), expected.String())
	}

	// Subtraction
	result = m1.Subtract(m2)
	expected = NewMoney(50.25)
	if !result.Equal(expected) {
		t.Errorf("Subtract failed: %s - %s = %s, want %s", m1.String(), m2.String(), result.String(), expected.String())
	}

	// Multiplication
	result = m1.Multiply(2.0)
	expected = NewMoney(201.0)
	if !result.Equal(expected) {
		t.Errorf("Multiply failed: %s * 2.0 = %s, want %s", m1.String(), result.String(), expected.String())
	}

	// Division
	result = m1.Divide(2.0)
	expected = NewMoney(50.25)
	if !result.Equal(expected) {
		t.Errorf("Divide failed: %s / 2.0 = %s, want %s", m1.String(), result.String(), expected.String())
	}
}

func TestMoneyJSON(t *testing.T) {
	money := NewMoney(123.45)

	// Marshal to JSON
	data, err := json.Marshal(money)
	if err != nil {
		t.Fatalf("Failed to marshal Money to JSON: %v", err)
	}

	expected := `"123.45"`
	if string(data) != expected {
		t.Errorf("JSON marshal = %s, want %s", string(data), expected)
	}

	// Unmarshal from JSON
	var unmarshaled Money
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal Money from JSON: %v", err)
	}

	if !money.Equal(unmarshaled) {
		t.Errorf("JSON unmarshal = %s, want %s", unmarshaled.String(), money.String())
	}
}

func TestMoneyComparisons(t *testing.T) {
	m1 := NewMoney(100.00)
	m2 := NewMoney(50.00)
	m3 := NewMoney(100.00)

	if !m1.Equal(m3) {
		t.Error("Equal comparison failed")
	}

	if !m1.GreaterThan(m2) {
		t.Error("GreaterThan comparison failed")
	}

	if !m2.LessThan(m1) {
		t.Error("LessThan comparison failed")
	}

	if !m1.IsPositive() {
		t.Error("IsPositive check failed")
	}

	negative := NewMoney(-50.00)
	if !negative.IsNegative() {
		t.Error("IsNegative check failed")
	}

	zero := NewMoney(0.00)
	if !zero.IsZero() {
		t.Error("IsZero check failed")
	}
}