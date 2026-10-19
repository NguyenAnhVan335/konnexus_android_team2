package com.meta.junior.service.impl;

import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.PostMediaDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;
import com.meta.junior.entity.Post;
import com.meta.junior.repository.PostMediaRepo;
import com.meta.junior.repository.PostRepo;
import com.meta.junior.service.HashtagService;
import com.meta.junior.service.PostSearchService;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.*;
import java.util.stream.Collectors;

@ApplicationScoped
public class PostSearchServiceImpl implements PostSearchService {

    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 30;

    @Inject
    PostRepo postRepo;

    @Inject
    HashtagService hashtagService;

    @Inject
    PostMediaRepo postMediaRepo;

    @Override
    public PageResponseDTO<PostResponseDTO> searchByKeyword(UUID currentUserId, String keyword, int page, int size) {
        int pageIndex = Math.max(0, page);
        int pageSize = (size <= 0) ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);

        if (keyword == null || keyword.isBlank()) {
            return PageResponseDTO.of(Collections.emptyList(), pageIndex, pageSize, 0, 0);
        }

        String normalizedKeyword = keyword.trim();
        if (normalizedKeyword.isBlank()) {
            return PageResponseDTO.of(Collections.emptyList(), pageIndex, pageSize, 0, 0);
        }

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<Post> query = postRepo.searchByKeyword(currentUserId, normalizedKeyword, pageable);

        return toPaginatedResponse(query, pageIndex, pageSize);
    }

    @Override
    public PageResponseDTO<PostResponseDTO> searchByHashtag(UUID currentUserId, String tagName, int page, int size) {
        int pageIndex = Math.max(0, page);
        int pageSize = (size <= 0) ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);

        if (tagName == null || tagName.isBlank()) {
            return PageResponseDTO.of(Collections.emptyList(), pageIndex, pageSize, 0, 0);
        }

        String cleanTag = tagName.trim();
        if (cleanTag.startsWith("#")) {
            cleanTag = cleanTag.substring(1);
        }
        cleanTag = cleanTag.trim().toLowerCase(Locale.ROOT);

        if (cleanTag.isBlank()) {
            return PageResponseDTO.of(Collections.emptyList(), pageIndex, pageSize, 0, 0);
        }

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<Post> query = postRepo.searchByHashtag(currentUserId, cleanTag, pageable);

        return toPaginatedResponse(query, pageIndex, pageSize);
    }

    /**
     * Helper gom nhóm và nạp dữ liệu liên quan theo lô (Batch Loading):
     * Triệt tiêu hoàn toàn vấn đề N+1 Query:
     * 1. Lấy danh sách posts của trang hiện tại.
     * 2. Nếu rỗng, return ngay lập tức (không query batch).
     * 3. Batch fetch toàn bộ media của postIds trong 1 câu SQL.
     * 4. Batch fetch toàn bộ hashtags của postIds trong 1 câu SQL.
     * 5. Map sang DTO với độ phức tạp tra cứu O(1) trong bộ nhớ.
     */
    private PageResponseDTO<PostResponseDTO> toPaginatedResponse(PanacheQuery<Post> query, int pageIndex, int pageSize) {
        List<Post> posts = query.list();

        // Early return: Nếu không có kết quả, không chạy thêm bất kỳ query batch nào
        if (posts.isEmpty()) {
            return PageResponseDTO.of(
                    Collections.emptyList(),
                    pageIndex,
                    pageSize,
                    query.count(),
                    query.pageCount()
            );
        }

        List<UUID> postIds = posts.stream()
                .map(Post::getId)
                .toList();

        // 1. Batch fetch Hashtags của toàn bộ postIds (1 query)
        Map<UUID, List<String>> hashtagsByPost = hashtagService.getHashtagNamesByPostIds(postIds);

        // 2. Batch fetch Media của toàn bộ postIds (1 query)
        Map<UUID, List<PostMediaDTO>> mediaByPost = postMediaRepo.findByPostIds(postIds).stream()
                .collect(Collectors.groupingBy(
                        m -> m.getPost().getId(),
                        Collectors.mapping(PostMediaDTO::fromEntity, Collectors.toList())
                ));

        // 3. Mapping DTO không gây ra Lazy Loading
        List<PostResponseDTO> items = posts.stream()
                .map(post -> PostResponseDTO.fromEntity(
                        post,
                        hashtagsByPost.getOrDefault(post.getId(), Collections.emptyList()),
                        mediaByPost.getOrDefault(post.getId(), Collections.emptyList())
                ))
                .toList();

        return PageResponseDTO.of(
                items,
                pageIndex,
                pageSize,
                query.count(),
                query.pageCount()
        );
    }
}
