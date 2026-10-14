package com.meta.junior.friendship.exception;

import com.meta.junior.friendship.dto.ApiResponse;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class ApiExceptionMapper implements ExceptionMapper<ApiException> {

    @Override
    public Response toResponse(ApiException exception) {
        return Response.status(exception.getStatusCode())
                .type(MediaType.APPLICATION_JSON)
                .entity(ApiResponse.error(exception.getMessage()))
                .build();
    }
}
