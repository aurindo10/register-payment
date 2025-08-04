package money

import (
	"reflect"

	"github.com/go-playground/validator/v10"
)

// RegisterValidators registers custom validators for Money type
func RegisterValidators(v *validator.Validate) {
	v.RegisterCustomTypeFunc(ValidateMoney, Money{})
}

// ValidateMoney validates Money values for the validator package
func ValidateMoney(field reflect.Value) interface{} {
	if money, ok := field.Interface().(Money); ok {
		return money.String()
	}
	return nil
}