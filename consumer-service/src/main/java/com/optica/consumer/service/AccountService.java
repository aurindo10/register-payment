package com.optica.consumer.service;

import com.optica.shared.dto.AccountRequest;
import com.optica.shared.entities.AccountEntity;

public interface AccountService {
  AccountEntity createAccount(AccountRequest account);
  AccountEntity getAccountById(Long id);
  void deleteAccount(Long id);
}
