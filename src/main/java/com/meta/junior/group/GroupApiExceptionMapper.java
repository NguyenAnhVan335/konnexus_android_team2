package com.meta.junior.group;

import com.meta.junior.common.ApiResponse;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

/** Only converts Groups exceptions. Existing modules keep their own error handling. */
@Provider
public class GroupApiExceptionMapper implements ExceptionMapper<GroupApiException> {
    @Override
    public Response toResponse(GroupApiException ex) {
        return Response.status(ex.getStatusCode())
                .type(MediaType.APPLICATION_JSON)
                .entity(ApiResponse.error(ex.getMessage()))
                .build();
    }
}
