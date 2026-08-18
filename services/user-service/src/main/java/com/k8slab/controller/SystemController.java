package com.k8slab.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SystemController {

    @Value("${spring.application.name}")
    private String applicationName;

    private volatile boolean ready = true;

    @GetMapping("/ready")
    public ResponseEntity<String>  ready() {
        if (ready) {
            return ResponseEntity.ok("READY");
        }

        return ResponseEntity
                .status(HttpStatus.SERVICE_UNAVAILABLE)
                .body("NOT READY");
    }

    @PostMapping("/ready")
    public void setReady(@RequestParam boolean value) {
        ready = value;
    }
    @GetMapping("/version")
    public String version() {
        return applicationName + " v1.0.0";
    }
}