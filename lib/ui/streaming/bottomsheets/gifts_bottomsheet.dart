import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../data/remote/firebase/assets_services.dart';
import '../../../../data/remote/firebase/profile_services.dart';
import '../../../core/widgets/gift_image_widget.dart';
import '../../../data/remote/firebase/room_services.dart';

class ParticipantSelector {
  final String userId;
  final String userName;
  final String? userPicture;
  bool isSelected;

  ParticipantSelector({required this.userId, required this.userName, this.userPicture, this.isSelected = false});
}

class GiftBottomSheet extends StatefulWidget {
  final String roomId;
  final List<dynamic> participants;
  final String hostId;

  const GiftBottomSheet({Key? key, required this.roomId, required this.participants, required this.hostId})
    : super(key: key);

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  GiftModel? _selectedGift;
  List<ParticipantSelector> _participantSelectors = [];
  int _currentBalance = 0;
  bool _isSending = false;

  // NEW: Cache categories and gifts to prevent reloading
  List<String>? _cachedCategories;
  Map<String, List<GiftModel>> _cachedGiftsByCategory = {};

  @override
  void initState() {
    super.initState();
    _initializeParticipants();
    _loadBalance();
    _loadCategories();
  }

  void _initializeParticipants() {
    _participantSelectors = widget.participants.map((p) {
      return ParticipantSelector(
        userId: p.userId,
        userName: p.userName,
        userPicture: p.userPicture,
        isSelected: p.userId == widget.hostId,
      );
    }).toList();

    _participantSelectors.sort((a, b) {
      if (a.userId == widget.hostId) return -1;
      if (b.userId == widget.hostId) return 1;
      return 0;
    });
  }

  Future<void> _loadBalance() async {
    final balance = await ProfileService.getCurrentUserBalance();
    if (mounted) {
      setState(() {
        _currentBalance = balance;
      });
    }
  }

  // NEW: Load categories once
  Future<void> _loadCategories() async {
    final categories = await AssetsService.getGiftCategories();
    if (mounted) {
      setState(() {
        _cachedCategories = categories;
      });
    }
  }

  int get _totalCost {
    if (_selectedGift == null) return 0;
    final selectedCount = _participantSelectors.where((p) => p.isSelected).length;
    return _selectedGift!.value * selectedCount;
  }

  bool get _canSend {
    return _selectedGift != null && _participantSelectors.any((p) => p.isSelected) && _currentBalance >= _totalCost;
  }

  Future<void> _sendGift() async {
    if (!_canSend || _selectedGift == null) return;

    setState(() {
      _isSending = true;
    });

    try {

        final selectedRecipients = _participantSelectors.where((p) => p.isSelected).map((p) => p.userId).toList();

        await ProfileService.sendGift(giftValue: _selectedGift!.value, recipientIds: selectedRecipients);

        await RoomService.sendGift(
          roomId: widget.roomId,
          giftAnimationUrl: _selectedGift!.iconUrl,
          giftImageUrl: _selectedGift!.imageUrl,
          giftValue: _selectedGift!.value,
          category: _selectedGift!.category,
        );

        if (!mounted) return;
        Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height * 0.5;

    return SafeArea(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Color(0xFF2d1b2b),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 16),

                const Text(
                  'Send Gift',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Padding(padding: const EdgeInsets.only(right: 16), child: _buildBalanceDisplay()),
              ],
            ),
            const SizedBox(height: 10),

            // Gift Categories and List - OPTIMIZED
            Expanded(
              child: _cachedCategories == null
                  ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                  : DefaultTabController(
                      length: _cachedCategories!.length,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            indicatorColor: Colors.pink,
                            labelColor: Colors.pink,
                            unselectedLabelColor: Colors.white70,
                            tabs: _cachedCategories!.map((cat) => Tab(text: cat)).toList(),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: _cachedCategories!.map((category) {
                                return _GiftGridView(
                                  category: category,
                                  selectedGiftId: _selectedGift?.id,
                                  cachedGifts: _cachedGiftsByCategory[category],
                                  onGiftSelected: (gift) {
                                    setState(() {
                                      _selectedGift = gift;
                                    });
                                  },
                                  onGiftsCached: (gifts) {
                                    _cachedGiftsByCategory[category] = gifts;
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Participants Selection Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Send to:',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (_selectedGift != null)
                        Text(
                          'Total: $_totalCost diamonds',
                          style: TextStyle(
                            color: _canSend ? Colors.amber : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _participantSelectors.length,
                            itemBuilder: (context, index) {
                              final participant = _participantSelectors[index];
                              return _buildParticipantItem(participant);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (_canSend && !_isSending) ? _sendGift : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          disabledBackgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Send',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return StreamBuilder<int>(
      stream: ProfileService.getCurrentUserBalanceStream(),
      initialData: _currentBalance,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != _currentBalance) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _currentBalance = snapshot.data!;
            }
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/beans.svg", color: Colors.amber, width: 16),
              const SizedBox(width: 4),
              Text(
                _currentBalance.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticipantItem(ParticipantSelector participant) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            participant.isSelected = !participant.isSelected;
          });
        },
        child: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: participant.isSelected ? Colors.pink : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: participant.userPicture != null && participant.userPicture!.isNotEmpty
                    ? Image.network(
                        participant.userPicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 24),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            if (participant.isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// NEW: Separate StatefulWidget for gift grid to prevent rebuilds
class _GiftGridView extends StatefulWidget {
  final String category;
  final String? selectedGiftId;
  final List<GiftModel>? cachedGifts;
  final Function(GiftModel) onGiftSelected;
  final Function(List<GiftModel>) onGiftsCached;

  const _GiftGridView({
    Key? key,
    required this.category,
    required this.selectedGiftId,
    required this.cachedGifts,
    required this.onGiftSelected,
    required this.onGiftsCached,
  }) : super(key: key);

  @override
  State<_GiftGridView> createState() => _GiftGridViewState();
}

class _GiftGridViewState extends State<_GiftGridView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use cached data if available
    if (widget.cachedGifts != null) {
      return _buildGrid(widget.cachedGifts!);
    }

    return StreamBuilder<List<GiftModel>>(
      stream: AssetsService.getGiftsByCategory(widget.category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.pink));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
          );
        }

        final gifts = snapshot.data ?? [];

        if (gifts.isEmpty) {
          return const Center(
            child: Text('No gifts found.', style: TextStyle(color: Colors.white70)),
          );
        }

        // Cache the gifts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onGiftsCached(gifts);
        });

        return _buildGrid(gifts);
      },
    );
  }

  Widget _buildGrid(List<GiftModel> gifts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final isSelected = widget.selectedGiftId == gift.id;

        return GestureDetector(
          onTap: () => widget.onGiftSelected(gift),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                    child: GiftImageWidget(
                      imageUrl: gift.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: CircularProgressIndicator(color: Colors.pink.withOpacity(0.5), strokeWidth: 1.5),
                      ),
                      errorWidget: const Icon(Icons.card_giftcard, color: Colors.white54, size: 24),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond_outlined, color: Colors.cyan, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        gift.value.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showGiftBottomSheet(
  BuildContext context, {
  required String roomId,
  required List<dynamic> participants,
  required String hostId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GiftBottomSheet(roomId: roomId, participants: participants, hostId: hostId),
  );
}
