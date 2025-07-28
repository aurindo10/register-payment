package com.optica.app.service.impl;

import org.springframework.stereotype.Service;

import com.optica.app.dto.RegisterRequest;
import com.optica.app.entities.AccountEntity;
import com.optica.app.entities.RegisterEntity;
import com.optica.app.repository.RegisterRepository;
import com.optica.app.service.AccountService;
import com.optica.app.service.RegisterService;

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
