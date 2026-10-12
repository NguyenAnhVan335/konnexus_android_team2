package com.meta.junior.dto;

/**
 * Standard success envelope used by every endpoint: {@code { "success": true, "message": ..., "data": ... }}.
 *
 * <p>Errors are returned through the exception mappers as {@link ErrorResponse} instead.</p>
 */
public record ApiResponse<T>(
        boolean success,
        String message,
        T data
) {
    public static <T> ApiResponse<T> ok(T data, String message) {
        return new ApiResponse<>(true, message, data);
    }

    public static <T> ApiResponse<T> ok(String message) {
        return new ApiResponse<>(true, message, null);
    }
}
