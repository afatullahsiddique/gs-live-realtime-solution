// lib/ui/host_page/host_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:cute_live/data/remote/rest/models/room_response_model.dart';
import 'package:cute_live/data/remote/rest/room_api_service.dart';

import '../../navigation/routes.dart';

// Which bottom tab is active
enum _HostTab { live, party }

// Video / Voice selection
enum _StreamMode { video, voice }

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  static const String _defaultSkinUrl =
      'https://res.cloudinary.com/dmcaktttv/image/upload/v1771180768/lpyqdzey0pfqoth5m6w7.jpg';

  _HostTab _activeTab = _HostTab.party;
  _StreamMode _streamMode = _StreamMode.voice;

  // Selected box count (number of party seats)
  int _selectedBoxCount = 4;

  bool _isLoading = false;
  final _roomApiService = GetIt.instance<RoomApiService>();
  List<Skin> _skins = [];
  Skin? _selectedSkin;

  // Box-count options: count → gridColumns
  static const List<int> _boxOptions = [4, 6, 9, 12, 16, 25];
  // Counts that support video. 16 & 25 are audio-only.
  static const Set<int> _videoCapable = {4, 6, 9, 12};

  final List<String> _categories = [
    'Chatting',
    'Singing',
    'Dancing',
    'Making friends',
    'Talent show',
  ];
  int _selectedCategoryIndex = 1; // "Singing" selected by default as in screenshot

  @override
  void initState() {
    super.initState();
    _fetchSkins();
  }

  Future<void> _fetchSkins() async {
    final response = await _roomApiService.getSkins();
    if (response != null && response.status && mounted) {
      setState(() {
        _skins = response.data.skins;
        if (_skins.isNotEmpty) _selectedSkin = _skins.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0D28), Color(0xFF1E1440), Color(0xFF2A1A50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildProfileArea(),
              const Spacer(),
              _buildBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────── TOP BAR
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────── PROFILE AREA
  Widget _buildProfileArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '১৩১০/– রিচার্জ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_outlined,
                        color: Colors.white70, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCategoryTags(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: _selectedSkin != null
                  ? NetworkImage(_selectedSkin!.url)
                  : const NetworkImage(_defaultSkinUrl),
              backgroundColor: Colors.grey[800],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Change',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTags() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────────────────── BOTTOM PANEL
  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabRow(),
          const SizedBox(height: 16),
          if (_activeTab == _HostTab.party) ...[
            _buildVideoVoiceToggle(),
            const SizedBox(height: 20),
            _buildBoxGrid(),
            const SizedBox(height: 24),
            _buildHoldPartyRow(),
          ] else ...[
            _buildLiveTabPlaceholder(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTab('Live', _HostTab.live),
        const SizedBox(width: 40),
        _buildTab('Party', _HostTab.party),
      ],
    );
  }

  Widget _buildTab(String label, _HostTab tab) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: 28,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────── VIDEO / VOICE TOGGLE
  Widget _buildVideoVoiceToggle() {
    final bool videoDisabled = !_videoCapable.contains(_selectedBoxCount);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeChip(
          label: 'Video',
          mode: _StreamMode.video,
          disabled: videoDisabled,
        ),
        const SizedBox(width: 8),
        _buildModeChip(
          label: 'Voice',
          mode: _StreamMode.voice,
          disabled: false,
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required _StreamMode mode,
    required bool disabled,
  }) {
    final isSelected = _streamMode == mode && !disabled;
    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(() => _streamMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B5BEB)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B5BEB)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: disabled
                ? Colors.white30
                : (isSelected ? Colors.white : Colors.white70),
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────── BOX GRID
  Widget _buildBoxGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _boxOptions.map((count) {
        final isSelected = _selectedBoxCount == count;
        final isNew = count == 25;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBoxCount = count;
              // If video is selected but new count doesn't support video, switch to voice
              if (!_videoCapable.contains(count) &&
                  _streamMode == _StreamMode.video) {
                _streamMode = _StreamMode.voice;
              }
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6B5BEB)
                      : Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF9B8FFF)
                        : Colors.white12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMiniGrid(count),
                    const SizedBox(height: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNew)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniGrid(int count) {
    // Determine columns for a visually correct mini-grid
    int cols;
    if (count <= 4) cols = 2;
    else if (count <= 6) cols = 3;
    else if (count <= 9) cols = 3;
    else if (count <= 12) cols = 4;
    else if (count <= 16) cols = 4;
    else cols = 5;

    final int rows = (count / cols).ceil();
    final int cells = rows * cols;

    return Wrap(
      spacing: 1.5,
      runSpacing: 1.5,
      children: List.generate(cells, (i) {
        final bool visible = i < count;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: visible
                ? Colors.white.withOpacity(0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  // ────────────────────────────────── HOLD PARTY ROW
  Widget _buildHoldPartyRow() {
    return Row(
      children: [
        Expanded(
          child: _isLoading
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B5BEB),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _holdParty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5BEB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                    shadowColor:
                        const Color(0xFF6B5BEB).withOpacity(0.6),
                  ),
                  child: const Text(
                    'Hold a party',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(Icons.more_horiz,
                color: Colors.white70, size: 22),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────── LIVE TAB PLACEHOLDER
  Widget _buildLiveTabPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () {
              context.push(Routes.liveApplication.path);
            },
            icon: const Icon(Icons.fiber_manual_record, size: 18),
            label: const Text(
              'Start Live Now',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5BEB),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 4,
              shadowColor:
                  const Color(0xFF6B5BEB).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────── ACTIONS
  Future<void> _holdParty() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      String backgroundUrl = _selectedSkin?.url ?? _defaultSkinUrl;

      final bool isLargeRoom = _selectedBoxCount == 16 || _selectedBoxCount == 25;
      if (isLargeRoom) {
        backgroundUrl =
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROmZRDYBM04vLZ49k2MzmQJSWlp3bhUg5ckQ&s';
      }

      final createResponse = await _roomApiService.createRoom(
        backgroundUrl,
        seats: isLargeRoom ? _selectedBoxCount : null,
      );

      if (createResponse != null && createResponse.status) {
        if (!mounted) return;
        final room = createResponse.data;
        context.pushReplacement(Routes.partyRoom.path, extra: {
          'roomId': room.roomId,
          'isHost': true,
          'slotCount': room.maxSeats > 0 ? room.maxSeats : _selectedBoxCount,
          'mode': _streamMode == _StreamMode.video ? 'video' : 'voice',
          'zegoConfig': room.zegoConfig,
        });
      } else {
        throw Exception(
            createResponse?.message ?? 'Failed to create party room.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() => _isLoading = false);
    }
  }
}
