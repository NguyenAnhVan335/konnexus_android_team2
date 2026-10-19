package com.meta.junior.service.impl;

import com.meta.junior.common.util.HashtagParser;
import com.meta.junior.dto.social_media.hashtag.HashtagResponseDTO;
import com.meta.junior.entity.Hashtag;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostHashtag;
import com.meta.junior.repository.HashtagRepo;
import com.meta.junior.repository.PostHashtagRepo;
import com.meta.junior.service.HashtagService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@ApplicationScoped
public class HashtagServiceImpl implements HashtagService {

    @Inject
    HashtagRepo hashtagRepo;

    @Inject
    PostHashtagRepo postHashtagRepo;

    @Override
    public Set<String> extractHashtags(String content) {
        return HashtagParser.extractTags(content);
    }

    @Override
    @Transactional
    public void syncPostHashtags(Post post, String content) {
        if (post == null || post.getId() == null) {
            return;
        }

        Set<String> targetTags = extractHashtags(content);
        List<Hashtag> currentHashtags = postHashtagRepo.findHashtagsByPostId(post.getId());

        Map<String, Hashtag> currentTagMap = currentHashtags.stream()
                .collect(Collectors.toMap(Hashtag::getName, h -> h, (h1, h2) -> h1));

        Set<String> currentTagNames = currentTagMap.keySet();

        // 1. Xử lý các Hashtag bị gỡ bỏ
        Set<String> removedTags = new HashSet<>(currentTagNames);
        removedTags.removeAll(targetTags);

        for (String tagName : removedTags) {
            Hashtag h = currentTagMap.get(tagName);
            if (h != null) {
                h.setUsage_count(Math.max(0, h.getUsage_count() - 1));
                hashtagRepo.persist(h);
                // Xóa bản ghi trong post_hashtags
                postHashtagRepo.delete("post.id = ?1 and hashtag.id = ?2", post.getId(), h.getId());
            }
        }

        // 2. Xử lý các Hashtag mới được thêm vào
        Set<String> addedTags = new HashSet<>(targetTags);
        addedTags.removeAll(currentTagNames);

        for (String tagName : addedTags) {
            Hashtag hashtag = hashtagRepo.findByName(tagName).orElseGet(() -> {
                Hashtag newTag = Hashtag.builder()
                        .name(tagName)
                        .usage_count(0)
                        .build();
                hashtagRepo.persist(newTag);
                return newTag;
            });

            hashtag.setUsage_count(hashtag.getUsage_count() + 1);
            hashtagRepo.persist(hashtag);

            if (!postHashtagRepo.exists(post.getId(), hashtag.getId())) {
                PostHashtag postHashtag = PostHashtag.builder()
                        .post(post)
                        .hashtag(hashtag)
                        .build();
                postHashtagRepo.persist(postHashtag);
            }
        }
    }

    @Override
    @Transactional
    public void removePostHashtags(UUID postId) {
        if (postId == null) {
            return;
        }

        List<Hashtag> currentHashtags = postHashtagRepo.findHashtagsByPostId(postId);
        for (Hashtag h : currentHashtags) {
            h.setUsage_count(Math.max(0, h.getUsage_count() - 1));
            hashtagRepo.persist(h);
        }

        postHashtagRepo.deleteByPostId(postId);
    }

    @Override
    public Map<UUID, List<String>> getHashtagNamesByPostIds(List<UUID> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Collections.emptyMap();
        }

        List<PostHashtag> postHashtags = postHashtagRepo.findByPostIdsWithHashtag(postIds);

        return postHashtags.stream()
                .collect(Collectors.groupingBy(
                        ph -> ph.getPost().getId(),
                        Collectors.mapping(ph -> ph.getHashtag().getName(), Collectors.toList())
                ));
    }

    @Override
    public List<String> getHashtagNamesByPostId(UUID postId) {
        if (postId == null) {
            return List.of();
        }
        return postHashtagRepo.findHashtagsByPostId(postId).stream()
                .map(Hashtag::getName)
                .toList();
    }

    @Override
    public List<HashtagResponseDTO> getTrendingHashtags(int limit) {
        return hashtagRepo.findTopTrending(limit).stream()
                .map(HashtagResponseDTO::fromEntity)
                .toList();
    }

    @Override
    public List<HashtagResponseDTO> searchHashtags(String query, int limit) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        String cleanQuery = query.trim();
        if (cleanQuery.startsWith("#")) {
            cleanQuery = cleanQuery.substring(1);
        }
        return hashtagRepo.searchByNamePrefix(cleanQuery, limit).stream()
                .map(HashtagResponseDTO::fromEntity)
                .toList();
    }
}
