package com.meta.junior.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.util.List;

/**
 * Pagination envelope used as {@code data} for list endpoints:
 * {@code { "content": [...], "page": ..., "size": ..., "total_elements": ..., "total_pages": ... }}.
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record PageData<T>(
        List<T> content,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static <T> PageData<T> of(List<T> content, int page, int size, long totalElements) {
        int totalPages = size > 0 ? (int) Math.ceil((double) totalElements / size) : 0;
        return new PageData<>(content, page, size, totalElements, totalPages);
    }
}
