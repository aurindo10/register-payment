package com.optica.app.service;

import com.optica.app.dto.AccountRequest;
import com.optica.app.entities.AccountEntity;

public interface AccountService {
  AccountEntity createAccount(AccountRequest account);
  AccountEntity getAccountById(Long id);
  void deleteAccount(Long id);
}
