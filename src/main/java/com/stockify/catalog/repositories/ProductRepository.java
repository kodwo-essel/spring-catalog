package com.stockify.catalog.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.stockify.catalog.entities.Product;

public interface ProductRepository extends JpaRepository<Product, Long> {
}

