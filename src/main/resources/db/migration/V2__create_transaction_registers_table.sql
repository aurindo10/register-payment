-- Create Transaction table
CREATE TABLE transaction (
    id BIGSERIAL PRIMARY KEY,
    external_transaction_id VARCHAR(255),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create junction table for Many-to-Many relationship
CREATE TABLE transaction_registers (
    transaction_id BIGINT NOT NULL,
    registers_id BIGINT NOT NULL,
    PRIMARY KEY (transaction_id, registers_id),
    CONSTRAINT fk_transaction_registers_transaction
        FOREIGN KEY (transaction_id)
            REFERENCES transaction(id)
            ON DELETE CASCADE,
    CONSTRAINT fk_transaction_registers_register
        FOREIGN KEY (registers_id)
            REFERENCES register(id)
            ON DELETE CASCADE
);

-- Add indexes
CREATE INDEX idx_transaction_registers_transaction_id ON transaction_registers (transaction_id);
CREATE INDEX idx_transaction_registers_register_id ON transaction_registers (registers_id);