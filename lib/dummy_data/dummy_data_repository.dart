import '../chat/chat_service.dart';
import '../cover/cover_design.dart';
import '../main_page/discover_book.dart';
import '../main_page/writer_profile.dart';
import '../publisher/publisher._directory.dart';

import 'dummy_books.dart';
import 'dummy_chats.dart';
import 'dummy_cover_artists.dart';
import 'dummy_publishers.dart';
import 'dummy_users.dart';

export 'dummy_books.dart';
export 'dummy_chats.dart';
export 'dummy_cover_artists.dart';
export 'dummy_publishers.dart';
export 'dummy_users.dart';

/// Central repository providing offline mock testing data for Novelly UI
class DummyDataRepository {
  /// Set to [true] to show dummy test data throughout the app.
  /// Set to [false] to hide dummy data (e.g. for testing empty states or live Firebase data).
  static const bool useDummyData = false;

  static List<DiscoverBook> get books =>
      useDummyData ? bangladeshiDiscoverBooks : const [];

  static List<PublisherEntry> get publishers =>
      useDummyData ? bangladeshiPublisherDirectory : const [];

  static List<WriterProfile> get coverArtists =>
      useDummyData ? bangladeshiCoverArtists : const [];

  static List<CoverDesign> get coverDesigns =>
      useDummyData ? bangladeshiCoverDesigns : const [];

  static List<CoverDesign> get coverDrafts =>
      useDummyData ? bangladeshiCoverDrafts : const [];

  static WriterProfile get currentUser => useDummyData
      ? defaultBangladeshiCurrentUser
      : const WriterProfile(name: 'User');

  static ChatService createChatService() =>
      useDummyData ? createBangladeshiChatService() : ChatService();
}
