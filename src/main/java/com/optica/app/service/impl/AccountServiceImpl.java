package com.optica.app.service.impl;

import com.optica.app.dto.AccountRequest;
import com.optica.app.entities.AccountEntity;
import com.optica.app.repository.AccountRepository;
import com.optica.app.service.AccountService;

import lombok.AllArgsConstructor;

@AllArgsConstructor
public class AccountServiceImpl implements AccountService {
  private final AccountRepository accountRepository;

  @Override
  public AccountEntity createAccount(AccountRequest account) {
    return accountRepository.save(account.toEntity(account));
  }

  @Override
  public AccountEntity getAccountById(Long id) {
    return accountRepository.findById(id).orElseThrow(() -> new RuntimeException("Account not found"));
  }

  @Override
  public AccountEntity updateAccount(AccountRequest account) {
    return accountRepository.save(account.toEntity(account));
  }

  @Override
  public void deleteAccount(Long id) {
    accountRepository.deleteById(id);
  }

}
