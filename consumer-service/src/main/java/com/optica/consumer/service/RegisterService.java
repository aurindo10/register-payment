package com.optica.consumer.service;

import com.optica.shared.dto.RegisterRequest;
import com.optica.shared.entities.RegisterEntity;

public interface RegisterService {
  RegisterEntity createRegister(RegisterRequest registerRequest);
}
