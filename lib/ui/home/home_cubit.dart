import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
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
  HomeCubit() : super(const HomeState()) {
    _initStreams();
  }

  final secureStorage = GetIt.instance<SecureStorage>();
  final _firestore = FirebaseFirestore.instance;

  late final Stream<List<StreamerModel>> allRoomsStream;
  late final Stream<List<StreamerModel>> audioRoomsStream;
  late final Stream<List<StreamerModel>> freshersStream;

  // Create BehaviorSubjects to hold and replay the latest value
  final _allRoomsSubject = BehaviorSubject<List<StreamerModel>>();
  final _audioRoomsSubject = BehaviorSubject<List<StreamerModel>>();
  final _freshersSubject = BehaviorSubject<List<StreamerModel>>();

  void _initStreams() {
    print('🔵 [HOME_CUBIT] Initializing streams...');

    // Get the individual streams and make them broadcast so they can be listened to multiple times
    final audioRoomsStreamRaw = RoomService.getAllRooms().asBroadcastStream();
    final videoRoomsStreamRaw = VideoRoomService.getAllRooms().asBroadcastStream();
    final liveStreamsStreamRaw = LiveStreamService.getAllRooms().asBroadcastStream();

    // Popular Tab: All rooms sorted by host diamonds
    Rx.combineLatest3(
      audioRoomsStreamRaw,
      videoRoomsStreamRaw,
      liveStreamsStreamRaw,
          (DatabaseEvent audioEvent, DatabaseEvent videoEvent, DatabaseEvent liveEvent) async {
        print('🔵 [POPULAR TAB] Processing rooms...');
        return await _processRoomsWithDiamonds(audioEvent, videoEvent, liveEvent);
      },
    ).asyncExpand((future) async* {
      yield await future;
    }).listen((rooms) {
      print('🔵 [POPULAR TAB] Emitting ${rooms.length} rooms to subject');
      _allRoomsSubject.add(rooms);
    });

    // Expose the stream from BehaviorSubject
    allRoomsStream = _allRoomsSubject.stream;

    // Party Tab: Only audio rooms sorted by host diamonds
    audioRoomsStreamRaw.asyncExpand((audioEvent) async* {
      print('🟢 [PARTY TAB] Processing audio rooms...');
      yield await _processAudioRooms(audioEvent);
    }).listen((rooms) {
      print('🟢 [PARTY TAB] Emitting ${rooms.length} rooms to subject');
      _audioRoomsSubject.add(rooms);
    });

    // Expose the stream from BehaviorSubject
    audioRoomsStream = _audioRoomsSubject.stream;

    // Freshers Tab: All active rooms sorted by HOST's createdAt (newest hosts first)
    Rx.combineLatest3(
      audioRoomsStreamRaw,
      videoRoomsStreamRaw,
      liveStreamsStreamRaw,
          (DatabaseEvent audioEvent, DatabaseEvent videoEvent, DatabaseEvent liveEvent) async {
        print('🟡 [FRESHERS TAB] Processing rooms with host creation timestamps...');
        return await _processRoomsWithHostCreationDate(audioEvent, videoEvent, liveEvent);
      },
    ).asyncExpand((future) async* {
      yield await future;
    }).listen((rooms) {
      print('🟡 [FRESHERS TAB] Emitting ${rooms.length} rooms to subject');
      _freshersSubject.add(rooms);
    });

    // Expose the stream from BehaviorSubject
    freshersStream = _freshersSubject.stream;

    print('🔵 [HOME_CUBIT] Streams initialized successfully');
  }

  // Process rooms with diamonds for Popular Tab
  Future<List<StreamerModel>> _processRoomsWithDiamonds(
      DatabaseEvent audioEvent,
      DatabaseEvent videoEvent,
      DatabaseEvent liveEvent,
      ) async {
    print('🔵 [POPULAR] Starting to process rooms...');
    final List<_RoomWithDiamonds> roomsWithDiamonds = [];

    // 1. Process Audio Rooms
    if (audioEvent.snapshot.exists && audioEvent.snapshot.value != null) {
      final data = audioEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🔵 [POPULAR] Found ${data.length} audio rooms');
      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Fetch host diamonds from Firestore
          int hostDiamonds = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              hostDiamonds = userDoc.data()?['diamonds'] ?? 0;
            }
          } catch (e) {
            print('🔴 [POPULAR] Error fetching diamonds for host $hostId: $e');
          }

          roomsWithDiamonds.add(
            _RoomWithDiamonds(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: false,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: false,
              ),
              diamonds: hostDiamonds,
            ),
          );
        } catch (e) {
          print('🔴 [POPULAR] Error processing audio room: $e');
        }
      }
    } else {
      print('🔵 [POPULAR] No audio rooms found');
    }

    // 2. Process Video Rooms
    if (videoEvent.snapshot.exists && videoEvent.snapshot.value != null) {
      final data = videoEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🔵 [POPULAR] Found ${data.length} video rooms');
      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Fetch host diamonds from Firestore
          int hostDiamonds = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              hostDiamonds = userDoc.data()?['diamonds'] ?? 0;
            }
          } catch (e) {
            print('🔴 [POPULAR] Error fetching diamonds for host $hostId: $e');
          }

          roomsWithDiamonds.add(
            _RoomWithDiamonds(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: true,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: false,
              ),
              diamonds: hostDiamonds,
            ),
          );
        } catch (e) {
          print('🔴 [POPULAR] Error processing video room: $e');
        }
      }
    } else {
      print('🔵 [POPULAR] No video rooms found');
    }

    // 3. Process Live Streams
    if (liveEvent.snapshot.exists && liveEvent.snapshot.value != null) {
      final data = liveEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🔵 [POPULAR] Found ${data.length} live streams');
      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Fetch host diamonds from Firestore
          int hostDiamonds = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              hostDiamonds = userDoc.data()?['diamonds'] ?? 0;
            }
          } catch (e) {
            print('🔴 [POPULAR] Error fetching diamonds for host $hostId: $e');
          }

          roomsWithDiamonds.add(
            _RoomWithDiamonds(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: true,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: true,
              ),
              diamonds: hostDiamonds,
            ),
          );
        } catch (e) {
          print('🔴 [POPULAR] Error processing live stream: $e');
        }
      }
    } else {
      print('🔵 [POPULAR] No live streams found');
    }

    // SORTING: Sort by host diamonds descending (Highest first)
    roomsWithDiamonds.sort((a, b) => b.diamonds.compareTo(a.diamonds));
    print('🔵 [POPULAR] Processed ${roomsWithDiamonds.length} total rooms, sorted by diamonds');

    // Extract just the StreamerModel list
    return roomsWithDiamonds.map((e) => e.streamer).toList();
  }

  // Process only audio rooms for Party Tab
  Future<List<StreamerModel>> _processAudioRooms(DatabaseEvent audioEvent) async {
    print('🟢 [PARTY TAB] Starting to process audio rooms...');
    print('🟢 [PARTY TAB] Audio event exists: ${audioEvent.snapshot.exists}');
    print('🟢 [PARTY TAB] Audio event value is null: ${audioEvent.snapshot.value == null}');

    final List<_RoomWithDiamonds> roomsWithDiamonds = [];

    if (audioEvent.snapshot.exists && audioEvent.snapshot.value != null) {
      final data = audioEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🟢 [PARTY TAB] Found ${data.length} audio rooms in database');
      print('🟢 [PARTY TAB] Audio rooms keys: ${data.keys.toList()}');

      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];
          final hostName = roomData['hostName'] ?? 'Unknown Host';

          print('🟢 [PARTY TAB] Processing room: ${entry.key}, host: $hostName, hostId: $hostId');

          // Fetch host diamonds from Firestore
          int hostDiamonds = 0;
          try {
            print('🟢 [PARTY TAB] Fetching diamonds for host $hostId...');
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              hostDiamonds = userDoc.data()?['diamonds'] ?? 0;
              print('🟢 [PARTY TAB] Host $hostId has $hostDiamonds diamonds');
            } else {
              print('🟡 [PARTY TAB] User document not found for host $hostId');
            }
          } catch (e) {
            print('🔴 [PARTY TAB] Error fetching diamonds for host $hostId: $e');
          }

          final streamer = StreamerModel(
            id: entry.key.toString(),
            name: hostName,
            imageUrl: roomData['hostPicture'],
            bio: '',
            viewCount: roomData['participantCount'] ?? 0,
            isVideo: false,
            isLocked: roomData['isLocked'] ?? false,
            isLiveStream: false,
          );

          roomsWithDiamonds.add(
            _RoomWithDiamonds(
              streamer: streamer,
              diamonds: hostDiamonds,
            ),
          );

          print('🟢 [PARTY TAB] Added room ${entry.key} to list');
        } catch (e) {
          print('🔴 [PARTY TAB] Error processing audio room: $e');
        }
      }
    } else {
      print('🟡 [PARTY TAB] No audio rooms snapshot or snapshot is null');
    }

    // Sort by diamonds descending
    roomsWithDiamonds.sort((a, b) => b.diamonds.compareTo(a.diamonds));
    print('🟢 [PARTY TAB] Returning ${roomsWithDiamonds.length} audio rooms sorted by diamonds');

    // Extract just the StreamerModel list
    final result = roomsWithDiamonds.map((e) => e.streamer).toList();
    print('🟢 [PARTY TAB] Final result count: ${result.length}');
    return result;
  }

  // Process rooms with HOST's createdAt for Freshers Tab
  Future<List<StreamerModel>> _processRoomsWithHostCreationDate(
      DatabaseEvent audioEvent,
      DatabaseEvent videoEvent,
      DatabaseEvent liveEvent,
      ) async {
    print('🟡 [FRESHERS TAB] Starting to process rooms with host creation dates...');
    final List<_RoomWithTimestamp> roomsWithTimestamp = [];

    // Process Audio Rooms
    if (audioEvent.snapshot.exists && audioEvent.snapshot.value != null) {
      final data = audioEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🟡 [FRESHERS TAB] Found ${data.length} audio rooms');

      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Get host's createdAt from Firestore
          int hostCreatedAtTimestamp = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              // Try to get createdAt timestamp
              final userData = userDoc.data();
              if (userData?['createdAt'] != null) {
                // Handle both Timestamp and int types
                final createdAtData = userData!['createdAt'];
                if (createdAtData is Timestamp) {
                  hostCreatedAtTimestamp = createdAtData.millisecondsSinceEpoch;
                } else if (createdAtData is int) {
                  hostCreatedAtTimestamp = createdAtData;
                }
                print('🟡 [FRESHERS TAB] Host $hostId createdAt: $hostCreatedAtTimestamp');
              } else {
                // Fallback to current time if createdAt doesn't exist
                hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
                print('🟡 [FRESHERS TAB] Host $hostId has NO createdAt, using current time');
              }
            }
          } catch (e) {
            print('🔴 [FRESHERS TAB] Error fetching host createdAt for $hostId: $e');
            hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
          }

          roomsWithTimestamp.add(
            _RoomWithTimestamp(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: false,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: false,
              ),
              timestamp: hostCreatedAtTimestamp,
            ),
          );
        } catch (e) {
          print('🔴 [FRESHERS TAB] Error processing audio room for freshers: $e');
        }
      }
    } else {
      print('🟡 [FRESHERS TAB] No audio rooms found');
    }

    // Process Video Rooms
    if (videoEvent.snapshot.exists && videoEvent.snapshot.value != null) {
      final data = videoEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🟡 [FRESHERS TAB] Found ${data.length} video rooms');

      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Get host's createdAt from Firestore
          int hostCreatedAtTimestamp = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData?['createdAt'] != null) {
                final createdAtData = userData!['createdAt'];
                if (createdAtData is Timestamp) {
                  hostCreatedAtTimestamp = createdAtData.millisecondsSinceEpoch;
                } else if (createdAtData is int) {
                  hostCreatedAtTimestamp = createdAtData;
                }
                print('🟡 [FRESHERS TAB] Video room host $hostId createdAt: $hostCreatedAtTimestamp');
              } else {
                hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
                print('🟡 [FRESHERS TAB] Video room host $hostId has NO createdAt, using current time');
              }
            }
          } catch (e) {
            print('🔴 [FRESHERS TAB] Error fetching host createdAt for $hostId: $e');
            hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
          }

          roomsWithTimestamp.add(
            _RoomWithTimestamp(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: true,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: false,
              ),
              timestamp: hostCreatedAtTimestamp,
            ),
          );
        } catch (e) {
          print('🔴 [FRESHERS TAB] Error processing video room for freshers: $e');
        }
      }
    } else {
      print('🟡 [FRESHERS TAB] No video rooms found');
    }

    // Process Live Streams
    if (liveEvent.snapshot.exists && liveEvent.snapshot.value != null) {
      final data = liveEvent.snapshot.value as Map<dynamic, dynamic>;
      print('🟡 [FRESHERS TAB] Found ${data.length} live streams');

      for (var entry in data.entries) {
        try {
          final roomData = entry.value as Map<dynamic, dynamic>;
          final hostId = roomData['hostId'];

          // Get host's createdAt from Firestore
          int hostCreatedAtTimestamp = 0;
          try {
            final userDoc = await _firestore.collection('users').doc(hostId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              if (userData?['createdAt'] != null) {
                final createdAtData = userData!['createdAt'];
                if (createdAtData is Timestamp) {
                  hostCreatedAtTimestamp = createdAtData.millisecondsSinceEpoch;
                } else if (createdAtData is int) {
                  hostCreatedAtTimestamp = createdAtData;
                }
                print('🟡 [FRESHERS TAB] Live stream host $hostId createdAt: $hostCreatedAtTimestamp');
              } else {
                hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
                print('🟡 [FRESHERS TAB] Live stream host $hostId has NO createdAt, using current time');
              }
            }
          } catch (e) {
            print('🔴 [FRESHERS TAB] Error fetching host createdAt for $hostId: $e');
            hostCreatedAtTimestamp = DateTime.now().millisecondsSinceEpoch;
          }

          roomsWithTimestamp.add(
            _RoomWithTimestamp(
              streamer: StreamerModel(
                id: entry.key.toString(),
                name: roomData['hostName'] ?? 'Unknown Host',
                imageUrl: roomData['hostPicture'],
                bio: '',
                viewCount: roomData['participantCount'] ?? 0,
                isVideo: true,
                isLocked: roomData['isLocked'] ?? false,
                isLiveStream: true,
              ),
              timestamp: hostCreatedAtTimestamp,
            ),
          );
        } catch (e) {
          print('🔴 [FRESHERS TAB] Error processing live stream for freshers: $e');
        }
      }
    } else {
      print('🟡 [FRESHERS TAB] No live streams found');
    }

    // SORTING: Sort by host createdAt descending (Newest hosts first)
    roomsWithTimestamp.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print('🟡 [FRESHERS TAB] Processed ${roomsWithTimestamp.length} total rooms, sorted by host creation date');

    // Extract just the StreamerModel list
    final result = roomsWithTimestamp.map((e) => e.streamer).toList();
    print('🟡 [FRESHERS TAB] Returning ${result.length} rooms');
    return result;
  }

  init() async {
    final user = await secureStorage.getUser();
    emit(state.copyWith(user: user, isLoading: false));
  }

  @override
  Future<void> close() {
    _allRoomsSubject.close();
    _audioRoomsSubject.close();
    _freshersSubject.close();
    return super.close();
  }
}

// Helper class to hold room data with diamonds for sorting
class _RoomWithDiamonds {
  final StreamerModel streamer;
  final int diamonds;

  _RoomWithDiamonds({required this.streamer, required this.diamonds});
}

// Helper class to hold room data with timestamp for sorting
class _RoomWithTimestamp {
  final StreamerModel streamer;
  final int timestamp;

  _RoomWithTimestamp({required this.streamer, required this.timestamp});
}
