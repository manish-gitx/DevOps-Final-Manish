package com.example.devops.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.devops.model.User;

@RestController
@RequestMapping("/users")
public class UserController {

    @GetMapping
    public ResponseEntity<List<User>> listUsers() {
        List<User> users = List.of(
            new User(1L, "Alice", "alice@example.com"),
            new User(2L, "Bob", "bob@example.com"),
            new User(3L, "Charlie", "charlie@example.com")
        );
        return ResponseEntity.ok(users);
    }
}
