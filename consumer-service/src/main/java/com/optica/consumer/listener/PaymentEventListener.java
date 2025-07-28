package com.optica.consumer.listener;

import com.optica.shared.events.AccountCreatedEvent;
import com.optica.shared.events.CompanyCreatedEvent;
import com.optica.shared.events.RegisterCreatedEvent;
import com.optica.shared.dto.AccountRequest;
import com.optica.shared.dto.CompanyRequest;
import com.optica.shared.dto.RegisterRequest;
import com.optica.shared.entities.RegisterTypeEntity;
import com.optica.consumer.service.AccountService;
import com.optica.consumer.service.CompanyService;
import com.optica.consumer.service.RegisterService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
@AllArgsConstructor
@Slf4j
public class PaymentEventListener {

    private final CompanyService companyService;
    private final AccountService accountService;
    private final RegisterService registerService;

    @RabbitListener(queues = "company.queue")
    public void handleCompanyCreated(CompanyCreatedEvent event) {
        log.info("Received company created event: {}", event);
        try {
            CompanyRequest request = new CompanyRequest(
                    event.getName(),
                    event.getCnpj(),
                    event.getExternalCompanyId()
            );
            companyService.createCompany(CompanyRequest.toEntity(request));
            log.info("Company created successfully: {}", event.getName());
        } catch (Exception e) {
            log.error("Error processing company created event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "account.queue")
    public void handleAccountCreated(AccountCreatedEvent event) {
        log.info("Received account created event: {}", event);
        try {
            AccountRequest request = new AccountRequest(
                    event.getBalance(),
                    event.getExternalAccountId(),
                    event.getCompanyId()
            );
            accountService.createAccount(request);
            log.info("Account created successfully: {}", event.getExternalAccountId());
        } catch (Exception e) {
            log.error("Error processing account created event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "register.queue")
    public void handleRegisterCreated(RegisterCreatedEvent event) {
        log.info("Received register created event: {}", event);
        try {
            RegisterRequest request = new RegisterRequest(
                    RegisterTypeEntity.valueOf(event.getType()),
                    event.getAmount(),
                    event.getAccountId(),
                    event.getUserId()
            );
            registerService.createRegister(request);
            log.info("Register created successfully: {}", event.getType());
        } catch (Exception e) {
            log.error("Error processing register created event: {}", e.getMessage(), e);
        }
    }
} 