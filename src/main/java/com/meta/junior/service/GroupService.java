package com.meta.junior.service;

import com.meta.junior.dto.*;
import com.meta.junior.entity.*;
import com.meta.junior.exception.ApiException;
import com.meta.junior.repository.*;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class GroupService {
    @Inject GroupRepository groups;
    @Inject GroupMemberRepository members;
    @Inject GroupJoinRequestRepository requests;

    public GroupEntity active(UUID groupId) {
        return groups.findActive(groupId).orElseThrow(() -> new ApiException(404, "Không tìm thấy nhóm"));
    }

    public GroupEntity activeForUpdate(UUID groupId) {
        return groups.findActiveForUpdate(groupId)
                .orElseThrow(() -> new ApiException(404, "Không tìm thấy nhóm"));
    }

    public Optional<GroupMemberEntity> membership(UUID groupId, UUID userId) {
        if (userId == null) return Optional.empty();
        return members.findMembership(groupId, userId);
    }

    public GroupMemberEntity requireMember(UUID groupId, UUID userId) {
        return membership(groupId, userId)
                .orElseThrow(() -> new ApiException(403, "Bạn chưa là thành viên nhóm"));
    }

    public GroupMemberEntity requireAdmin(UUID groupId, UUID userId) {
        GroupMemberEntity member = requireMember(groupId, userId);
        if (member.role != GroupRole.ADMIN && member.role != GroupRole.OWNER) {
            throw new ApiException(403, "Chỉ chủ nhóm hoặc quản trị viên có quyền thực hiện");
        }
        return member;
    }

    private void requireOwner(GroupEntity group, UUID actor) {
        if (!group.ownerId.equals(actor)) throw new ApiException(403, "Chỉ chủ nhóm có quyền thực hiện");
    }

    private GroupDto map(GroupEntity group, UUID viewer) {
        GroupRole role = membership(group.id, viewer).map(m -> m.role).orElse(null);
        return new GroupDto(group.id, group.name, group.description, group.privacy,
                group.ownerId, group.coverUrl, group.requirePostApproval,
                members.countMembers(group.id), role, group.createdAt);
    }

    @Transactional
    public GroupDto create(UUID actor, CreateGroupRequest request) {
        if (request == null) throw new ApiException(400, "Thiếu nội dung tạo nhóm");
        if (request.name() == null || request.name().isBlank()) {
            throw new ApiException(400, "Tên nhóm không được để trống");
        }
        GroupEntity group = new GroupEntity();
        group.name = request.name().trim();
        group.description = request.description();
        group.privacy = request.privacy() == null ? GroupPrivacy.PUBLIC : request.privacy();
        group.coverUrl = request.coverUrl();
        group.ownerId = actor;
        group.requirePostApproval = Boolean.TRUE.equals(request.requirePostApproval());
        groups.persist(group);

        GroupMemberEntity owner = new GroupMemberEntity();
        owner.groupId = group.id;
        owner.userId = actor;
        owner.role = GroupRole.OWNER;
        members.persist(owner);
        return map(group, actor);
    }

    public List<GroupDto> search(String keyword, UUID viewer) {
        return groups.search(keyword).stream().map(g -> map(g, viewer)).toList();
    }

    public List<GroupDto> mine(UUID actor) {
        return members.findByUser(actor).stream()
                .map(m -> groups.findActive(m.groupId).orElse(null))
                .filter(java.util.Objects::nonNull)
                .map(g -> map(g, actor)).toList();
    }

    public GroupDto detail(UUID groupId, UUID viewer) {
        return map(active(groupId), viewer);
    }

    @Transactional
    public GroupDto update(UUID groupId, UUID actor, UpdateGroupRequest request) {
        if (request == null) throw new ApiException(400, "Thiếu nội dung cập nhật");
        GroupEntity group = activeForUpdate(groupId);
        requireAdmin(groupId, actor);
        if (request.name() != null) {
            if (request.name().isBlank()) throw new ApiException(400, "Tên nhóm không được để trống");
            group.name = request.name().trim();
        }
        if (request.description() != null) group.description = request.description();
        if (request.coverUrl() != null) group.coverUrl = request.coverUrl();
        if (request.privacy() != null) group.privacy = request.privacy();
        if (request.requirePostApproval() != null) {
            group.requirePostApproval = request.requirePostApproval();
        }
        return map(group, actor);
    }

    /** Soft deletion: members, requests and posts remain in the database for audit/recovery. */
    @Transactional
    public void delete(UUID groupId, UUID actor) {
        GroupEntity group = activeForUpdate(groupId);
        requireOwner(group, actor);
        group.deletedAt = java.time.LocalDateTime.now();
        group.deletedBy = actor;
    }

    @Transactional
    public GroupJoinResultDto join(UUID groupId, UUID actor) {
        GroupEntity group = activeForUpdate(groupId);
        if (membership(groupId, actor).isPresent()) {
            throw new ApiException(409, "Bạn đã là thành viên nhóm");
        }
        Optional<GroupJoinRequestEntity> existing = requests.findByGroupAndUser(groupId, actor);
        if (group.privacy == GroupPrivacy.PUBLIC) {
            GroupMemberEntity member = new GroupMemberEntity();
            member.groupId = groupId;
            member.userId = actor;
            member.role = GroupRole.MEMBER;
            members.persist(member);
            existing.ifPresent(r -> { r.status = GroupJoinStatus.APPROVED; r.resolvedBy = null; });
            return new GroupJoinResultDto(groupId, "JOINED");
        }
        if (existing.isPresent() && existing.get().status == GroupJoinStatus.PENDING) {
            throw new ApiException(409, "Bạn đã gửi yêu cầu tham gia nhóm này");
        }
        GroupJoinRequestEntity joinRequest = existing.orElseGet(GroupJoinRequestEntity::new);
        joinRequest.groupId = groupId;
        joinRequest.userId = actor;
        joinRequest.status = GroupJoinStatus.PENDING;
        joinRequest.resolvedBy = null;
        if (existing.isEmpty()) requests.persist(joinRequest);
        return new GroupJoinResultDto(groupId, "PENDING");
    }

    public GroupMembershipStatusDto status(UUID groupId, UUID actor) {
        active(groupId);
        Optional<GroupMemberEntity> m = membership(groupId, actor);
        if (m.isPresent()) return new GroupMembershipStatusDto(groupId, "MEMBER", m.get().role);
        boolean pending = requests.findByGroupAndUser(groupId, actor)
                .map(r -> r.status == GroupJoinStatus.PENDING).orElse(false);
        return new GroupMembershipStatusDto(groupId, pending ? "PENDING" : "NONE", null);
    }

    @Transactional
    public void cancelJoinRequest(UUID groupId, UUID actor) {
        activeForUpdate(groupId);
        GroupJoinRequestEntity request = requests.findByGroupAndUser(groupId, actor)
                .orElseThrow(() -> new ApiException(404, "Không tìm thấy yêu cầu tham gia"));
        if (request.status != GroupJoinStatus.PENDING) {
            throw new ApiException(409, "Yêu cầu không còn ở trạng thái chờ duyệt");
        }
        request.status = GroupJoinStatus.CANCELED;
        request.resolvedBy = actor;
    }

    public List<GroupJoinRequestDto> pendingRequests(UUID groupId, UUID actor) {
        active(groupId);
        requireAdmin(groupId, actor);
        return requests.pendingInGroup(groupId).stream().map(this::mapRequest).toList();
    }

    private GroupJoinRequestDto mapRequest(GroupJoinRequestEntity r) {
        return new GroupJoinRequestDto(r.id, r.groupId, r.userId, r.status, r.createdAt);
    }

    @Transactional
    public GroupMemberDto approve(UUID groupId, UUID requestId, UUID actor) {
        activeForUpdate(groupId);
        requireAdmin(groupId, actor);
        GroupJoinRequestEntity request = requested(groupId, requestId);
        if (request.status != GroupJoinStatus.PENDING) {
            throw new ApiException(409, "Yêu cầu không còn ở trạng thái chờ duyệt");
        }
        if (membership(groupId, request.userId).isPresent()) {
            throw new ApiException(409, "Người dùng đã là thành viên");
        }
        GroupMemberEntity member = new GroupMemberEntity();
        member.groupId = groupId;
        member.userId = request.userId;
        member.role = GroupRole.MEMBER;
        members.persist(member);
        request.status = GroupJoinStatus.APPROVED;
        request.resolvedBy = actor;
        return mapMember(member);
    }

    @Transactional
    public void reject(UUID groupId, UUID requestId, UUID actor) {
        activeForUpdate(groupId);
        requireAdmin(groupId, actor);
        GroupJoinRequestEntity request = requested(groupId, requestId);
        if (request.status != GroupJoinStatus.PENDING) {
            throw new ApiException(409, "Yêu cầu không còn ở trạng thái chờ duyệt");
        }
        request.status = GroupJoinStatus.REJECTED;
        request.resolvedBy = actor;
    }

    private GroupJoinRequestEntity requested(UUID groupId, UUID requestId) {
        GroupJoinRequestEntity request = requests.findByIdOptional(requestId)
                .orElseThrow(() -> new ApiException(404, "Không tìm thấy yêu cầu tham gia"));
        if (!groupId.equals(request.groupId)) throw new ApiException(404, "Không tìm thấy yêu cầu tham gia");
        return request;
    }

    public List<GroupMemberDto> listMembers(UUID groupId, UUID actor) {
        GroupEntity group = active(groupId);
        if (group.privacy == GroupPrivacy.PRIVATE) requireMember(groupId, actor);
        return members.findMembers(groupId).stream().map(this::mapMember).toList();
    }

    private GroupMemberDto mapMember(GroupMemberEntity m) {
        return new GroupMemberDto(m.userId, m.role, m.joinedAt);
    }

    @Transactional
    public void leave(UUID groupId, UUID actor) {
        activeForUpdate(groupId);
        GroupMemberEntity member = requireMember(groupId, actor);
        if (member.role == GroupRole.OWNER) {
            throw new ApiException(409, "Chủ nhóm cần chuyển quyền sở hữu trước khi rời nhóm");
        }
        members.delete(member);
    }

    @Transactional
    public void removeMember(UUID groupId, UUID targetId, UUID actor) {
        activeForUpdate(groupId);
        GroupMemberEntity admin = requireAdmin(groupId, actor);
        GroupMemberEntity target = requireMember(groupId, targetId);
        if (target.role == GroupRole.OWNER || (admin.role == GroupRole.ADMIN && target.role == GroupRole.ADMIN)) {
            throw new ApiException(403, "Bạn không có quyền xóa thành viên này");
        }
        members.delete(target);
    }

    @Transactional
    public GroupMemberDto changeAdmin(UUID groupId, UUID targetId, UUID actor, boolean promote) {
        GroupEntity group = activeForUpdate(groupId);
        requireOwner(group, actor);
        GroupMemberEntity member = requireMember(groupId, targetId);
        if (member.role == GroupRole.OWNER) throw new ApiException(409, "Không thể đổi quyền chủ nhóm");
        member.role = promote ? GroupRole.ADMIN : GroupRole.MEMBER;
        return mapMember(member);
    }

    @Transactional
    public GroupDto transferOwnership(UUID groupId, UUID targetId, UUID actor) {
        GroupEntity group = activeForUpdate(groupId);
        requireOwner(group, actor);
        if (actor.equals(targetId)) throw new ApiException(409, "Bạn đã là chủ nhóm");
        GroupMemberEntity next = requireMember(groupId, targetId);
        GroupMemberEntity former = requireMember(groupId, actor);
        former.role = GroupRole.ADMIN;
        next.role = GroupRole.OWNER;
        group.ownerId = targetId;
        return map(group, actor);
    }
}
