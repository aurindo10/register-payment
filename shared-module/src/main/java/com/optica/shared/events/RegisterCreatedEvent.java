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
public class RegisterCreatedEvent {
    @JsonProperty("type")
    private String type;
    
    @JsonProperty("amount")
    private BigDecimal amount;
    
    @JsonProperty("account_id")
    private Long accountId;
    
    @JsonProperty("user_id")
    private String userId;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
} 