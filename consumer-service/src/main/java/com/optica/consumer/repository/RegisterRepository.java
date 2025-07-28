package com.optica.consumer.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.shared.entities.RegisterEntity;

public interface RegisterRepository extends JpaRepository<RegisterEntity, Long> {
}
