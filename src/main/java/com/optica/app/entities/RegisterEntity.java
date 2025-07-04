package com.optica.app.entities;

import java.time.LocalDateTime;

import jakarta.persistence.*;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;


@Entity
@Table(name = "register")
public class RegisterEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Enumerated(EnumType.STRING)
  private RegisterTypeEntity type;

  @Column(name = "created_at")
  private LocalDateTime createdAt;

  @Column(name = "amount")
  private Double amount;

  @Column(name = "account_id")
  private String accountId;
  
  @Column(name = "user_id")
  private String userId;
}
