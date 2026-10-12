package com.meta.junior.dto;

import java.util.List;

/**
 * Consistent error body returned by the exception mappers.
 */
public record ErrorResponse(
        int status,
        String code,
        String message,
        List<String> details
) {
    public static ErrorResponse of(int status, String code, String message) {
        return new ErrorResponse(status, code, message, List.of());
    }

    public static ErrorResponse of(int status, String code, String message, List<String> details) {
        return new ErrorResponse(status, code, message, details);
    }
}
