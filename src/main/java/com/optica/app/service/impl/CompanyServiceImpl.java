package com.optica.app.service.impl;

import java.util.List;

import com.optica.app.entities.CompanyEntity;
import com.optica.app.repository.CompanyRepository;
import com.optica.app.service.CompanyService;

import lombok.AllArgsConstructor;

@AllArgsConstructor
public class CompanyServiceImpl implements CompanyService {

  private final CompanyRepository companyRepository;

  @Override
  public CompanyEntity createCompany(CompanyEntity company) {
    return companyRepository.save(company);
  }

  @Override
  public void deleteCompany(Long id) {
    companyRepository.deleteById(id);
  }

  @Override
  public List<CompanyEntity> getAllCompanies() {
    return companyRepository.findAll();
  }
}