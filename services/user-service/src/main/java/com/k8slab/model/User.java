package com.k8slab.model;

public record User(
        Long id,
        String name,
        String email
) {
}
