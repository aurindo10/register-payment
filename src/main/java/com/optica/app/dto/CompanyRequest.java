package com.optica.app.dto;

import com.optica.app.entities.CompanyEntity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompanyRequest {
  private String name;
  private String cnpj;
  private String externalCompanyId;

  public static CompanyEntity toEntity(CompanyRequest company) {
    return CompanyEntity.builder()
        .name(company.getName())
        .cnpj(company.getCnpj())
        .externalCompanyId(company.getExternalCompanyId())
        .build();
  }
}
