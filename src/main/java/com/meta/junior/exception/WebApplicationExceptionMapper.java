package com.meta.junior.exception;

import com.meta.junior.dto.ErrorResponse;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

/**
 * Maps {@link WebApplicationException} (404, 403, 401, 400, ...) to a consistent JSON error body.
 */
@Provider
public class WebApplicationExceptionMapper implements ExceptionMapper<WebApplicationException> {

    @Override
    public Response toResponse(WebApplicationException exception) {
        Response original = exception.getResponse();
        int status = original.getStatus();
        String message = exception.getMessage() != null ? exception.getMessage() : "HTTP " + status;
        return Response.status(status)
                .entity(ErrorResponse.of(status, toCode(status), message))
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    private static String toCode(int status) {
        return switch (status) {
            case 400 -> "BAD_REQUEST";
            case 401 -> "UNAUTHORIZED";
            case 403 -> "FORBIDDEN";
            case 404 -> "NOT_FOUND";
            case 405 -> "METHOD_NOT_ALLOWED";
            case 409 -> "CONFLICT";
            case 422 -> "UNPROCESSABLE_ENTITY";
            case 500 -> "INTERNAL_SERVER_ERROR";
            default -> "HTTP_" + status;
        };
    }
}
