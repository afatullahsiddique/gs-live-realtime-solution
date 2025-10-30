import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../data/remote/firebase/live_streaming_services.dart';
import '../../data/remote/firebase/room_services.dart';
import '../../data/remote/firebase/video_room_services.dart';
import '../auth/login/login_state.dart';
import 'home_page.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState()) {
    _initStreams();
  }
  final secureStorage = GetIt.instance<SecureStorage>();

  late final Stream<List<StreamerModel>> allRoomsStream;

  void _initStreams() {
    // Get the individual streams
    final audioRoomsStream = RoomService.getAllRooms();
    final videoRoomsStream = VideoRoomService.getAllRooms();
    final liveStreamsStream = LiveStreamService.getAllRooms();

    // Assign the combined stream to the public property
    allRoomsStream = CombineLatestStream.combine3(
      audioRoomsStream,
      videoRoomsStream,
      liveStreamsStream,
          (
          QuerySnapshot audioSnapshot,
          QuerySnapshot videoSnapshot,
          QuerySnapshot liveStreamSnapshot,
          ) {
        final List<StreamerModel> liveRooms = [];

        // Process audio rooms
        for (var doc in audioSnapshot.docs) {
          var roomData = doc.data() as Map<String, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: doc.id,
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: false,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: false,
            ),
          );
        }

        // Process video rooms
        for (var doc in videoSnapshot.docs) {
          var roomData = doc.data() as Map<String, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: doc.id,
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: true,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: false,
            ),
          );
        }

        // Process new live streams
        for (var doc in liveStreamSnapshot.docs) {
          var roomData = doc.data() as Map<String, dynamic>;
          liveRooms.add(
            StreamerModel(
              id: doc.id,
              name: roomData['hostName'] ?? 'Unknown Host',
              imageUrl: roomData['hostPicture'],
              bio: '',
              viewCount: roomData['participantCount'] ?? 0,
              isVideo: true,
              isLocked: roomData['isLocked'] ?? false,
              isLiveStream: true,
            ),
          );
        }
        liveRooms.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        return liveRooms;
      },
    ).shareReplay(maxSize: 1);
  }

  init() async {
    // This function can now be called 'fetchUser' or similar
    // but we'll keep it as 'init' to match the BlocProvider
    final user = await secureStorage.getUser();
    emit(state.copyWith(user: user, isLoading: false));
  }
}