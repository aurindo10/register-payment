package com.optica.app.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.optica.app.entities.AccountEntity;
import com.optica.app.entities.CompanyEntity;

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

  public AccountEntity toEntity(AccountRequest account, CompanyEntity company) {
    return AccountEntity.builder()
        .balance(BigDecimal.valueOf(account.getBalance().doubleValue()))
        .externalAccountId(account.getExternalAccountId())
        .company(company)
        .build();
  }
}
