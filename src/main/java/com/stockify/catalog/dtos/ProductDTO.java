package com.stockify.catalog.dtos;

import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

@Getter
@Setter
public class ProductDTO {
    private String name;
    private String description;
    private Double price;
    private MultipartFile image;
}