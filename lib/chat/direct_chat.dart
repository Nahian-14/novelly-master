import 'package:flutter/material.dart';

import '../main_page/writer_profile.dart';
import 'chat_model.dart';
import 'chat_screen.dart';
import 'chat_service.dart';

Future<void> openDirectChat(
  BuildContext context, {
  required String userId,
  required String userName,
  String? avatarPath,
  ChatService? service,
}) async {
  final currentUser = WriterProfileScreen.currentUser;
  final chatService = service ?? ChatService.shared;
  final currentUserId = _chatIdentity(
    accountId: currentUser.accountId,
    displayName: currentUser.name,
  );
  final recipientId = _chatIdentity(accountId: userId, displayName: userName);
  late final ChatConversation conversation;
  try {
    conversation = await chatService.ensureConversation(
      currentUserId: currentUserId,
      userId: recipientId,
      userName: userName,
      avatarPath: avatarPath,
    );
    if (chatService.usesMongo) {
      await chatService.loadMessages(conversation.conversationId);
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open conversation: $error')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          ChatScreen(conversation: conversation, service: chatService),
    ),
  );
}

String _chatIdentity({required String accountId, required String displayName}) {
  final stableId = accountId.trim();
  if (stableId.isNotEmpty) return stableId;
  return 'local:${displayName.trim().toLowerCase()}';
}
