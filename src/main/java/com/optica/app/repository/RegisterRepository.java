package com.optica.app.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.app.entities.RegisterEntity;

public interface RegisterRepository extends JpaRepository<RegisterEntity, Long> {
}
