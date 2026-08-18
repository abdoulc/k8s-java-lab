package com.k8slab.service;

import com.k8slab.model.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Optional;


@Service
public class OrderService {

    private final List<Order> orders;
    private final RestClient restClient;

    public OrderService(
            @Value("${user-service.url}") String userServiceUrl
    ) {
        this.orders = List.of(
                new Order(1001L, 1L, "Kubernetes Book", 1),
                new Order(1002L, 2L, "Java Book", 2),
                new Order(1003L, 1L, "Docker Book", 1)
        );

        this.restClient = RestClient.builder()
                .baseUrl(userServiceUrl)
                .build();
    }

    public List<Order> findAll() {
        return orders;
    }

    public Optional<Order> findById(Long id) {
        return orders.stream()
                .filter(order -> order.id().equals(id))
                .findFirst();
    }

    public Object findUser(Long userId) {
        return restClient
                .get()
                .uri("/users/{id}", userId)
                .retrieve()
                .body(Object.class);
    }
}