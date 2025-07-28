-- Create Company table
CREATE TABLE company (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(255) UNIQUE NOT NULL,
    external_company_id VARCHAR(255) UNIQUE
);

-- Create Account table
CREATE TABLE account (
    id BIGSERIAL PRIMARY KEY,
    balance NUMERIC(19, 2) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    external_account_id VARCHAR(255) UNIQUE,
    company_id BIGINT NOT NULL,
    date_updated TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company
        FOREIGN KEY(company_id)
            REFERENCES company(id)
);

-- Create Register table
CREATE TABLE register (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL, -- Storing enum as string
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(19, 2) NOT NULL,
    account_id BIGINT NOT NULL, -- Changed from String to BIGINT to match AccountEntity ID
    user_id VARCHAR(255), -- Assuming user_id is a string or UUID for now,
                          -- as no UserEntity was provided.
                          -- If a UserEntity exists, this should be a foreign key to it.
    CONSTRAINT fk_account
        FOREIGN KEY(account_id)
            REFERENCES account(id)
);

-- Add indexes for foreign keys to improve performance
CREATE INDEX idx_account_company_id ON account (company_id);
CREATE INDEX idx_register_account_id ON register (account_id);
