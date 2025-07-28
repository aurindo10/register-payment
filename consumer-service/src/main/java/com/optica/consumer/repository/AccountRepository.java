package com.optica.consumer.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.shared.entities.AccountEntity;

public interface AccountRepository extends JpaRepository<AccountEntity, Long> {

}
