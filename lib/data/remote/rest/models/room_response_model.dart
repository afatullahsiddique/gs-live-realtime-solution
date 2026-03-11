class RoomResponse {
  final bool status;
  final int statusCode;
  final String message;
  final RoomData data;

  RoomResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory RoomResponse.fromJson(Map<String, dynamic> json) {
    return RoomResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: RoomData.fromJson(json['data'] ?? {}),
    );
  }
}

class RoomData {
  final List<RoomModel> room;

  RoomData({required this.room});

  factory RoomData.fromJson(Map<String, dynamic> json) {
    return RoomData(
      room: (json['room'] as List? ?? []).map((i) => RoomModel.fromJson(i)).toList(),
    );
  }
}

// Single Room Response
class SingleRoomResponse {
  final bool status;
  final int statusCode;
  final String message;
  final SingleRoomData data;

  SingleRoomResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory SingleRoomResponse.fromJson(Map<String, dynamic> json) {
    return SingleRoomResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: SingleRoomData.fromJson(json['data'] ?? {}),
    );
  }
}

class SingleRoomData {
  final RoomModel room;

  SingleRoomData({required this.room});

  factory SingleRoomData.fromJson(Map<String, dynamic> json) {
    return SingleRoomData(
      room: RoomModel.fromJson(json),
    );
  }
}

class RoomModel {
  final String id;
  final String roomId;
  final String hostId;
  final String hostDisplayId;
  final String hostName;
  final String? hostPicture;
  final String hostCountry;
  final String hostCountryFlagEmoji;
  final String? password;
  final String? backgroundUrl;
  final bool isActive;
  final int participantCount;
  final int maxParticipants;
  final int maxSeats;
  final bool isMoveAllowed;
  final bool isSeatApprovalRequired;
  final bool isLocked;
  final String notice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? backgroundUpdatedAt;
  final DateTime? endedAt;
  final HostInfo host;
  final List<ParticipantInJoin> participants;
  final List<Seat> seats;

  RoomModel({
    required this.id,
    required this.roomId,
    required this.hostId,
    required this.hostDisplayId,
    required this.hostName,
    this.hostPicture,
    required this.hostCountry,
    required this.hostCountryFlagEmoji,
    this.password,
    this.backgroundUrl,
    required this.isActive,
    required this.participantCount,
    required this.maxParticipants,
    required this.maxSeats,
    required this.isMoveAllowed,
    required this.isSeatApprovalRequired,
    required this.isLocked,
    required this.notice,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundUpdatedAt,
    this.endedAt,
    required this.host,
    required this.participants,
    required this.seats,
    this.zegoConfig,
  });

  final ZegoConfig? zegoConfig;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      hostId: json['hostId'] ?? '',
      hostDisplayId: json['hostDisplayId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostPicture: json['hostPicture'],
      hostCountry: json['hostCountry'] ?? '',
      hostCountryFlagEmoji: json['hostCountryFlagEmoji'] ?? '',
      password: json['password'],
      backgroundUrl: json['backgroundUrl'],
      isActive: json['isActive'] ?? false,
      participantCount: json['participantCount'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 0,
      maxSeats: json['maxSeats'] ?? 0,
      isMoveAllowed: json['isMoveAllowed'] ?? true,
      isSeatApprovalRequired: json['isSeatApprovalRequired'] ?? false,
      isLocked: json['isLocked'] ?? false,
      notice: json['notice'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      backgroundUpdatedAt: json['backgroundUpdatedAt'] != null ? DateTime.parse(json['backgroundUpdatedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      host: HostInfo.fromJson(json['host'] ?? {}),
      participants: (json['participants'] as List? ?? []).map((i) => ParticipantInJoin.fromJson(i)).toList(),
      seats: (json['seats'] as List? ?? []).map((i) => Seat.fromJson(i)).toList(),
      zegoConfig: json['zegoConfig'] != null ? ZegoConfig.fromJson(json['zegoConfig']) : null,
    );
  }
}

class HostInfo {
  final String id;
  final String name;
  final String? photoUrl;
  final String displayId;

  HostInfo({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.displayId,
  });

  factory HostInfo.fromJson(Map<String, dynamic> json) {
    String? photo;
    if (json['photoUrl'] is List) {
      final list = json['photoUrl'] as List;
      if (list.isNotEmpty) {
        photo = list[0].toString();
      }
    } else if (json['photoUrl'] is String) {
      photo = json['photoUrl'];
    }

    return HostInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: photo,
      displayId: json['displayId'] ?? '',
    );
  }
}

class ParticipantInfo {
  final String id;
  final String displayId;
  final String roomId;
  final String? userPicture;

  ParticipantInfo({
    required this.id,
    required this.displayId,
    required this.roomId,
    this.userPicture,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      id: json['id'] ?? '',
      displayId: json['displayId'] ?? '',
      roomId: json['roomId'] ?? '',
      userPicture: json['userPicture'],
    );
  }
}

// Join Room Response Models
class JoinRoomResponse {
  final bool status;
  final int statusCode;
  final String message;
  final JoinRoomData data;

  JoinRoomResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) {
    return JoinRoomResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: JoinRoomData.fromJson(json['data'] ?? {}),
    );
  }
}

