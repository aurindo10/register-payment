package com.optica.app.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.optica.app.dto.CompanyRequest;
import com.optica.app.entities.CompanyEntity;
import com.optica.app.service.CompanyService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/companies")
@AllArgsConstructor
public class CompanyController {
  private final CompanyService companyService;

  @PostMapping
  public CompanyEntity createCompany(@RequestBody CompanyRequest companyRequest) {
    return companyService.createCompany(CompanyRequest.toEntity(companyRequest));
  }

  @GetMapping
  public List<CompanyEntity> getAllCompanies() {
    return companyService.getAllCompanies();
  }

}
