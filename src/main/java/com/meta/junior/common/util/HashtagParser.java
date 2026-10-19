package com.meta.junior.common.util;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utility bóc tách và chuẩn hóa Hashtags từ nội dung văn bản
 */
public final class HashtagParser {

    /**
     * Regex nhận diện hashtag: bắt đầu bằng # theo sau là chữ cái (hỗ trợ Unicode tiếng Việt), số hoặc dấu gạch dưới
     */
    private static final Pattern HASHTAG_PATTERN = Pattern.compile("#([\\p{L}0-9_]+)");
    private static final int MAX_TAG_LENGTH = 100;

    private HashtagParser() {
        // Utility class
    }

    /**
     * Bóc tách danh sách các hashtag duy nhất từ nội dung văn bản
     * @param content Nội dung bài viết
     * @return Tập hợp tên hashtag (không chứa ký tự #, đã chuẩn hóa chữ thường)
     */
    public static Set<String> extractTags(String content) {
        if (content == null || content.isBlank()) {
            return Collections.emptySet();
        }

        Set<String> tags = new LinkedHashSet<>();
        Matcher matcher = HASHTAG_PATTERN.matcher(content);

        while (matcher.find()) {
            String tag = matcher.group(1).trim().toLowerCase();
            if (!tag.isEmpty() && tag.length() <= MAX_TAG_LENGTH) {
                tags.add(tag);
            }
        }

        return tags;
    }
}
