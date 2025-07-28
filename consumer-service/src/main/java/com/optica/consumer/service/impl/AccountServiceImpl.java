package com.optica.consumer.service.impl;

import com.optica.shared.dto.AccountRequest;
import com.optica.shared.entities.AccountEntity;
import com.optica.shared.entities.CompanyEntity;
import com.optica.consumer.repository.AccountRepository;
import com.optica.consumer.service.AccountService;
import com.optica.consumer.service.CompanyService;

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
