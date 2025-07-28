package com.optica.consumer.service.impl;

import org.springframework.stereotype.Service;

import com.optica.shared.dto.RegisterRequest;
import com.optica.shared.entities.AccountEntity;
import com.optica.shared.entities.RegisterEntity;
import com.optica.consumer.repository.RegisterRepository;
import com.optica.consumer.service.AccountService;
import com.optica.consumer.service.RegisterService;

import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class RegisterServiceImpl implements RegisterService {
  private final RegisterRepository registerRepository;
  private final AccountService accountService;

  @Override
  public RegisterEntity createRegister(RegisterRequest registerRequest) {
    AccountEntity account = accountService.getAccountById(registerRequest.getAccountId());
    if (account == null) {
      throw new RuntimeException("Account not found");
    }
    RegisterEntity register = RegisterRequest.toEntity(registerRequest);;

    register.setAccount(account);

    return registerRepository.save(register);
  }
}
