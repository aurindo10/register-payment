package com.optica.app.entities;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;


@Entity
@Table(name = "account")
@Builder
@Data
@NoArgsConstructor
@AllArgsConstructor
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

  @OneToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "company_id")
  private CompanyEntity company;

  @Column(name = "date_updated")
  private LocalDateTime dateUpdated;

}