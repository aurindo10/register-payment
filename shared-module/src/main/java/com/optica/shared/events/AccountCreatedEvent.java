package com.optica.shared.events;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AccountCreatedEvent {
    @JsonProperty("balance")
    private BigDecimal balance;
    
    @JsonProperty("external_account_id")
    private String externalAccountId;
    
    @JsonProperty("company_id")
    private Long companyId;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
} 