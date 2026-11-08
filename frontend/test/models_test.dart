import 'package:flutter_test/flutter_test.dart';
import 'package:konnexus/models/page_data.dart';
import 'package:konnexus/models/post_model.dart';
import 'package:konnexus/utils/formatters.dart';
import 'package:konnexus/utils/json_utils.dart';
import 'package:konnexus/utils/validators.dart';

void main() {
  group('PostModel.fromJson', () {
    test('đọc đúng payload snake_case của PostResponse', () {
      final PostModel post = PostModel.fromJson(<String, dynamic>{
        'id': 'post-1',
        'author': <String, dynamic>{
          'id': 'user-1',
          'username': 'minhanh',
          'avatar_url': null,
        },
        'content': 'Xin chào Konexus',
        'privacy': 'FRIENDS_ONLY',
        'like_count': 3,
        'comment_count': 2,
        'media_list': <dynamic>[
          <String, dynamic>{
            'id': 'media-1',
            'media_url': 'https://example.com/a.jpg',
            'media_type': 'IMAGE',
            'display_order': 0,
          },
        ],
        'created_at': '2026-10-19T09:30:00',
        'updated_at': '2026-10-19T09:35:00',
        'is_edited': true,
        'is_liked': true,
        'reactions': <String, dynamic>{
          'total': 3,
          'by_type': <String, dynamic>{'LIKE': 3},
          'my_reaction': 'LIKE',
        },
        'comments': <dynamic>[
          <String, dynamic>{
            'id': 'comment-1',
            'post_id': 'post-1',
            'parent_comment_id': null,
            'content': 'Hay quá',
            'image': null,
            'created_at': '2026-10-19T09:40:00',
          },
        ],
      });

      expect(post.id, 'post-1');
      expect(post.author.username, 'minhanh');
      expect(post.privacy, PostPrivacy.friends);
      expect(post.likeCount, 3);
      expect(post.media.single.kind, MediaKind.image);
      expect(post.liked, isTrue);
      expect(post.edited, isTrue);
      expect(post.reactions?.myReaction, 'LIKE');
      expect(post.comments?.single.content, 'Hay quá');
    });

    test('giá trị thiếu/không hợp lệ không làm sập parser', () {
      final PostModel post = PostModel.fromJson(<String, dynamic>{
        'id': 'post-2',
        'author': <String, dynamic>{},
        'privacy': null,
        'media_list': null,
      });

      expect(post.privacy, PostPrivacy.public);
      expect(post.content, isNull);
      expect(post.media, isEmpty);
      expect(post.author.displayName, 'Người dùng');
      expect(post.liked, isFalse);
    });
  });

  group('PageData.fromJson', () {
    test('đọc envelope phân trang', () {
      final PageData<PostModel> page = PageData<PostModel>.fromJson(
        <String, dynamic>{
          'items': <dynamic>[
            <String, dynamic>{
              'id': 'p1',
              'author': <String, dynamic>{'id': 'u1'}
            },
          ],
          'page': 0,
          'size': 10,
          'total_elements': 11,
          'total_pages': 2,
        },
        PostModel.fromJson,
      );

      expect(page.content.length, 1);
      expect(page.totalElements, 11);
      expect(page.hasMore, isTrue);
    });
  });

  group('Validators', () {
    test('kiểm tra đăng ký', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('konexus'), isNull);
      expect(Validators.email('sai-email'), isNotNull);
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.confirmPassword('123456', '123456'), isNull);
      expect(Validators.confirmPassword('123456', '654321'), isNotNull);
    });

    test('bài viết cần nội dung hoặc media', () {
      expect(Validators.postContent('   ', hasMedia: false), isNotNull);
      expect(Validators.postContent('   ', hasMedia: true), isNull);
      expect(Validators.postContent('Nội dung', hasMedia: false), isNull);
    });

    test('media URL chỉ nhận http/https', () {
      expect(Validators.mediaUrl('ftp://example.com/a.png'), isNotNull);
      expect(Validators.mediaUrl('khong-phai-url'), isNotNull);
      expect(Validators.mediaUrl('https://example.com/a.png'), isNull);
    });
  });

  group('utils', () {
    test('asMap/asList xử lý dữ liệu null', () {
      expect(asMap(null), isEmpty);
      expect(asList(null), isEmpty);
      expect(asString(42), '42');
      expect(asInt('7'), 7);
      expect(asBool('true'), isTrue);
    });

    test('initialsOf và formatCount', () {
      expect(initialsOf('Nguyễn Minh Anh'), 'NA');
      expect(initialsOf('Konexus'), 'K');
      expect(formatCount(1500), '1,5K');
      expect(formatCount(1200000), '1,2M');
    });
  });
}
