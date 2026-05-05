import 'package:meta_plogging/features/feed/domain/entities/post_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_provider.g.dart';

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  List<PostEntity> build() => List.from(kMockPosts);

  void toggleLike(String postId) {
    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            isLiked: !post.isLiked,
            likeCount:
                post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
          )
        else
          post,
    ];
  }

  void toggleBookmark(String postId) {
    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(isBookmarked: !post.isBookmarked)
        else
          post,
    ];
  }

  void addPost(PostEntity post) {
    state = [post, ...state];
  }
}
