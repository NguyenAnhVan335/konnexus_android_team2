package com.meta.junior.common;

import com.meta.junior.entity.Post;

/**
 * Lifecycle status of a {@link Post} as exposed by the API.
 *
 * <p>Internally the flag is stored as the boolean {@code post.status} column
 * ({@code true} = active, {@code false} = soft deleted). The API uses this enum instead of a boolean
 * so a client can explicitly express "delete this post" with
 * {@code PUT /api/v1/posts/{id}} + {@code {"status": "DELETED"}}.</p>
 */
public enum PostStatus {
    ACTIVE,
    DELETED
}
