package com.k8slab.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SystemController {

    @Value("${spring.application.name}")
    private String applicationName;

    @GetMapping("/version")
    public String version() {
        return applicationName + " v1.0.0";
    }
}