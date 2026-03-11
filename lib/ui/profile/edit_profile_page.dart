import 'dart:io';
import 'dart:ui';
import 'package:cute_live/ui/profile/repository/user_repository.dart';
import 'package:cute_live/ui/profile/edit_field_page.dart';
import 'package:cute_live/ui/profile/interest_tags_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:country_picker/country_picker.dart';
import '../../theme/app_theme.dart';
import 'model/user_profile_model.dart';
// FIX 1: Removed duplicate import of 'edit_field_page.dart'

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // FIX 2: _formKey is now actually used inside a Form widget in build()
  final _formKey = GlobalKey<FormState>();
  String? _userId;
  bool _isLoading = false;
  bool _isFetching = true;

  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  // State variables
  String? _selectedGender;
  DateTime? _selectedDob;
  List<String?> _photoUrls = List.filled(6, null);
  List<File?> _photoFiles = List.filled(6, null);
  List<Tag> _myTags = [];
  int _bioCharCount = 0;

  // Country state
  String? _selectedCountryName;
  String? _selectedCountryFlagEmoji;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _bioController.addListener(_updateBioCount);
    _loadCurrentProfile();
  }

  void _updateBioCount() {
    if (_bioController.text.length <= 80) {
      setState(() {
        _bioCharCount = _bioController.text.length;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.removeListener(_updateBioCount);
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isFetching = true);
    try {
      final user = await UserRepository().getUserProfile();
      _nameController.text = user.host?.displayName ?? user.name ?? '';
      _bioController.text = user.host?.bio ?? '';
      _selectedGender = user.gender;
      _selectedCountryName = user.host?.country;
      _selectedCountryFlagEmoji = user.host?.countryFlagEmoji;

      if (user.photoUrls != null) {
        for (int i = 0; i < user.photoUrls!.length && i < 6; i++) {
          _photoUrls[i] = user.photoUrls![i];
        }
      }

      if (user.host?.myTags != null) {
        _myTags = user.host!.myTags!;
      }

      setState(() {
        _bioCharCount = _bioController.text.length;
        _isFetching = false;
      });
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _photoFiles[index] = File(pickedFile.path);
        _isLoading = true;
      });

      try {
        await UserRepository().updateUserProfile(
          photoIndex: index,
          imageFile: _photoFiles[index],
        );

        await _loadCurrentProfileQuietly();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCurrentProfileQuietly() async {
    try {
      final user = await UserRepository().getUserProfile();
      if (user.photoUrls != null) {
        setState(() {
          for (int i = 0; i < 6; i++) {
            _photoUrls[i] = i < user.photoUrls!.length ? user.photoUrls![i] : null;
            _photoFiles[i] = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Quiet load failed: $e");
    }
  }

  Future<void> _saveProfile() async {
    // FIX 3: _formKey.currentState is only called when Form widget exists (see build)
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await UserRepository().updateUserProfile(
        displayName: _nameController.text,
        gender: _selectedGender,
        bio: _bioController.text,
        country: _selectedCountryName,
        location: _selectedCountryName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          children: const [
            Text(
              'Edit data',
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Profile Completeness 60%',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
        // FIX 4: Added Save action button so _saveProfile() is reachable
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CupertinoActivityIndicator(),
          )
              : TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      // FIX 5: Wrapped body in Form so _formKey.currentState!.validate() works
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoWallSection(),
              const SizedBox(height: 12),
              _buildMyProfileSection(),
              const SizedBox(height: 12),
              _buildInterestTagsSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoWallSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo Wall(1/6)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              double totalWidth = constraints.maxWidth;
              double spacing = 4.0;
              double smallItemSize = (totalWidth - (spacing * 2)) / 3;
              double largeItemSize = (smallItemSize * 2) + spacing;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoBox(width: largeItemSize, height: largeItemSize, index: 0, isMain: true),
                      SizedBox(width: spacing),
                      Column(
                        children: [
                          _buildPhotoBox(width: smallItemSize, height: smallItemSize, index: 1),
                          SizedBox(height: spacing),
                          _buildPhotoBox(width: smallItemSize, height: smallItemSize, index: 2),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Row(
                    children: [
                      _buildPhotoBox(width: smallItemSize, height: smallItemSize, index: 3),
                      SizedBox(width: spacing),
                      _buildPhotoBox(width: smallItemSize, height: smallItemSize, index: 4),
                      SizedBox(width: spacing),
                      _buildPhotoBox(width: smallItemSize, height: smallItemSize, index: 5),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox({required double width, required double height, required int index, bool isMain = false}) {
    bool hasImage = (_photoFiles[index] != null) || (_photoUrls[index] != null && _photoUrls[index]!.isNotEmpty);

    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _photoFiles[index] != null
                    ? Image.file(_photoFiles[index]!, width: width, height: height, fit: BoxFit.cover)
                    : Image.network(_photoUrls[index]!, width: width, height: height, fit: BoxFit.cover),
              )
            else
              const Center(child: Icon(CupertinoIcons.add, color: Color(0xFFE0E0E0), size: 30)),
            if (isMain)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProfileSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'My Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          _buildProfileTile(
            label: 'Nickname',
            value: _nameController.text.isEmpty ? 'Tap to set' : _nameController.text,
            onTap: () => _navigateToEditField('Nickname', _nameController.text, (val) => setState(() => _nameController.text = val)),
          ),
          _buildProfileTile(
            label: 'Homepage Link',
            value: 'Go settings',
            showInfo: true,
            onTap: () {},
          ),
          _buildProfileTile(
            label: 'Gender',
            value: _selectedGender ?? 'Tap to set',
            showInfo: true,
            onTap: _showGenderPicker,
          ),
          _buildProfileTile(
            label: 'Date of Birth',
            value: _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : 'Tap to set',
            onTap: _showDobPicker,
          ),
          _buildProfileTile(
            label: 'Country',
            value: _selectedCountryFlagEmoji != null
                ? '$_selectedCountryFlagEmoji  ${_selectedCountryName ?? ''}'
                : _selectedCountryName ?? 'Tap to set',
            showInfo: true,
            onTap: _showCountryPicker,
          ),
          _buildProfileTile(
            label: 'Self-introduction',
            value: _bioController.text.isEmpty ? 'Click to enter' : _bioController.text,
            onTap: () => _navigateToEditField(
              'Self-introduction',
              _bioController.text,
                  (val) => setState(() => _bioController.text = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required String label,
    required String value,
    bool showInfo = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: label + optional info icon — fixed width, won't shrink
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (showInfo) ...[
                      const SizedBox(width: 4),
                      const Icon(CupertinoIcons.info_circle, size: 15, color: Colors.grey),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
                // Right: value text + chevron — fills remaining space, right-aligned
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 15, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(CupertinoIcons.chevron_right, size: 15, color: Color(0xFFBBBBBB)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 0),
      ],
    );
  }

  // FIX 6: _buildInterestTagsSection was missing closing ')' for InkWell
  Widget _buildInterestTagsSection() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterestTagsPage(initialTags: _myTags),
          ),
        );
        if (result == true) {
          _loadCurrentProfileQuietly();
        }
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  'Interest Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Spacer(),
                Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            if (_myTags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _myTags.map((tag) => _buildTag(tag.name)).toList(),
              )
            else
              DashedContainer(
                child: Column(
                  children: const [
                    Icon(CupertinoIcons.add, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Add tags', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Add tags to find people who resonate', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ), // FIX 6: This closing ')' was missing in the original
    );
  }

  Widget _buildTag(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        name,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
    );
  }

  void _navigateToEditField(String title, String initialValue, Function(String) onSave) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditFieldPage(
          title: title,
          initialValue: initialValue,
          reminderText: title == 'Nickname'
              ? 'Reminder: You have one free nickname modification opportunity per month. After exceeding this limit, each modification will require a deduction of 10,000 coins.'
              : null,
          onSave: (val) async {
            onSave(val);
            try {
              await UserRepository().updateUserProfile(
                displayName: title == 'Nickname' ? val : _nameController.text,
                bio: title == 'Self-introduction' ? val : _bioController.text,
                gender: _selectedGender,
                country: _selectedCountryName,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error saving $title: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showGenderPicker() {
    final genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: genders.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(genders[index]),
                trailing: _selectedGender == genders[index]
                    ? const Icon(CupertinoIcons.checkmark, color: Colors.pink)
                    : null,
                onTap: () {
                  setState(() => _selectedGender = genders[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showDobPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDob = pickedDate;
      });
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountryName = country.name;
          _selectedCountryFlagEmoji = country.flagEmoji;
        });
      },
    );
  }
}

class DashedContainer extends StatelessWidget {
  final Widget child;

  const DashedContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedRectPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: child,
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3;
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    RRect rrect = RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(12));
    Path path = Path()..addRRect(rrect);

    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}