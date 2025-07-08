package com.optica.app.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.optica.app.entities.AccountEntity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AccountRequest {
  private Number balance;
  private String externalAccountId;
  private Long companyId;
  private LocalDateTime createdAt;
  private LocalDateTime dateUpdated;

  public AccountEntity toEntity(AccountRequest account) {
    return AccountEntity.builder()
        .balance(BigDecimal.valueOf(account.getBalance().doubleValue()))
        .externalAccountId(account.getExternalAccountId())
        .companyId(account.getCompanyId())
        .build();
  }
}
