import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import '../../data/local/secure_storage/secure_storage.dart';
import '../../data/remote/rest/room_api_service.dart';
import '../../data/remote/rest/models/room_response_model.dart';
import '../auth/login/login_state.dart';
import 'home_page.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState()) {
    _initStreams();
  }

  final secureStorage = GetIt.instance<SecureStorage>();
  final roomApiService = GetIt.instance<RoomApiService>();

  late final Stream<List<StreamerModel>> allRoomsStream;
  late final Stream<List<StreamerModel>> audioRoomsStream;
  late final Stream<List<StreamerModel>> freshersStream;

  // Create BehaviorSubjects to hold and replay the latest value
  final _allRoomsSubject = BehaviorSubject<List<StreamerModel>>();
  final _audioRoomsSubject = BehaviorSubject<List<StreamerModel>>();
  final _freshersSubject = BehaviorSubject<List<StreamerModel>>();

  void _initStreams() {
    print('🔵 [HOME_CUBIT] Initializing streams...');

    allRoomsStream = _allRoomsSubject.stream;
    audioRoomsStream = _audioRoomsSubject.stream;
    freshersStream = _freshersSubject.stream;
  }

  Future<void> refreshData() async {
    print('🔵 [HOME_CUBIT] Fetching data from REST API...');
    final response = await roomApiService.getAllAudioRooms();

    if (response != null && response.status) {
      final rooms = response.data.room;
      print('🔵 [HOME_CUBIT] Received ${rooms.length} rooms');

      // Map to StreamerModel
      final streamerRooms = rooms.map((room) => _mapToStreamerModel(room)).toList();

      // Popular Tab: (Right now just all rooms, as they come from API)
      // If the API doesn't provide diamonds, we'll just show them in the order they come
      // Or we can sort by participantCount
      final popularRooms = List<StreamerModel>.from(streamerRooms);
      popularRooms.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      _allRoomsSubject.add(popularRooms);

      // Party Tab: Only audio rooms (the provided API is for audio rooms)
      _audioRoomsSubject.add(streamerRooms);

      // Freshers Tab: Sorted by createdAt
      // Note: Rest API has createdAt as DateTime
      final apiRoomsWithDate = rooms.map((r) => MapEntry(_mapToStreamerModel(r), r.createdAt)).toList();
      apiRoomsWithDate.sort((a, b) => b.value.compareTo(a.value));
      _freshersSubject.add(apiRoomsWithDate.map((e) => e.key).toList());

    } else {
      print('🔴 [HOME_CUBIT] Error or empty response from API');
      _allRoomsSubject.add([]);
      _audioRoomsSubject.add([]);
      _freshersSubject.add([]);
    }
  }

  StreamerModel _mapToStreamerModel(RoomModel room) {
    return StreamerModel(
      id: room.roomId, // Using roomId for navigation/identification
      name: room.hostName,
      imageUrl: room.hostPicture,
      bio: room.notice,
      viewCount: room.participantCount,
      isVideo: false, // Audio room
      isLocked: room.isLocked,
      isLiveStream: false,
    );
  }

  init() async {
    final user = await secureStorage.getUser();
    emit(state.copyWith(user: user, isLoading: false));
    await refreshData();
  }

  @override
  Future<void> close() {
    _allRoomsSubject.close();
    _audioRoomsSubject.close();
    _freshersSubject.close();
    return super.close();
  }
}
