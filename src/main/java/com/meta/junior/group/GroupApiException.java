package com.meta.junior.group;

/** Group-only API exception, independent of other modules' exception classes. */
public class GroupApiException extends RuntimeException {
    private final int statusCode;

    public GroupApiException(int statusCode, String message) {
        super(message);
        this.statusCode = statusCode;
    }

    public int getStatusCode() {
        return statusCode;
    }
}
