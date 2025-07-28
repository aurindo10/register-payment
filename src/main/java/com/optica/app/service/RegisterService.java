package com.optica.app.service;

import com.optica.app.dto.RegisterRequest;
import com.optica.app.entities.RegisterEntity;

public interface RegisterService {
  RegisterEntity createRegister(RegisterRequest registerRequest);
}
