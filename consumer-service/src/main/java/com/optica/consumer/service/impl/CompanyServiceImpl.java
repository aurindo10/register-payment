package com.optica.consumer.service.impl;

import java.util.List;

import com.optica.shared.entities.CompanyEntity;
import com.optica.consumer.repository.CompanyRepository;
import com.optica.consumer.service.CompanyService;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;

@Service
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

  @Override
  public CompanyEntity find(Long id) {
    return companyRepository.findById(id).orElseThrow(() -> new RuntimeException("Company not found"));
  }
}