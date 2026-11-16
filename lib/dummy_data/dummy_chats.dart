import '../chat/chat_model.dart';
import '../chat/chat_service.dart';

/// Populates mock chat service for offline testing
ChatService createBangladeshiChatService() {
  final now = DateTime.now();
  const humayunConvoId = 'convo-humayun-ahmed';
  const prothomaConvoId = 'convo-prothoma-prokashan';
  const dhrubaConvoId = 'convo-dhruba-esh';
  const batigharConvoId = 'convo-batighar-prokashani';

  return ChatService(
    conversations: [
      ChatConversation(
        conversationId: humayunConvoId,
        userId: 'humayun-ahmed',
        userName: 'Humayun Ahmed',
        isOnline: true,
        lastMessagePreview: 'I am glad you felt connected to the story.',
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
        unreadCount: 1,
      ),
      ChatConversation(
        conversationId: prothomaConvoId,
        userId: 'prothoma-prokashan',
        userName: 'Prothoma Prokashan',
        isOnline: true,
        lastMessagePreview: 'We would love to publish it in Ekushey Boi Mela!',
        lastMessageAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        unreadCount: 2,
      ),
      ChatConversation(
        conversationId: dhrubaConvoId,
        userId: 'dhruba-esh',
        userName: 'Dhruba Esh (Cover Artist)',
        isOnline: false,
        lastMessagePreview: 'I used classic Bengali calligraphy for the cover draft.',
        lastMessageAt: now.subtract(const Duration(hours: 4, minutes: 30)),
      ),
      ChatConversation(
        conversationId: batigharConvoId,
        userId: 'batighar-prokashani',
        userName: 'Batighar Prokashani',
        isOnline: true,
        lastMessagePreview: 'Your special edition of Pather Panchali has shipped!',
        lastMessageAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ],
    messages: [
      ChatMessage(
        messageId: 'h-1',
        conversationId: humayunConvoId,
        senderId: 'humayun-ahmed',
        type: ChatMessageType.text,
        text: 'Salam! Thank you for reading Nondito Noroke.',
        sentAt: now.subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        messageId: 'h-2',
        conversationId: humayunConvoId,
        senderId: 'current-user',
        type: ChatMessageType.text,
        text: 'Salam sir! It is a masterpiece. The emotions in every chapter touched my heart.',
        sentAt: now.subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        messageId: 'h-3',
        conversationId: humayunConvoId,
        senderId: 'humayun-ahmed',
        type: ChatMessageType.text,
        text: 'I am glad you felt connected to the story. Have you read Misir Ali yet?',
        sentAt: now.subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        messageId: 'h-4',
        conversationId: humayunConvoId,
        senderId: 'current-user',
        type: ChatMessageType.text,
        text: 'Yes! Misir Ali\'s logical approach to mysteries is brilliant.',
        sentAt: now.subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        messageId: 'h-5',
        conversationId: humayunConvoId,
        senderId: 'humayun-ahmed',
        type: ChatMessageType.text,
        text: 'I am glad you felt connected to the story.',
        sentAt: now.subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        messageId: 'p-1',
        conversationId: prothomaConvoId,
        senderId: 'prothoma-prokashan',
        type: ChatMessageType.text,
        text: 'Hello! We reviewed your manuscript submission for the new story collection.',
        sentAt: now.subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        messageId: 'p-2',
        conversationId: prothomaConvoId,
        senderId: 'current-user',
        type: ChatMessageType.text,
        text: 'Thank you! I am looking forward to hearing your feedback.',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      ),
      ChatMessage(
        messageId: 'p-3',
        conversationId: prothomaConvoId,
        senderId: 'prothoma-prokashan',
        type: ChatMessageType.text,
        text: 'We would love to publish it in Ekushey Boi Mela!',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 12)),
      ),
      ChatMessage(
        messageId: 'd-1',
        conversationId: dhrubaConvoId,
        senderId: 'dhruba-esh',
        type: ChatMessageType.text,
        text: 'Salam! I used classic Bengali calligraphy for the cover draft.',
        sentAt: now.subtract(const Duration(hours: 4, minutes: 30)),
      ),
      ChatMessage(
        messageId: 'b-1',
        conversationId: batigharConvoId,
        senderId: 'batighar-prokashani',
        type: ChatMessageType.text,
        text: 'Your special edition of Pather Panchali has shipped!',
        sentAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ],
  );
}