class JoinRoomData {
  final String message;
  final JoinRoomInfo room;
  final CurrentParticipant currentParticipant;
  final List<ParticipantInJoin> participants;
  final List<Seat> seats;
  final ZegoConfig zegoConfig;

  JoinRoomData({
    required this.message,
    required this.room,
    required this.currentParticipant,
    required this.participants,
    required this.seats,
    required this.zegoConfig,
  });

  factory JoinRoomData.fromJson(Map<String, dynamic> json) {
    // Check if fields are flattened (like in SingleRoomResponse) or nested
    final bool isFlattened = json.containsKey('roomId') && !json.containsKey('room');
    
    return JoinRoomData(
      message: json['message'] ?? '',
      room: JoinRoomInfo.fromJson(isFlattened ? json : (json['room'] ?? {})),
      currentParticipant: CurrentParticipant.fromJson(json['currentParticipant'] ?? {}),
      participants: (json['participants'] as List? ?? [])
          .map((i) => ParticipantInJoin.fromJson(i))
          .toList(),
      seats: (json['seats'] as List? ?? []).map((i) => Seat.fromJson(i)).toList(),
      zegoConfig: ZegoConfig.fromJson(json['zegoConfig'] ?? {}),
    );
  }
}

class JoinRoomInfo {
  final String roomId;
  final String hostId;
  final String hostDisplayId;
  final String hostName;
  final String hostPicture;
  final String hostCountry;
  final DateTime createdAt;
  final bool isActive;
  final int participantCount;
  final bool isMoveAllowed;
  final bool isSeatApprovalRequired;
  final bool isLocked;
  final String backgroundUrl;
  final String notice;
  final DateTime backgroundUpdatedAt;
  final int maxSeats;

  JoinRoomInfo({
    required this.roomId,
    required this.hostId,
    required this.hostDisplayId,
    required this.hostName,
    required this.hostPicture,
    required this.hostCountry,
    required this.createdAt,
    required this.isActive,
    required this.participantCount,
    required this.isMoveAllowed,
    required this.isSeatApprovalRequired,
    required this.isLocked,
    required this.backgroundUrl,
    required this.notice,
    required this.backgroundUpdatedAt,
    required this.maxSeats,
  });

