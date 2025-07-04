package com.optica.app.entities;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;


@Entity
@Table(name = "account")
public class AccountEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "balance")
  private BigDecimal balance;

  @Column(name = "created_at")
  private LocalDateTime createdAt;
  
  @Column(name = "external_account_id")
  private String externalAccountId;

  @Column(name = "company_id")
  private Long companyEntity;

  @Column(name = "date_updated")
  private LocalDateTime dateUpdated;

}