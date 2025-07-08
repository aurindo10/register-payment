package com.optica.app.service.impl;

import com.optica.app.dto.AccountRequest;
import com.optica.app.entities.AccountEntity;
import com.optica.app.entities.CompanyEntity;
import com.optica.app.repository.AccountRepository;
import com.optica.app.service.AccountService;
import com.optica.app.service.CompanyService;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@AllArgsConstructor
public class AccountServiceImpl implements AccountService {
  private final AccountRepository accountRepository;
  private final CompanyService companyService;

  @Override
  public AccountEntity createAccount(AccountRequest account) {
    CompanyEntity company = companyService.find(account.getCompanyId());
    if (company == null) {
      throw new RuntimeException("Company not found");
    }
    return accountRepository.save(account.toEntity(account, company));
  }

  @Override
  public AccountEntity getAccountById(Long id) {
    return accountRepository.findById(id).orElseThrow(() -> new RuntimeException("Account not found"));
  }

  @Override
  public void deleteAccount(Long id) {
    accountRepository.deleteById(id);
  }

}
