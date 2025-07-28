package com.optica.gateway.controller;

import com.optica.gateway.service.PublisherService;
import com.optica.shared.dto.AccountRequest;
import com.optica.shared.dto.CompanyRequest;
import com.optica.shared.dto.RegisterRequest;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/gateway")
@AllArgsConstructor
@Slf4j
public class PaymentGatewayController {

    private final PublisherService publisherService;

    @PostMapping("/companies")
    public ResponseEntity<String> createCompany(@RequestBody CompanyRequest request) {
        log.info("Received company creation request: {}", request);
        publisherService.publishCompanyCreated(request);
        return ResponseEntity.accepted().body("Company creation request submitted");
    }

    @PostMapping("/accounts")
    public ResponseEntity<String> createAccount(@RequestBody AccountRequest request) {
        log.info("Received account creation request: {}", request);
        publisherService.publishAccountCreated(request);
        return ResponseEntity.accepted().body("Account creation request submitted");
    }

    @PostMapping("/registers")
    public ResponseEntity<String> createRegister(@RequestBody RegisterRequest request) {
        log.info("Received register creation request: {}", request);
        publisherService.publishRegisterCreated(request);
        return ResponseEntity.accepted().body("Register creation request submitted");
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Gateway service is healthy");
    }
} 