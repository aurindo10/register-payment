package com.optica.app.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.optica.app.dto.RegisterRequest;
import com.optica.app.entities.RegisterEntity;
import com.optica.app.service.RegisterService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/registers")
@AllArgsConstructor
public class RegisterController {
  private final RegisterService registerService;

  @PostMapping
  public RegisterEntity createRegister(@RequestBody RegisterRequest registerRequest) {
    return registerService.createRegister(registerRequest);
  }
}
