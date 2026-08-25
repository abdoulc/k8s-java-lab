package com.k8slab.controller;

import com.k8slab.model.Order;
import com.k8slab.service.OrderService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private OrderService orderService;

    @Test
    void returnsOrders() throws Exception {
        when(orderService.findAll()).thenReturn(List.of(
                new Order(1001L, 1L, "Kubernetes Book", 1)
        ));

        mockMvc.perform(get("/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(1001))
                .andExpect(jsonPath("$[0].product").value("Kubernetes Book"));
    }

    @Test
    void returnsNotFoundForUnknownOrder() throws Exception {
        when(orderService.findById(9999L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/orders/9999"))
                .andExpect(status().isNotFound());
    }

    @Test
    void returnsTheUserAssociatedWithAnOrder() throws Exception {
        Order order = new Order(1001L, 1L, "Kubernetes Book", 1);
        when(orderService.findById(1001L)).thenReturn(Optional.of(order));
        when(orderService.findUser(1L)).thenReturn(Map.of(
                "id", 1,
                "name", "Alice"
        ));

        mockMvc.perform(get("/orders/1001/user"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Alice"));
    }
}
