package com.k8slab.service;

import com.k8slab.model.User;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class UserService {

    private final List<User> users = List.of(
            new User(1L, "Alice", "alice@example.com"),
            new User(2L, "Bob", "bob@example.com"),
            new User(3L, "Charlie", "charlie@example.com")
    );

    public List<User> findAll() {
        return users;
    }

    public Optional<User> findById(Long id) {
        return users.stream()
                .filter(user -> user.id().equals(id))
                .findFirst();
    }
}