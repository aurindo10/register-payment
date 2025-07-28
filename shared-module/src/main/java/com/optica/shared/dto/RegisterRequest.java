package com.optica.shared.dto;

import com.optica.shared.entities.RegisterEntity;
import com.optica.shared.entities.RegisterTypeEntity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {
  private String type;
  private Double amount;
  private Long accountId;
  private String userId;
  public static RegisterEntity toEntity(RegisterRequest registerRequest) {
    return RegisterEntity.builder()
        .type(RegisterTypeEntity.valueOf(registerRequest.getType()))
        .amount(registerRequest.getAmount())
        .userId(registerRequest.getUserId())
        .build();
  }
}
