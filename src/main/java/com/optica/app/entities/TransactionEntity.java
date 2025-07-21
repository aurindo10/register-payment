package com.optica.app.entities;

import java.time.LocalDateTime;
import java.util.List;

import jakarta.persistence.FetchType;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.Id;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Column;

@Entity
@Table(name = "transaction")
public class TransactionEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "external_transaction_id")
  private String externalTransactionId;

  @ManyToMany(fetch = FetchType.LAZY)
  private List<RegisterEntity> registers;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @Column(name = "amount")
  private Double amount;

  @Column(name = "conciliation_id")
  private ConciliationEntity  conciliation;
}