  factory JoinRoomInfo.fromJson(Map<String, dynamic> json) {
    return JoinRoomInfo(
      roomId: json['roomId'] ?? '',
      hostId: json['hostId'] ?? '',
      hostDisplayId: json['hostDisplayId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostPicture: json['hostPicture'] ?? '',
      hostCountry: json['hostCountry'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      participantCount: json['participantCount'] ?? 0,
      isMoveAllowed: json['isMoveAllowed'] ?? true,
      isSeatApprovalRequired: json['isSeatApprovalRequired'] ?? false,
      isLocked: json['isLocked'] ?? false,
      backgroundUrl: json['backgroundUrl'] ?? '',
      notice: json['notice'] ?? '',
      backgroundUpdatedAt: DateTime.parse(json['backgroundUpdatedAt'] ?? DateTime.now().toIso8601String()),
      maxSeats: json['maxSeats'] ?? 9,
    );
  }
}

class CurrentParticipant {
  final String userId;
  final String displayId;
  final String userName;
  final String? userPicture;
  final bool isCoHost;
  final int seatNo;
  final DateTime joinedAt;
  final bool isOnline;
  final bool isMuted;

  CurrentParticipant({
    required this.userId,
    required this.displayId,
    required this.userName,
    this.userPicture,
    required this.isCoHost,
    required this.seatNo,
    required this.joinedAt,
    required this.isOnline,
    required this.isMuted,
  });

  factory CurrentParticipant.fromJson(Map<String, dynamic> json) {
    return CurrentParticipant(
      userId: json['userId'] ?? '',
      displayId: json['displayId'] ?? '',
      userName: json['userName'] ?? '',
      userPicture: json['userPicture'],
      isCoHost: json['isCoHost'] ?? false,
      seatNo: json['seatNo'] ?? -1,
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isOnline: json['isOnline'] ?? false,
      isMuted: json['isMuted'] ?? false,
    );
  }
}

class ParticipantInJoin {
  final String userId;
  final String displayId;
  final String userName;
  final String? userPicture;
  final bool isCoHost;
  final int seatNo;
  final DateTime joinedAt;
  final bool isOnline;
  final bool isMuted;

  ParticipantInJoin({
    required this.userId,
    required this.displayId,
    required this.userName,
    this.userPicture,
    required this.isCoHost,
    required this.seatNo,
    required this.joinedAt,
    required this.isOnline,
    required this.isMuted,
  });

  factory ParticipantInJoin.fromJson(Map<String, dynamic> json) {
    return ParticipantInJoin(
      userId: json['userId'] ?? '',
      displayId: json['displayId'] ?? '',
      userName: json['userName'] ?? '',
      userPicture: json['userPicture'],
      isCoHost: json['isCoHost'] ?? false,
      seatNo: json['seatNo'] ?? -1,
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      isOnline: json['isOnline'] ?? false,
      isMuted: json['isMuted'] ?? false,
    );
  }
}

class Seat {
  final String id;
  final int seatNo;
  final bool isSpecial;
  final bool isOccupied;
  final bool isMuted;
  final String? occupiedBy;
  final HostInfo? user;

  Seat({
    required this.id,
    required this.seatNo,
    required this.isSpecial,
    required this.isOccupied,
    required this.isMuted,
    this.occupiedBy,
    this.user,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] ?? '',
      seatNo: json['seatNo'] ?? 0,
      isSpecial: json['isSpecial'] ?? false,
      isOccupied: json['isOccupied'] ?? false,
      isMuted: json['isMuted'] ?? false,
      occupiedBy: json['occupiedBy'],
      user: json['user'] != null ? HostInfo.fromJson(json['user']) : null,
    );
  }
}

class ZegoConfig {
  final dynamic appId;
  final String? roomId;
  final String? token;
  final String? userId;
  final String? userName;
  final String? signId;

  ZegoConfig({
    required this.appId,
    this.roomId,
    this.token,
    this.userId,
    this.userName,
    this.signId,
  });

  factory ZegoConfig.fromJson(Map<String, dynamic> json) {
    return ZegoConfig(
      appId: json['appId'] ?? 0,
      roomId: json['roomId'],
      token: json['token'],
      userId: json['userId'],
      userName: json['userName'],
      signId: json['signId'],
    );
  }
}

class TakeSeatResponse {
  final bool status;
  final int? statusCode;
  final String message;
  final TakeSeatData? data;

