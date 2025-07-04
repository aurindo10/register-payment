package com.optica.app.service;

import java.util.List;

import com.optica.app.entities.CompanyEntity;

public interface CompanyService {
  CompanyEntity createCompany(CompanyEntity company);
  CompanyEntity getCompanyByCnpj(String cnpj);
  CompanyEntity updateCompany(CompanyEntity company);
  void deleteCompany(Long id);
  List<CompanyEntity> getAllCompanies();
}
