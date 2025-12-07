import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart'; // Changed from cloud_firestore
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../data/remote/firebase/live_streaming_services.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../data/remote/firebase/video_room_services.dart';
import '../auth/login/login_state.dart';
import 'home_page.dart'; // Imports StreamerModel

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    _initStreams();
  }

  final secureStorage = GetIt.instance<SecureStorage>();

  late final Stream<List<StreamerModel>> allRoomsStream;

  void _initStreams() {
    // Get the individual streams (Returns Stream<DatabaseEvent>)
    final audioRoomsStream = RoomService.getAllRooms();
    final videoRoomsStream = VideoRoomService.getAllRooms();
    final liveStreamsStream = LiveStreamService.getAllRooms();

    // Assign the combined stream to the public property
    allRoomsStream = CombineLatestStream.combine3(audioRoomsStream, videoRoomsStream, liveStreamsStream, (
        DatabaseEvent audioEvent,
        DatabaseEvent videoEvent,
        DatabaseEvent liveEvent,
        ) {
      final List<StreamerModel> liveRooms = [];

      // 1. Process Audio Rooms
      if (audioEvent.snapshot.exists && audioEvent.snapshot.value != null) {
        // RTDB returns a Map<dynamic, dynamic> where keys are IDs
        final data = audioEvent.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final roomData = value as Map<dynamic, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: key,
              // The key is the roomId
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: false,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: false,
            ),
          );
        });
      }

      // 2. Process Video Rooms
      if (videoEvent.snapshot.exists && videoEvent.snapshot.value != null) {
        final data = videoEvent.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final roomData = value as Map<dynamic, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: key,
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: true,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: false,
            ),
          );
        });
      }

      // 3. Process Live Streams
      if (liveEvent.snapshot.exists && liveEvent.snapshot.value != null) {
        final data = liveEvent.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final roomData = value as Map<dynamic, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: key,
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: true,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: true,
            ),
          );
        });
      }

      // SORTING: Sort by viewCount descending (Highest first)
      liveRooms.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      return liveRooms;
    }).shareReplay(maxSize: 1);
  }

  init() async {
    final user = await secureStorage.getUser();
    emit(state.copyWith(user: user, isLoading: false));
  }
}