  TakeSeatResponse({
    required this.status,
    this.statusCode,
    required this.message,
    this.data,
  });

  factory TakeSeatResponse.fromJson(Map<String, dynamic> json) {
    return TakeSeatResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'],
      message: json['message'] ?? '',
      data: json['data'] != null ? TakeSeatData.fromJson(json['data']) : null,
    );
  }
}

class TakeSeatData {
  final String message;
  final int seatNo;
  final bool isMuted;

  TakeSeatData({
    required this.message,
    required this.seatNo,
    required this.isMuted,
  });

  factory TakeSeatData.fromJson(Map<String, dynamic> json) {
    return TakeSeatData(
      message: json['message'] ?? '',
      seatNo: json['seatNo'] ?? -1,
      isMuted: json['isMuted'] ?? false,
    );
  }
}

// Room Skins Models
class SkinsResponse {
  final bool status;
  final int statusCode;
  final String message;
  final SkinsData data;

  SkinsResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory SkinsResponse.fromJson(Map<String, dynamic> json) {
    return SkinsResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: SkinsData.fromJson(json['data'] ?? {}),
    );
  }
}

class SkinsData {
  final int total;
  final List<Skin> skins;

  SkinsData({required this.total, required this.skins});

  factory SkinsData.fromJson(Map<String, dynamic> json) {
    return SkinsData(
      total: json['total'] ?? 0,
      skins: (json['skins'] as List? ?? []).map((i) => Skin.fromJson(i)).toList(),
    );
  }
}

class MoveSeatResponse {
  final bool status;
  final int statusCode;
  final String message;
  final MoveSeatData? data;

  MoveSeatResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory MoveSeatResponse.fromJson(Map<String, dynamic> json) {
    return MoveSeatResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? MoveSeatData.fromJson(json['data']) : null,
    );
  }
}

class MoveSeatData {
  final String message;
  final int newSeatNo;
  final bool isCoHost;

  MoveSeatData({
    required this.message,
    required this.newSeatNo,
    required this.isCoHost,
  });

  factory MoveSeatData.fromJson(Map<String, dynamic> json) {
    return MoveSeatData(
      message: json['message'] ?? '',
      newSeatNo: json['newSeatNo'] ?? -1,
      isCoHost: json['isCoHost'] ?? false,
    );
  }
}

class Skin {
  final String id;
  final String name;
  final String url;
  final String category;
  final int price;
  final DateTime createdAt;

  Skin({
    required this.id,
    required this.name,
    required this.url,
    required this.category,
    required this.price,
    required this.createdAt,
  });

  factory Skin.fromJson(Map<String, dynamic> json) {
    return Skin(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Create Room Response
class CreateRoomResponse {
  final bool status;
  final int statusCode;
  final String message;
  final CreateRoomData data;

  CreateRoomResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    return CreateRoomResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: CreateRoomData.fromJson(json['data'] ?? {}),
    );
  }
}

class CreateRoomData {
  final String roomId;
  final String hostId;
  final String hostDisplayId;
  final String hostName;
  final String? hostPicture;
  final String hostCountry;
  final DateTime createdAt;
  final bool isActive;
  final int participantCount;
  final int maxSeats;
  final bool isMoveAllowed;
  final bool isSeatApprovalRequired;
  final bool isLocked;
  final String backgroundUrl;
  final ZegoConfig? zegoConfig;

  CreateRoomData({
    required this.roomId,
    required this.hostId,
    required this.hostDisplayId,
    required this.hostName,
    this.hostPicture,
    required this.hostCountry,
    required this.createdAt,
    required this.isActive,
    required this.participantCount,
    required this.maxSeats,
    required this.isMoveAllowed,
    required this.isSeatApprovalRequired,
    required this.isLocked,
    required this.backgroundUrl,
    this.zegoConfig,
  });

