-- Create conciliation table
CREATE TABLE conciliation (
    id BIGSERIAL PRIMARY KEY,
    description VARCHAR(400),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE transaction ADD COLUMN conciliation_id BIGINT;
ALTER TABLE transaction ADD
    CONSTRAINT fk_conciliation
        FOREIGN KEY(conciliation_id)
            REFERENCES conciliation(id); 