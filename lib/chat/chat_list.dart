import 'package:flutter/material.dart';

import '../main_page/novelly_bottom_navigation.dart';
import '../main_page/writer_profile.dart';
import '../theme/theme_controller.dart';
import 'chat_model.dart';
import 'chat_screen.dart';
import 'chat_service.dart';
import '../widgets/image_provider_for_path.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({this.service, super.key});

  final ChatService? service;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  ChatService get _chatService => widget.service ?? ChatService.shared;

  @override
  void initState() {
    super.initState();
    if (_chatService.usesMongo) {
      _chatService.currentUserId = WriterProfileScreen.currentUser.accountId;
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    try {
      await _chatService.loadConversations();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load messages: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = _chatService;
    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.paperColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  final horizontalPadding = (constraints.maxWidth * 0.05).clamp(
                    compact ? 16.0 : 20.0,
                    38.0,
                  );
                  final account = WriterProfileScreen.currentUser;
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          16,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: theme.inkColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Messages',
                                style: TextStyle(
                                  color: theme.inkColor,
                                  fontFamily: 'Georgia',
                                  fontSize: 25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: theme.lineColor),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: chatService,
                          builder: (context, _) {
                            final conversations = chatService.conversations;
                            if (conversations.isEmpty) {
                              return _EmptyConversations(theme: theme);
                            }
                            return ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 12,
                              ),
                              itemCount: conversations.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: theme.lineColor,
                                indent: 72,
                              ),
                              itemBuilder: (context, index) {
                                final conversation = conversations[index];
                                return _ConversationTile(
                                  conversation: conversation,
                                  theme: theme,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ChatScreen(
                                        conversation: conversation,
                                        service: chatService,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 7 : 10,
                          horizontalPadding,
                          compact ? 8 : 10,
                        ),
                        child: NovellyBottomNavigation(
                          libraryLabel: account.isCoverArtist
                              ? 'My Designs'
                              : account.isPublisher
                              ? 'My Publishing'
                              : 'My Book',
                          libraryIcon: account.isCoverArtist
                              ? Icons.palette_outlined
                              : Icons.menu_book_outlined,
                          selectedDestination:
                              NovellyNavigationDestination.chat,
                          compact: compact,
                          onDestinationSelected: (destination) {
                            handleNovellyNavigation(
                              context: context,
                              currentDestination:
                                  NovellyNavigationDestination.chat,
                              targetDestination: destination,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.theme,
    required this.onTap,
  });

  final ChatConversation conversation;
  final NovellyThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(conversation.conversationId),
    background: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: theme.accentGold,
      child: const Row(
        children: [
          Icon(Icons.push_pin_outlined, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Pin Chat',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    secondaryBackground: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Colors.redAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Archive',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.archive_outlined, color: Colors.white),
        ],
      ),
    ),
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.startToEnd) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pinned ${conversation.userName}\'s conversation 📌'),
          ),
        );
        return false;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Archived conversation with ${conversation.userName}',
            ),
          ),
        );
        return true;
      }
    },
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            _ProfileAvatar(
              imagePath: conversation.avatarPath,
              online: conversation.isOnline,
              radius: 27,
              theme: theme,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.inkColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    conversation.lastMessagePreview ?? 'Start a conversation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.mutedColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatConversationTime(conversation.lastMessageAt),
                  style: TextStyle(color: theme.mutedColor, fontSize: 11),
                ),
                const SizedBox(height: 7),
                if (conversation.unreadCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 21),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.inkColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.paperColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imagePath,
    required this.online,
    required this.radius,
    required this.theme,
  });

  final String? imagePath;
  final bool online;
  final double radius;
  final NovellyThemeData theme;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: theme.deepInkColor,
        child: imagePath == null
            ? Icon(Icons.person, color: theme.accentGold, size: radius * 1.15)
            : ClipOval(
                child: Image(
                  image: imageProviderForPath(imagePath!),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person,
                    color: theme.accentGold,
                    size: radius * 1.15,
                  ),
                ),
              ),
      ),
      if (online)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF3D936A),
              shape: BoxShape.circle,
              border: Border.all(color: theme.paperColor, width: 2),
            ),
          ),
        ),
    ],
  );
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations({required this.theme});

  final NovellyThemeData theme;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, color: theme.accentGold, size: 48),
          const SizedBox(height: 14),
          Text(
            'No conversations yet',
            style: TextStyle(
              color: theme.inkColor,
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Your messages with other readers and writers will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.mutedColor, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

String _formatConversationTime(DateTime? time) {
  if (time == null) return '';
  final now = DateTime.now();
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} '
        '${time.hour < 12 ? 'AM' : 'PM'}';
  }
  if (now.difference(time).inDays < 2) return 'Yesterday';
  return '${time.day}/${time.month}/${time.year}';
}
