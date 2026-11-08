import '../utils/json_utils.dart';

/// Bao phân trang chuẩn của backend: `data = { content, page, size, total_elements, total_pages }`.
class PageData<T> {
  const PageData({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;

  bool get isEmpty => content.isEmpty;

  factory PageData.fromJson(
    dynamic json,
    T Function(Map<String, dynamic> item) parser,
  ) {
    final Map<String, dynamic> map = asMap(json);
    final List<T> items = asList(map['items'])
        .whereType<Map>()
        .map((dynamic item) => parser(asMap(item)))
        .toList(growable: false);
    return PageData<T>(
      content: items,
      page: asInt(map['page']),
      size: asInt(map['size'], fallback: items.length),
      totalElements: asInt(map['total_elements'], fallback: items.length),
      totalPages: asInt(map['total_pages'], fallback: items.isEmpty ? 0 : 1),
    );
  }

  factory PageData.empty() {
    return PageData<T>(
      content: <T>[],
      page: 0,
      size: 0,
      totalElements: 0,
      totalPages: 0,
    );
  }
}
