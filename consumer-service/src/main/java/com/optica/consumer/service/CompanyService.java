package com.optica.consumer.service;

import java.util.List;

import com.optica.shared.entities.CompanyEntity;

public interface CompanyService {
  CompanyEntity createCompany(CompanyEntity company);
  void deleteCompany(Long id);
  List<CompanyEntity> getAllCompanies();
  CompanyEntity find(Long id);
}
