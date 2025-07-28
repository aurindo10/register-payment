package com.optica.app.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.optica.app.dto.AccountRequest;
import com.optica.app.entities.AccountEntity;
import com.optica.app.service.AccountService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/account")
@AllArgsConstructor
public class AccountController {
  private final AccountService accountService;

  @PostMapping
  public AccountEntity createAccount(@RequestBody AccountRequest accountRequest) {
    return accountService.createAccount(accountRequest);
  }
}
