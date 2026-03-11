import 'package:dio/dio.dart';
import 'api_client.dart';
import 'models/room_response_model.dart';

class RoomApiService {
  final ApiClient _apiClient;

  RoomApiService(this._apiClient);

  Future<RoomResponse?> getAllAudioRooms() async {
    try {
      print('🚀 [ROOM_API_SERVICE] Fetching audio rooms from /room/audio/all...');
      final response = await _apiClient.dio.get("/room/audio/all");
      print('✅ [ROOM_API_SERVICE] Successfully fetched rooms. Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return RoomResponse.fromJson(response.data);
      } else {
        print('⚠️ [ROOM_API_SERVICE] Failed to fetch rooms with status code: ${response.statusCode}. Response data: ${response.data}');
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Failed to fetch rooms: $e');
    }
    return null;
  }

  Future<SingleRoomResponse?> getRoomInfo(String roomId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Fetching room info for $roomId...');
      final response = await _apiClient.dio.get("/room/audio/$roomId");
      print('✅ [ROOM_API_SERVICE] Fetch room info status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return SingleRoomResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error fetching room info: $e');
    }
    return null;
  }

  Future<JoinRoomResponse?> joinRoom(String roomId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Joining room $roomId...');
      final response = await _apiClient.dio.post("/room/audio/$roomId/join");
      print('✅ [ROOM_API_SERVICE] Join response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return JoinRoomResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error joining room: $e');
    }
    return null;
  }

  Future<TakeSeatResponse?> takeSeat(String roomId, int seatNo) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Taking seat $seatNo in room $roomId...');
      final response = await _apiClient.dio.post(
        "/room/audio/$roomId/seats/$seatNo/take",
      );
      print('✅ [ROOM_API_SERVICE] Take seat response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return TakeSeatResponse.fromJson(response.data);
      }
    } catch (e) {
      if (e is DioException) {
        // ← ADD THIS to see the actual error message from backend
        print('❌ [ROOM_API_SERVICE] Error taking seat: ${e.response?.statusCode} — ${e.response?.data}');
      } else {
        print('❌ [ROOM_API_SERVICE] Error taking seat: $e');
      }
    }
    return null;
  }

  Future<MoveSeatResponse?> moveSeat(String roomId, int newSeatNo) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Moving to seat $newSeatNo in room $roomId...');
      final response = await _apiClient.dio.put(
        "/room/audio/$roomId/seats/move",
        data: {"newSeatNo": newSeatNo},
      );
      print('✅ [ROOM_API_SERVICE] Move seat response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return MoveSeatResponse.fromJson(response.data);
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ [ROOM_API_SERVICE] Error moving seat: ${e.response?.statusCode} — ${e.response?.data}');
      } else {
        print('❌ [ROOM_API_SERVICE] Error moving seat: $e');
      }
    }
    return null;
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Leaving room $roomId...');
      await _apiClient.dio.post("/room/audio/$roomId/leave");
      print('✅ [ROOM_API_SERVICE] Left room successfully');
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error leaving room: $e');
    }
  }

  Future<SkinsResponse?> getSkins() async {
    try {
      print('🚀 [ROOM_API_SERVICE] Fetching room skins...');
      final response = await _apiClient.dio.get("/room/skins");
      print('✅ [ROOM_API_SERVICE] Skins response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return SkinsResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error fetching skins: $e');
    }
    return null;
  }

  Future<CreateRoomResponse?> createRoom(String backgroundUrl, {int? seats}) async {
    try {
      final Map<String, dynamic> data = {"backgroundUrl": backgroundUrl};
      if (seats != null) {
        data["seats"] = seats;
      }

      print('🚀 [ROOM_API_SERVICE] Creating audio room with data: $data');
      final response = await _apiClient.dio.post(
        "/room/audio",
        data: data,
      );
      print('✅ [ROOM_API_SERVICE] Create room response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateRoomResponse.fromJson(response.data);
      }
    } catch (e) {
      if (e is DioException) {
        print('❌ [ROOM_API_SERVICE] Error creating room: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('❌ [ROOM_API_SERVICE] Error creating room: $e');
      }
    }
    return null;
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Deleting audio room $roomId...');
      final response = await _apiClient.dio.delete("/room/audio/$roomId");
      print('✅ [ROOM_API_SERVICE] Delete room response status: ${response.statusCode}');
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error deleting room: $e');
    }
  }

  Future<CohostRequestResponse?> requestCohost(String roomId, {bool isMuted = true}) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Requesting co-host in room $roomId...');
      final response = await _apiClient.dio.post(
        "/room/audio/$roomId/cohost/request",
        data: {"isMuted": isMuted},
      );
      print('✅ [ROOM_API_SERVICE] Co-host request response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CohostRequestResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error requesting co-host: $e');
    }
    return null;
  }

  Future<CohostRequestsListResponse?> getCohostRequests(String roomId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Fetching co-host requests for room $roomId...');
      final response = await _apiClient.dio.get("/room/audio/$roomId/cohost/requests");
      print('✅ [ROOM_API_SERVICE] Co-host requests response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return CohostRequestsListResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error fetching co-host requests: $e');
    }
    return null;
  }

  Future<ApproveCohostResponse?> approveCohost(String roomId, String requestId, String userId) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Approving co-host request $requestId for user $userId in room $roomId...');
      final response = await _apiClient.dio.post(
        "/room/audio/$roomId/cohost/approve",
        data: {
          "requestId": requestId,
          "userId": userId,
        },
      );
      print('✅ [ROOM_API_SERVICE] Approve co-host response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return ApproveCohostResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error approving co-host: $e');
    }
    return null;
  }

  Future<MuteResponse?> updateMuteState(String roomId, bool isMuted) async {
    try {
      print('🚀 [ROOM_API_SERVICE] Updating mute state to $isMuted in room $roomId...');
      final response = await _apiClient.dio.put(
        "/room/audio/$roomId/mute",
        data: {"isMuted": isMuted},
      );
      print('✅ [ROOM_API_SERVICE] Mute state response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return MuteResponse.fromJson(response.data);
      }
    } catch (e) {
      print('❌ [ROOM_API_SERVICE] Error updating mute state: $e');
    }
    return null;
  }
}
