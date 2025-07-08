package com.optica.app.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.optica.app.entities.AccountEntity;

public interface AccountRepository extends JpaRepository<AccountEntity, Long> {

}
