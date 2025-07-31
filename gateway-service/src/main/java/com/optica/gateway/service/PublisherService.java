package com.optica.gateway.service;

import com.optica.gateway.config.RabbitConfig;
import com.optica.shared.dto.AccountRequest;
import com.optica.shared.dto.CompanyRequest;
import com.optica.shared.dto.RegisterRequest;
import com.optica.shared.events.AccountCreatedEvent;
import com.optica.shared.events.CompanyCreatedEvent;
import com.optica.shared.events.RegisterCreatedEvent;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Service
@AllArgsConstructor
@Slf4j
public class PublisherService {

    private final RabbitTemplate rabbitTemplate;

    public void publishCompanyCreated(CompanyRequest request) {
        CompanyCreatedEvent event = new CompanyCreatedEvent(
                request.getName(),
                request.getCnpj(),
                request.getExternalCompanyId(),
                LocalDateTime.now()
        );
        
        log.info("Publishing company created event: {}", event);
        rabbitTemplate.convertAndSend(RabbitConfig.PAYMENT_EXCHANGE, "company.created", event);
    }

    public void publishAccountCreated(AccountRequest request) {
        AccountCreatedEvent event = new AccountCreatedEvent(
                BigDecimal.valueOf(request.getBalance().doubleValue()),
                request.getExternalAccountId(),
                request.getCompanyId(),
                LocalDateTime.now()
        );
        
        log.info("Publishing account created event: {}", event);
        rabbitTemplate.convertAndSend(RabbitConfig.PAYMENT_EXCHANGE, "account.created", event);
    }

    public void publishRegisterCreated(RegisterRequest request) {
        RegisterCreatedEvent event = new RegisterCreatedEvent(
                request.getType(),
                BigDecimal.valueOf(request.getAmount()),
                request.getAccountId(),
                request.getUserId(),
                LocalDateTime.now()
        );
        
        log.info("Publishing register created event: {}", event);
        rabbitTemplate.convertAndSend(RabbitConfig.PAYMENT_EXCHANGE, "register.created", event);
    }
} 