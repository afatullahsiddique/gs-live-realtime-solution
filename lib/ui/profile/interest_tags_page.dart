import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cute_live/ui/profile/model/user_profile_model.dart';
import 'repository/user_repository.dart';

class InterestTagsPage extends StatefulWidget {
  final List<Tag> initialTags;

  const InterestTagsPage({super.key, required this.initialTags});

  @override
  State<InterestTagsPage> createState() => _InterestTagsPageState();
}

class _InterestTagsPageState extends State<InterestTagsPage> {
  Map<String, List<Tag>> _categories = {};
  List<Tag> _allTags = [];
  bool _isFetching = true;
  bool _isLoading = false;
  late Set<String> _selectedTagIds;
  // Tracks the tag IDs that are already saved on the server
  Set<String> _serverTagIds = {};

  final Map<String, bool> _isMultiSelect = {
    'Occupation': false,
    'Constellation': false,
    'Hobby': true,
    'Exercise': true,
    'Pet': true,
  };

  // FIX 2: Extracted a reusable empty Tag as a static final (non-const)
  // so it can be safely used in orElse callbacks without the const error.
  static final Tag _emptyTag = Tag(id: '', name: '', category: '');

  @override
  void initState() {
    super.initState();
    // Seed with any initialTags passed in; will be updated once API responds
    _selectedTagIds = widget.initialTags.map((t) => t.id).toSet();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    try {
      // Fetch all available tags AND the user's saved tags in parallel
      final results = await Future.wait([
        UserRepository().getAllTags(),
        UserRepository().getMyTags(),
      ]);

      final List<Tag> allTags = results[0];
      final List<Tag> myTags = results[1];

      final Map<String, List<Tag>> grouped = {};
      for (var tag in allTags) {
        final category = tag.category ?? 'Other';
        if (!grouped.containsKey(category)) {
          grouped[category] = [];
        }
        grouped[category]!.add(tag);
      }

      final serverIds = myTags.map((t) => t.id).toSet();
      setState(() {
        _allTags = allTags;
        _categories = grouped;
        // Override selection with the freshly fetched server-side tags
        _selectedTagIds = Set.from(serverIds);
        _serverTagIds = Set.from(serverIds);
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tags: $e')),
        );
      }
    }
  }

  void _toggleTag(String category, Tag tag) {
    setState(() {
      if (_isMultiSelect[category] ?? true) {
        if (_selectedTagIds.contains(tag.id)) {
          _selectedTagIds.remove(tag.id);
        } else {
          int countInCategory = _selectedTagIds.where((id) {
            // FIX 2: Use static _emptyTag instead of Tag(...) in orElse
            final t = _allTags.firstWhere(
                  (element) => element.id == id,
              orElse: () => _emptyTag,
            );
            return t.category == category;
          }).length;

          if (countInCategory < 3) {
            _selectedTagIds.add(tag.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You can select up to 3 tags in this category')),
            );
          }
        }
      } else {
        // Single select
        if (_selectedTagIds.contains(tag.id)) {
          _selectedTagIds.remove(tag.id);
        } else {
          _selectedTagIds.removeWhere((id) {
            // FIX 2: Use static _emptyTag instead of Tag(...) in orElse
            final t = _allTags.firstWhere(
                  (element) => element.id == id,
              orElse: () => _emptyTag,
            );
            return t.category == category;
          });
          _selectedTagIds.add(tag.id);
        }
      }
    });
  }

  Future<void> _saveTags() async {
    setState(() => _isLoading = true);
    try {
      final repo = UserRepository();

      // Tags the user removed (were on server, now deselected)
      final toDelete = _serverTagIds.difference(_selectedTagIds);
      // Tags the user added (selected now, not yet on server)
      final toAdd = _selectedTagIds.difference(_serverTagIds);

      // 1. Delete removed tags one by one
      for (final tagId in toDelete) {
        await repo.deleteMyTag(tagId);
      }

      // 2. Save only the newly-added tags (skip already-saved ones)
      if (toAdd.isNotEmpty) {
        await repo.saveMyTags(toAdd.toList());
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save tags: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.left_chevron, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Interest Tags',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F0FF), Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: _isFetching
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 100),
              child: Column(
                children: _categories.keys
                    .map((category) => _buildCategorySection(category))
                    .toList(),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTags,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final tagsInCategory = _categories[category]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _getIconForCategory(category),
            const SizedBox(width: 8),
            Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isMultiSelect[category] ?? true ? 'select up to 3' : 'Single choice',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tagsInCategory.map((tag) {
            bool isSelected = _selectedTagIds.contains(tag.id);
            return GestureDetector(
              onTap: () => _toggleTag(category, tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _getIconForCategory(String category) {
    switch (category) {
      case 'Occupation':
        return const Icon(CupertinoIcons.person_solid, color: Colors.blue, size: 24);
      case 'Constellation':
        return const Icon(CupertinoIcons.star_fill, color: Colors.purple, size: 24);
      case 'Hobby':
        return const Icon(CupertinoIcons.gamecontroller_fill, color: Colors.green, size: 24);
      case 'Exercise':
        return const Icon(CupertinoIcons.sportscourt_fill, color: Colors.blueAccent, size: 24);
      case 'Pet':
      // FIX 3: CupertinoIcons.paw_fill does not exist in Flutter's CupertinoIcons.
      // Replaced with Material Icons.pets which is the correct paw/pet icon.
        return const Icon(Icons.pets, color: Colors.orange, size: 24);
      default:
        return const Icon(CupertinoIcons.tag_fill, color: Colors.grey);
    }
  }
}