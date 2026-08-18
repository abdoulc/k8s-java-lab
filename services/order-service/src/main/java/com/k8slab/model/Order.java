package com.k8slab.model;

public record Order(
        Long id,
        Long userId,
        String product,
        int quantity
) {
}
