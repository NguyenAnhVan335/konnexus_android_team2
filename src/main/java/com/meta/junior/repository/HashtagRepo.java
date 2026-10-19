package com.meta.junior.repository;

import com.meta.junior.entity.Hashtag;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class HashtagRepo implements PanacheRepositoryBase<Hashtag, UUID> {

    /**
     * Tìm hashtag theo tên (chuẩn hóa chữ thường)
     */
    public Optional<Hashtag> findByName(String name) {
        if (name == null || name.isBlank()) {
            return Optional.empty();
        }
        return find("name = ?1", name.trim().toLowerCase()).firstResultOptional();
    }

    /**
     * Lấy danh sách Top Hashtags thịnh hành (được sử dụng nhiều nhất)
     */
    public List<Hashtag> findTopTrending(int limit) {
        int pageSize = limit > 0 ? limit : 10;
        return find("order by usage_count desc, created_at desc")
                .page(Page.of(0, pageSize))
                .list();
    }

    /**
     * Tìm kiếm gợi ý hashtag theo tiền tố (dùng cho autocomplete khi người dùng gõ #...)
     */
    public List<Hashtag> searchByNamePrefix(String prefix, int limit) {
        if (prefix == null || prefix.isBlank()) {
            return List.of();
        }
        int pageSize = limit > 0 ? limit : 5;
        return find("name like ?1 order by usage_count desc", prefix.trim().toLowerCase() + "%")
                .page(Page.of(0, pageSize))
                .list();
    }
}
