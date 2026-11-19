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
import java.time.LocalDateTime;

@ApplicationScoped
public class PostRepo implements PanacheRepositoryBase<Post, UUID> {

    /**
     * TÃ¬m bÃ i viáº¿t cÃ²n hoáº¡t Ä‘á»™ng (chÆ°a xÃ³a má»m) theo ID.
     */
    public Optional<Post> findActiveById(UUID id) {
        return find(
                "id = ?1 and isDeleted = false",
                id).firstResultOptional();
    }

    /**
     * Láº¥y bÃ i viáº¿t chi tiáº¿t kÃ¨m author vÃ  mediaList.
     *
     * DÃ¹ng fetch join Ä‘á»ƒ trÃ¡nh lazy loading khi láº¥y detail.
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
     * Láº¥y báº£ng tin (Newsfeed) cÃ³ phÃ¢n trang.
     *
     * Quy táº¯c privacy:
     * - PUBLIC: má»i ngÆ°á»i Ä‘á»u xem Ä‘Æ°á»£c.
     * - PRIVATE: chá»‰ chÃ­nh tÃ¡c giáº£ xem Ä‘Æ°á»£c.
     * - FRIENDS_ONLY: tÃ¡c giáº£ vÃ  báº¡n bÃ¨ Ä‘Ã£ ACCEPTED xem Ä‘Æ°á»£c.
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
     * Láº¥y bÃ i viáº¿t trÃªn dÃ²ng thá»i gian cÃ¡ nhÃ¢n cÃ³ phÃ¢n trang.
     *
     * Quy táº¯c privacy:
     * - Náº¿u currentUserId == targetUserId:
     * tháº¥y táº¥t cáº£ bÃ i chÆ°a xÃ³a cá»§a chÃ­nh mÃ¬nh.
     * - Náº¿u lÃ  ngÆ°á»i khÃ¡c:
     * PUBLIC -> xem Ä‘Æ°á»£c.
     * FRIENDS_ONLY -> chá»‰ xem náº¿u lÃ  báº¡n ACCEPTED.
     * PRIVATE -> khÃ´ng xem Ä‘Æ°á»£c.
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
     * TÃ¬m kiáº¿m bÃ i viáº¿t theo tá»« khÃ³a cÃ³ kiá»ƒm tra quyá»n riÃªng tÆ°.
     *
     * Quy táº¯c privacy:
     * - PUBLIC: má»i ngÆ°á»i Ä‘á»u xem Ä‘Æ°á»£c.
     * - PRIVATE: chá»‰ tÃ¡c giáº£ xem Ä‘Æ°á»£c.
     * - FRIENDS_ONLY: báº¡n bÃ¨ ACCEPTED xem Ä‘Æ°á»£c.
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
                  and lower(p.content) like lower(:keyword) escape '\'
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
     * TÃ¬m kiáº¿m bÃ i viáº¿t theo hashtag cÃ³ kiá»ƒm tra quyá»n riÃªng tÆ°.
     *
     * Há»— trá»£:
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

        // VÃ­ dá»¥ input chá»‰ lÃ  "#"
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

    /**Láº¥y bÃ i viáº¿t ná»•i báº­t (trending) trong N ngÃ y gáº§n nháº¥t, xáº¿p theo tÆ°Æ¡ng tÃ¡c.*/
    public PanacheQuery<Post> findTrending(UUID currentUserId, Page page, int days) {
        LocalDateTime since = LocalDateTime.now().minusDays(Math.max(1, days));
        return find("""
                select p
                from Post p
                where p.isDeleted = false
                  and p.createdAt >= :since
                  and (
                      p.privacy = :publicPrivacy
                      or p.author.id = :currentUserId
                      or (
                          p.privacy = :friendsPrivacy
                          and exists (
                              select 1 from Friendship f
                              where f.status = :acceptedStatus
                                and ((f.sender.id = :currentUserId and f.receiver.id = p.author.id)
                                     or (f.receiver.id = :currentUserId and f.sender.id = p.author.id))
                          )
                      )
                  )
                order by (p.like_count + p.comment_count) desc, p.createdAt desc, p.id desc
                """,
                Map.of(
                        "publicPrivacy", PostPrivacy.PUBLIC,
                        "friendsPrivacy", PostPrivacy.FRIENDS_ONLY,
                        "acceptedStatus", FriendRequestStatus.ACCEPTED,
                        "currentUserId", currentUserId,
                        "since", since))
                .page(page);
    }
}