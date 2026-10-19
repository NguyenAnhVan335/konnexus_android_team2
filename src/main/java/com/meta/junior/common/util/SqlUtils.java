package com.meta.junior.common.util;

/**
 * Utility hỗ trợ xử lý và chuẩn hóa chuỗi cho các câu truy vấn SQL / HQL
 */
public final class SqlUtils {

    private SqlUtils() {
        // Utility class - ngăn ngừa khởi tạo đối tượng
    }

    /**
     * Escape các ký tự wildcard đặc biệt trong câu truy vấn LIKE của SQL:
     * Thứ tự escape:
     * 1. Dấu gạch chéo ngược '\' -> '\\' (bắt buộc escape đầu tiên)
     * 2. Ký tự '%' -> '\%' (ký tự đại diện cho 0 hoặc nhiều ký tự bất kỳ)
     * 3. Ký tự '_' -> '\_' (ký tự đại diện cho 1 ký tự bất kỳ)
     *
     * @param input Chuỗi đầu vào của người dùng
     * @return Chuỗi đã được escape an toàn để dùng với toán tử LIKE :param ESCAPE '\'
     */
    public static String escapeLike(String input) {
        if (input == null) {
            return "";
        }
        return input
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_");
    }
}
