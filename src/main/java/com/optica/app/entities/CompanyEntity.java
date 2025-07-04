package com.optica.app.entities;

import jakarta.persistence.*;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Builder;

@Entity
@Builder
@Table(name = "company")
public class CompanyEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "name")
  private String name;

  @Column(name = "cnpj")
  private String cnpj;

  @Column(name = "external_company_id")
  private String externalCompanyId;
}
