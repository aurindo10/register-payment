package com.optica.shared.events;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CompanyCreatedEvent {
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("cnpj")
    private String cnpj;
    
    @JsonProperty("external_company_id")
    private String externalCompanyId;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
} 