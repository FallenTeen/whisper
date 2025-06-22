class ApiConstants {
  static const String baseUrl = 'https://whisperapi.stdia.my.id';
  static const String wsBaseUrl = 'ws://whisperapi.stdia.my.id';

  static const String apiUrl = '$baseUrl/api';
  static const String loginUrl = '$apiUrl/login';
  static const String registerUrl = '$apiUrl/register';
  static const String logoutUrl = '$apiUrl/logout';
  static const String chatRoomsUrl = '$apiUrl/chat/rooms';
  static const String createPrivateChatUrl = '$apiUrl/chat/rooms/private';
  static const String searchUsersUrl = '$apiUrl/chat/users/search';
  static const String testEncryptionUrl = '$baseUrl/test-encryption';

  static String getChatMessagesUrl(int roomId) =>
      '$apiUrl/chat/rooms/$roomId/messages';
  static String getSendMessageUrl(int roomId) =>
      '$apiUrl/chat/rooms/$roomId/messages';
}
