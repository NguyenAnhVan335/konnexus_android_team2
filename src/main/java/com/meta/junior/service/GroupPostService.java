package com.meta.junior.service;

import com.meta.junior.dto.*;
import com.meta.junior.entity.*;
import com.meta.junior.exception.ApiException;
import com.meta.junior.repository.GroupPostRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class GroupPostService {
    @Inject GroupService groups;
    @Inject GroupPostRepository posts;

    private GroupPostDto map(GroupPostEntity post) {
        return new GroupPostDto(post.id, post.groupId, post.authorId, post.content,
                post.status, post.createdAt, post.updatedAt);
    }

    private GroupPostEntity activePost(UUID groupId, UUID postId) {
        return posts.findActive(groupId, postId)
                .orElseThrow(() -> new ApiException(404, "Không tìm thấy bài viết"));
    }

    private void requireCanRead(GroupEntity group, UUID actor) {
        if (group.privacy == GroupPrivacy.PRIVATE) groups.requireMember(group.id, actor);
    }

    public List<GroupPostDto> published(UUID groupId, UUID actor) {
        GroupEntity group = groups.active(groupId);
        requireCanRead(group, actor);
        return posts.published(groupId).stream().map(this::map).toList();
    }

    public List<GroupPostDto> pending(UUID groupId, UUID actor) {
        groups.active(groupId);
        groups.requireAdmin(groupId, actor);
        return posts.pending(groupId).stream().map(this::map).toList();
    }

    public List<GroupPostDto> mine(UUID groupId, UUID actor) {
        groups.active(groupId);
        groups.requireMember(groupId, actor);
        return posts.mine(groupId, actor).stream().map(this::map).toList();
    }

    private String text(CreateGroupPostRequest request) {
        if (request == null || request.content() == null || request.content().isBlank()) {
            throw new ApiException(400, "Nội dung bài viết không được để trống");
        }
        if (request.content().length() > 10000) throw new ApiException(400, "Bài viết quá dài");
        return request.content().trim();
    }

    @Transactional
    public GroupPostDto create(UUID groupId, UUID actor, CreateGroupPostRequest request) {
        GroupEntity group = groups.activeForUpdate(groupId);
        GroupMemberEntity member = groups.requireMember(groupId, actor);
        GroupPostEntity post = new GroupPostEntity();
        post.groupId = groupId;
        post.authorId = actor;
        post.content = text(request);
        post.status = group.requirePostApproval && member.role == GroupRole.MEMBER
                ? GroupPostStatus.PENDING : GroupPostStatus.PUBLISHED;
        posts.persist(post);
        return map(post);
    }

    @Transactional
    public GroupPostDto update(UUID groupId, UUID postId, UUID actor, CreateGroupPostRequest request) {
        GroupEntity group = groups.activeForUpdate(groupId);
        GroupMemberEntity member = groups.requireMember(groupId, actor);
        GroupPostEntity post = activePost(groupId, postId);
        if (!post.authorId.equals(actor)) throw new ApiException(403, "Bạn chỉ có thể sửa bài viết của mình");
        post.content = text(request);
        if (group.requirePostApproval && member.role == GroupRole.MEMBER) {
            post.status = GroupPostStatus.PENDING;
            post.moderatedBy = null;
            post.moderatedAt = null;
        } else {
            post.status = GroupPostStatus.PUBLISHED;
        }
        return map(post);
    }

    @Transactional
    public GroupPostDto moderate(UUID groupId, UUID postId, UUID actor, boolean approve) {
        groups.activeForUpdate(groupId);
        groups.requireAdmin(groupId, actor);
        GroupPostEntity post = activePost(groupId, postId);
        if (post.status != GroupPostStatus.PENDING) {
            throw new ApiException(409, "Bài viết không ở trạng thái chờ duyệt");
        }
        post.status = approve ? GroupPostStatus.PUBLISHED : GroupPostStatus.REJECTED;
        post.moderatedBy = actor;
        post.moderatedAt = LocalDateTime.now();
        return map(post);
    }

    @Transactional
    public void delete(UUID groupId, UUID postId, UUID actor) {
        groups.activeForUpdate(groupId);
        GroupMemberEntity member = groups.requireMember(groupId, actor);
        GroupPostEntity post = activePost(groupId, postId);
        if (!post.authorId.equals(actor) && member.role == GroupRole.MEMBER) {
            throw new ApiException(403, "Bạn không có quyền xóa bài viết này");
        }
        post.deletedAt = LocalDateTime.now();
    }
}
