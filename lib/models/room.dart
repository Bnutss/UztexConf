class Room {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final bool isOwner;

  Room({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.isOwner,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }
}

class RoomToken {
  final String token;
  final String livekitUrl;
  final String roomName;
  final String roomId;
  final String username;

  RoomToken({
    required this.token,
    required this.livekitUrl,
    required this.roomName,
    required this.roomId,
    required this.username,
  });

  factory RoomToken.fromJson(Map<String, dynamic> json) {
    return RoomToken(
      token: json['token'] as String,
      livekitUrl: json['livekit_url'] as String,
      roomName: json['room_name'] as String,
      roomId: json['room_id'] as String,
      username: json['username'] as String,
    );
  }
}
