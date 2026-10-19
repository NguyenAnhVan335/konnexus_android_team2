package com.meta.junior.repository;
import com.meta.junior.common.FriendRequestStatus;
import com.meta.junior.common.PostPrivacy;
import com.meta.junior.common.util.SqlUtils;
import com.meta.junior.entity.Post;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class PostRepo implements PanacheRepositoryBase<Post, UUID> {

    /**
     * Tìm bài viết còn hoạt động (chưa xóa mềm) theo ID.
     */
    public Optional<Post> findActiveById(UUID id) {
        return find(
                "id = ?1 and isDeleted = false",
                id).firstResultOptional();
    }

    /**
     * Lấy bài viết chi tiết kèm author và mediaList.
     *
     * Dùng fetch join để tránh lazy loading khi lấy detail.
     */
    public Optional<Post> findActiveByIdWithDetails(UUID id) {
        return find("""
                select distinct p
                from Post p
                left join fetch p.author
                left join fetch p.mediaList
                where p.id = :id
                  and p.isDeleted = false
                """,
                Map.of("id", id)).firstResultOptional();
    }

    /**
     * Lấy bảng tin (Newsfeed) có phân trang.
     *
     * Quy tắc privacy:
     * - PUBLIC: mọi người đều xem được.
     * - PRIVATE: chỉ chính tác giả xem được.
     * - FRIENDS_ONLY: tác giả và bạn bè đã ACCEPTED xem được.
     */
    public PanacheQuery<Post> findFeed(
            UUID currentUserId,
            Page page) {
        return find("""
                select p
                from Post p
                where p.isDeleted = false
                  and (
                      p.privacy = :publicPrivacy
                      or p.author.id = :currentUserId
                      or (
                          p.privacy = :friendsPrivacy
                          and exists (
                              select 1
                              from Friendship f
                              where f.status = :acceptedStatus
                                and (
                                    (f.sender.id = :currentUserId
                                     and f.receiver.id = p.author.id)
                                    or
                                    (f.receiver.id = :currentUserId
                                     and f.sender.id = p.author.id)
                                )
                          )
                      )
                  )
                order by p.createdAt desc, p.id desc
                """,
                Map.of(
                        "publicPrivacy", PostPrivacy.PUBLIC,
                        "friendsPrivacy", PostPrivacy.FRIENDS_ONLY,
                        "acceptedStatus", FriendRequestStatus.ACCEPTED,
                        "currentUserId", currentUserId))
                .page(page);
    }

    /**
     * Lấy bài viết trên dòng thời gian cá nhân có phân trang.
     *
     * Quy tắc privacy:
     * - Nếu currentUserId == targetUserId:
     * thấy tất cả bài chưa xóa của chính mình.
     * - Nếu là người khác:
     * PUBLIC -> xem được.
     * FRIENDS_ONLY -> chỉ xem nếu là bạn ACCEPTED.
     * PRIVATE -> không xem được.
     */
    public PanacheQuery<Post> findUserTimeline(
            UUID currentUserId,
            UUID targetUserId,
            Page page) {
        return find("""
                select p
                from Post p
                where p.isDeleted = false
                  and p.author.id = :targetUserId
                  and (
                      p.author.id = :currentUserId
                      or p.privacy = :publicPrivacy
                      or (
                          p.privacy = :friendsPrivacy
                          and exists (
                              select 1
                              from Friendship f
                              where f.status = :acceptedStatus
                                and (
                                    (f.sender.id = :currentUserId
                                     and f.receiver.id = :targetUserId)
                                    or
                                    (f.receiver.id = :currentUserId
                                     and f.sender.id = :targetUserId)
                                )
                          )
                      )
                  )
                order by p.createdAt desc, p.id desc
                """,
                Map.of(
                        "currentUserId", currentUserId,
                        "targetUserId", targetUserId,
                        "publicPrivacy", PostPrivacy.PUBLIC,
                        "friendsPrivacy", PostPrivacy.FRIENDS_ONLY,
                        "acceptedStatus", FriendRequestStatus.ACCEPTED))
                .page(page);
    }

    /**
     * Tìm kiếm bài viết theo từ khóa có kiểm tra quyền riêng tư.
     *
     * Quy tắc privacy:
     * - PUBLIC: mọi người đều xem được.
     * - PRIVATE: chỉ tác giả xem được.
     * - FRIENDS_ONLY: bạn bè ACCEPTED xem được.
     */
    public PanacheQuery<Post> searchByKeyword(
            UUID currentUserId,
            String keyword,
            Page page) {
        if (keyword == null || keyword.isBlank()) {
            return find("1 = 0").page(page);
        }

        String normalizedKeyword = keyword.trim();

        if (normalizedKeyword.isBlank()) {
            return find("1 = 0").page(page);
        }

        String query = """
                select p
                from Post p
                left join fetch p.author
                where p.isDeleted = false
                  and lower(p.content) like lower(:keyword) escape '\\\\'
                  and (
                      p.privacy = :publicPrivacy
                      or p.author.id = :currentUserId
                      or (
                          p.privacy = :friendsPrivacy
                          and exists (
                              select 1
                              from Friendship f
                              where f.status = :acceptedStatus
                                and (
                                    (f.sender.id = :currentUserId
                                     and f.receiver.id = p.author.id)
                                    or
                                    (f.receiver.id = :currentUserId
                                     and f.sender.id = p.author.id)
                                )
                          )
                      )
                  )
                order by p.createdAt desc, p.id desc
                """;

        return find(
                query,
                Map.of(
                        "keyword", "%" + SqlUtils.escapeLike(normalizedKeyword) + "%",
                        "currentUserId", currentUserId,
                        "publicPrivacy", PostPrivacy.PUBLIC,
                        "friendsPrivacy", PostPrivacy.FRIENDS_ONLY,
                        "acceptedStatus", FriendRequestStatus.ACCEPTED))
                .page(page);
    }

    /**
     * Tìm kiếm bài viết theo hashtag có kiểm tra quyền riêng tư.
     *
     * Hỗ trợ:
     * - dalat
     * - #dalat
     */
    public PanacheQuery<Post> searchByHashtag(
            UUID currentUserId,
            String tagName,
            Page page) {
        if (tagName == null || tagName.isBlank()) {
            return find("1 = 0").page(page);
        }

        String cleanTagName = tagName.trim();

        if (cleanTagName.startsWith("#")) {
            cleanTagName = cleanTagName.substring(1);
        }

        cleanTagName = cleanTagName
                .trim()
                .toLowerCase(Locale.ROOT);

        // Ví dụ input chỉ là "#"
        if (cleanTagName.isBlank()) {
            return find("1 = 0").page(page);
        }

        String query = """
                select p
                from Post p
                left join fetch p.author
                where p.isDeleted = false
                  and exists (
                      select 1
                      from PostHashtag ph
                      where ph.post = p
                        and ph.hashtag.name = :tagName
                  )
                  and (
                      p.privacy = :publicPrivacy
                      or p.author.id = :currentUserId
                      or (
                          p.privacy = :friendsPrivacy
                          and exists (
                              select 1
                              from Friendship f
                              where f.status = :acceptedStatus
                                and (
                                    (f.sender.id = :currentUserId
                                     and f.receiver.id = p.author.id)
                                    or
                                    (f.receiver.id = :currentUserId
                                     and f.sender.id = p.author.id)
                                )
                          )
                      )
                  )
                order by p.createdAt desc, p.id desc
                """;

        return find(
                query,
                Map.of(
                        "tagName", cleanTagName,
                        "currentUserId", currentUserId,
                        "publicPrivacy", PostPrivacy.PUBLIC,
                        "friendsPrivacy", PostPrivacy.FRIENDS_ONLY,
                        "acceptedStatus", FriendRequestStatus.ACCEPTED))
                .page(page);
    }
}