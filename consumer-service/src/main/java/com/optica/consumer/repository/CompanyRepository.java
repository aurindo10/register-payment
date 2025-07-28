package com.optica.consumer.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.shared.entities.CompanyEntity;

public interface CompanyRepository extends JpaRepository<CompanyEntity, Long> {
}
