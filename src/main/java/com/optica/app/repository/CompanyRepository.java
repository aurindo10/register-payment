package com.optica.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.app.entities.CompanyEntity;

public interface CompanyRepository extends JpaRepository<CompanyEntity, Long> {
}