  factory CreateRoomData.fromJson(Map<String, dynamic> json) {
    return CreateRoomData(
      roomId: json['roomId'] ?? '',
      hostId: json['hostId'] ?? '',
      hostDisplayId: json['hostDisplayId'] ?? '',
      hostName: json['hostName'] ?? '',
      hostPicture: json['hostPicture'],
      hostCountry: json['hostCountry'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? false,
      participantCount: json['participantCount'] ?? 0,
      maxSeats: json['maxSeats'] ?? 9,
      isMoveAllowed: json['isMoveAllowed'] ?? true,
      isSeatApprovalRequired: json['isSeatApprovalRequired'] ?? false,
      isLocked: json['isLocked'] ?? false,
      backgroundUrl: json['backgroundUrl'] ?? '',
      zegoConfig: json['zegoConfig'] != null ? ZegoConfig.fromJson(json['zegoConfig']) : null,
    );
  }
}

// Co-host Response Models
class CohostRequestResponse {
  final bool status;
  final int statusCode;
  final String message;
  final CohostRequestData data;

  CohostRequestResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory CohostRequestResponse.fromJson(Map<String, dynamic> json) {
    return CohostRequestResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: CohostRequestData.fromJson(json['data'] ?? {}),
    );
  }
}

class CohostRequestData {
  final String requestId;
  final String userId;
  final String userName;
  final String? userPicture;
  final DateTime requestedAt;

  CohostRequestData({
    required this.requestId,
    required this.userId,
    required this.userName,
    this.userPicture,
    required this.requestedAt,
  });

  factory CohostRequestData.fromJson(Map<String, dynamic> json) {
    return CohostRequestData(
      requestId: json['requestId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPicture: json['userPicture'],
      requestedAt: DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CohostRequestsListResponse {
  final bool status;
  final int statusCode;
  final String message;
  final CohostRequestsListData data;

  CohostRequestsListResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory CohostRequestsListResponse.fromJson(Map<String, dynamic> json) {
    return CohostRequestsListResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: CohostRequestsListData.fromJson(json['data'] ?? {}),
    );
  }
}

class CohostRequestsListData {
  final int total;
  final List<CohostRequestData> requests;

  CohostRequestsListData({
    required this.total,
    required this.requests,
  });

  factory CohostRequestsListData.fromJson(Map<String, dynamic> json) {
    return CohostRequestsListData(
      total: json['total'] ?? 0,
      requests: (json['requests'] as List? ?? []).map((i) => CohostRequestData.fromJson(i)).toList(),
    );
  }
}

class ApproveCohostResponse {
  final bool status;
  final int statusCode;
  final String message;
  final ApproveCohostData data;

  ApproveCohostResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory ApproveCohostResponse.fromJson(Map<String, dynamic> json) {
    return ApproveCohostResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: ApproveCohostData.fromJson(json['data'] ?? {}),
    );
  }
}

class ApproveCohostData {
  final String message;
  final String userId;
  final int seatNo;
  final bool isCoHost;

  ApproveCohostData({
    required this.message,
    required this.userId,
    required this.seatNo,
    required this.isCoHost,
  });

  factory ApproveCohostData.fromJson(Map<String, dynamic> json) {
    return ApproveCohostData(
      message: json['message'] ?? '',
      userId: json['userId'] ?? '',
      seatNo: json['seatNo'] ?? -1,
      isCoHost: json['isCoHost'] ?? false,
    );
  }
}

class MuteResponse {
  final bool status;
  final int statusCode;
  final String message;
  final MuteData data;

  MuteResponse({
    required this.status,
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory MuteResponse.fromJson(Map<String, dynamic> json) {
    return MuteResponse(
      status: json['status'] ?? false,
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: MuteData.fromJson(json['data'] ?? {}),
    );
  }
}

class MuteData {
  final bool isMuted;

  MuteData({required this.isMuted});

  factory MuteData.fromJson(Map<String, dynamic> json) {
    return MuteData(
      isMuted: json['isMuted'] ?? false,
    );
  }
}
