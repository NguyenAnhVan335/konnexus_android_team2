package alan.nguyen.dto;

import java.util.List;

/**
 * DTO chuẩn hóa kết quả phân trang (Pagination Response)
 * @param <T> Kiểu dữ liệu của các phần tử trong danh sách items
 */
public record PageResponseDTO<T>(
        List<T> items,
        int page,
        int size,
        long total_elements,
        int total_pages,
        boolean is_last
) {
    public static <T> PageResponseDTO<T> of(List<T> items, int page, int size, long totalElements, int totalPages) {
        boolean isLast = (page + 1) >= totalPages || totalPages == 0;
        return new PageResponseDTO<>(items, page, size, totalElements, totalPages, isLast);
    }
}
