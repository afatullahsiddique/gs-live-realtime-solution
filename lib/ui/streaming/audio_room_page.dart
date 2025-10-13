// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:zego_uikit/src/services/defines/message.dart';
// import 'package:zego_uikit/src/services/defines/user.dart';
// import 'dart:ui';
//
// class AudioRoomPage extends StatelessWidget {
//   const AudioRoomPage();
//
//   final isHost = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: ZegoUIKitPrebuiltLiveAudioRoom(
//         appID: 1738777063,
//         appSign: "1b5dbd4c4dac51d753a6a4eb7563490006a11a161c5133a4bb2f4727d5e34550",
//         userID: "asdf",
//         userName: "Riad Safowan",
//         roomID: "1234",
//         config: (isHost ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host() : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience())
//           // Background
//           ..background = _buildGradientBackground()
//           // Seat configuration
//           ..seat = (ZegoLiveAudioRoomSeatConfig()
//             ..showSoundWaveInAudioMode = true
//             ..avatarBuilder = _customAvatarBuilder
//             ..foregroundBuilder = _customSeatForegroundBuilder
//             // ..backgroundBuilder = _customSeatBackgroundBuilder
//             ..layout = ZegoLiveAudioRoomLayoutConfig(
//               rowSpacing: 40,
//               rowConfigs: [
//                 ZegoLiveAudioRoomLayoutRowConfig(count: 1, alignment: ZegoLiveAudioRoomLayoutAlignment.center),
//                 ZegoLiveAudioRoomLayoutRowConfig(count: 4, alignment: ZegoLiveAudioRoomLayoutAlignment.spaceAround),
//                 ZegoLiveAudioRoomLayoutRowConfig(count: 4, alignment: ZegoLiveAudioRoomLayoutAlignment.spaceAround),
//                 ZegoLiveAudioRoomLayoutRowConfig(count: 4, alignment: ZegoLiveAudioRoomLayoutAlignment.spaceAround),
//               ],
//             ))
//           // Bottom menu bar
//           ..bottomMenuBar = ZegoLiveAudioRoomBottomMenuBarConfig(
//             hostButtons: [
//               ZegoLiveAudioRoomMenuBarButtonName.toggleMicrophoneButton,
//               ZegoLiveAudioRoomMenuBarButtonName.showMemberListButton,
//             ],
//             audienceButtons: [ZegoLiveAudioRoomMenuBarButtonName.showMemberListButton],
//           )
//           // Top menu bar
//           ..topMenuBar = ZegoLiveAudioRoomTopMenuBarConfig(
//             buttons: [ZegoLiveAudioRoomMenuBarButtonName.minimizingButton],
//           )
//           // In-room messages
//           ..inRoomMessage = ZegoLiveAudioRoomInRoomMessageConfig(itemBuilder: _customMessageBuilder),
//       ),
//     );
//   }
//
//   Widget _buildGradientBackground() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF000000), Color(0xFF1a0a0a), Color(0xFF2d1b2b), Color(0xFF4a2c4a), Color(0xFFff6b9d)],
//           stops: [0.0, 0.3, 0.6, 0.8, 1.0],
//         ),
//       ),
//     );
//   }
//
//   Widget _customAvatarBuilder(BuildContext context, Size size, ZegoUIKitUser? user, Map<String, dynamic> extraInfo) {
//     return Container(
//       width: size.width,
//       height: size.height,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade500, Colors.purple.shade400]),
//         boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(2.0),
//         child: ClipOval(
//           child: true ?? false
//               ? Image.network(
//                   "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400",
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return _defaultAvatar();
//                   },
//                 )
//               : _defaultAvatar(),
//         ),
//       ),
//     );
//   }
//
//   Widget _defaultAvatar() {
//     return Container(
//       decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade700, Colors.grey.shade800])),
//       child: const Icon(Icons.person, color: Colors.white, size: 30),
//     );
//   }
//
//   Widget _customSeatForegroundBuilder(
//     BuildContext context,
//     Size size,
//     ZegoUIKitUser? user,
//     Map<String, dynamic> extraInfo,
//   ) {
//     // if (user == null) {
//     //   return const SizedBox.shrink();
//     // }
//
//     return SizedBox(
//       height: 80,
//       child: Positioned(
//         bottom: 0,
//         left: 0,
//         right: 0,
//         child: Column(
//           children: [
//             Container(
//               child: Text(
//                 "User",
//                 style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _customSeatBackgroundBuilder(
//     BuildContext context,
//     Size size,
//     ZegoUIKitUser? user,
//     Map<String, dynamic> extraInfo,
//   ) {
//     final isEmpty = user == null;
//     final isSpeaking = extraInfo['is_speaking'] as bool? ?? false;
//
//     return Container(
//       width: size.width,
//       height: size.height,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: isEmpty
//             ? LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Colors.black.withOpacity(0.3), Colors.pink.withOpacity(0.1)],
//               )
//             : LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [Colors.pink.shade800.withOpacity(0.3), Colors.purple.shade800.withOpacity(0.3)],
//               ),
//         border: Border.all(
//           color: isEmpty
//               ? Colors.pink.withOpacity(0.2)
//               : isSpeaking
//               ? Colors.green.shade400
//               : Colors.pink.withOpacity(0.4),
//           width: isSpeaking ? 3 : 2,
//         ),
//         boxShadow: [
//           if (isSpeaking)
//             BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10)
//           else if (!isEmpty)
//             BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 8),
//         ],
//       ),
//       child: isEmpty ? Icon(Icons.event_seat, color: Colors.pink.shade300, size: 28) : null,
//     );
//   }
//
//   Widget _customMessageBuilder(BuildContext context, ZegoInRoomMessage message, Map<String, dynamic> data) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '${message.user.name}: ',
//             style: TextStyle(color: Colors.pink.shade300, fontSize: 12, fontWeight: FontWeight.w600),
//           ),
//           Expanded(
//             child: Text(
//               message.message,
//               style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
