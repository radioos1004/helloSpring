package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ActuatorController {
    @GetMapping("/health")
    public String health() {

        return "Hello, Spring Boot 성공이야 ㅋㅋㅋㅋ 너무 좋다 ^^^^! green";
    }
}
