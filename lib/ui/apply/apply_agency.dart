import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';

import '../../data/remote/firebase/profile_services.dart';
import '../../theme/app_theme.dart';

class ApplyAgencyPage extends StatefulWidget {
  const ApplyAgencyPage({super.key});

  @override
  State<ApplyAgencyPage> createState() => _ApplyAgencyPageState();
}

class _ApplyAgencyPageState extends State<ApplyAgencyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isCheckingStatus = true;
  String? _applicationStatus;

  // ## NEW: State for conflicting application ##
  String? _conflictingApplicationError;

  // Controllers
  final _agencyNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _agencyIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _referenceController = TextEditingController();

  // State variables
  String? _selectedCountryName;
  String? _selectedCountryFlagEmoji;
  File? _nidFrontImage;
  File? _nidBackImage;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _holderNameController.dispose();
    _agencyIdController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  // ## MODIFIED: Check for both agency and hosting applications ##
  Future<void> _checkApplicationStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });
    try {
      // 1. Check for its OWN application status first
      final statusDoc = await ProfileService.getAgencyApplicationStatus();
      if (statusDoc.exists) {
        final data = statusDoc.data() as Map<String, dynamic>;
        setState(() {
          _applicationStatus = data['status']; // e.g., 'pending', 'approved'
        });
      } else {
        // 2. If NO own application, check for a CONFLICTING (hosting) application
        final hostingStatusDoc = await ProfileService.getHostingApplicationStatus();
        if (hostingStatusDoc.exists) {
          setState(() {
            _conflictingApplicationError = "You have already applied for hosting. You cannot apply for an agency.";
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking status: $e");
      // Optionally show a generic error
    } finally {
      setState(() {
        _isCheckingStatus = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, Function(File) onImageSelected) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        onImageSelected(File(pickedFile.path));
      });
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    if (_nidFrontImage == null || _nidBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload both NID images.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ProfileService.applyForAgency(
        agencyName: _agencyNameController.text,
        holderName: _holderNameController.text,
        agencyId: _agencyIdController.text,
        email: _emailController.text,
        whatsappNumber: _whatsappController.text,
        location: _selectedCountryName ?? 'N/A',
        locationFlag: _selectedCountryFlagEmoji,
        reference: _referenceController.text,
        nidFrontFile: _nidFrontImage!,
        nidBackFile: _nidBackImage!,
      );

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted successfully!')));
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting application: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // ## MODIFIED: Handle all 3 states (loading, conflict, status, form) ##
              Expanded(
                child: _isCheckingStatus
                    ? Center(child: CircularProgressIndicator(color: AppColors.pink))
                    : _conflictingApplicationError != null
                    ? _buildErrorDisplay(_conflictingApplicationError!)
                    : _applicationStatus != null
                    ? _buildStatusDisplay()
                    : _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 0, right: 20, top: 0, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.back, size: 28, color: AppColors.pink),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'Apply for Agency',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 2))],
            ),
          ),
          Spacer(),
          // Only show submit button if form is visible
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.pink, strokeWidth: 2),
              ),
            )
          else if (_applicationStatus == null && _conflictingApplicationError == null)
            TextButton(
              onPressed: _submitApplication,
              child: Text(
                'Submit',
                style: TextStyle(color: AppColors.pink, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ## NEW: Widget to display the conflicting error ##
  Widget _buildErrorDisplay(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.xmark_octagon_fill, color: Colors.red.shade400, size: 80),
            const SizedBox(height: 20),
            Text(
              'Application Blocked',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _applicationStatus == 'pending' ? CupertinoIcons.clock_fill : CupertinoIcons.check_mark_circled_solid,
            color: _applicationStatus == 'pending' ? Colors.amber : Colors.green,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text('Your application is ${_applicationStatus!}.', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 10),
          Text('Admin will review your submission shortly.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    // ... (This function remains unchanged)
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _agencyNameController,
              label: 'Agency Name',
              icon: CupertinoIcons.building_2_fill,
              validator: (v) => v!.isEmpty ? 'Agency Name is required' : null,
            ),
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _holderNameController,
              label: 'Holder Name',
              icon: CupertinoIcons.person_fill,
              validator: (v) => v!.isEmpty ? 'Holder Name is required' : null,
            ),
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _agencyIdController,
              label: 'Agency ID',
              icon: CupertinoIcons.number,
              validator: (v) => v!.isEmpty ? 'Agency ID is required' : null,
            ),
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _emailController,
              label: 'Email',
              icon: CupertinoIcons.mail_solid,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _whatsappController,
              label: 'WhatsApp Number',
              icon: Icons.message,
              // Using a Material icon
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'WhatsApp number is required' : null,
            ),
            const SizedBox(height: 20),
            _buildCountryPicker(),
            const SizedBox(height: 20),
            _buildGlassyTextField(
              controller: _referenceController,
              label: 'Reference (Optional)',
              icon: CupertinoIcons.group_solid,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImagePicker(
                  label: 'NID Front',
                  imageFile: _nidFrontImage,
                  onTap: () => _pickImage(ImageSource.gallery, (file) => _nidFrontImage = file),
                ),
                _buildImagePicker(
                  label: 'NID Back',
                  imageFile: _nidBackImage,
                  onTap: () => _pickImage(ImageSource.gallery, (file) => _nidBackImage = file),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Reusable Widgets (Unchanged) ---

  Widget _buildGlassyTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    // ... (This function remains unchanged)
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 18),
                child: Icon(icon, color: AppColors.pinkLight, size: 20),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  style: TextStyle(color: Colors.white),
                  minLines: minLines,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(left: 15, right: 20, top: 16, bottom: 16),
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
    // ... (This function remains unchanged)
    String countryText = _selectedCountryName ?? 'Select Location (Country)';
    Widget prefixWidget = _selectedCountryFlagEmoji != null
        ? Text(_selectedCountryFlagEmoji!, style: const TextStyle(fontSize: 26))
        : Icon(CupertinoIcons.location_solid, color: AppColors.pinkLight, size: 20);

    return GestureDetector(
      onTap: () {
        showCountryPicker(
          context: context,
          showPhoneCode: false,
          onSelect: (Country country) {
            setState(() {
              _selectedCountryName = country.name;
              _selectedCountryFlagEmoji = country.flagEmoji;
            });
          },
          countryListTheme: CountryListThemeData(
            backgroundColor: Colors.grey[900],
            textStyle: const TextStyle(color: Colors.white),
            bottomSheetHeight: 500,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
            inputDecoration: InputDecoration(
              labelText: 'Search',
              hintText: 'Start typing to search',
              labelStyle: TextStyle(color: AppColors.pinkLight),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: AppColors.pinkLight),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.pinkLight.withOpacity(0.5))),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.pinkLight.withOpacity(0.5))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.pink)),
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                prefixWidget,
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    countryText,
                    style: TextStyle(
                      color: _selectedCountryName != null ? Colors.white : Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(CupertinoIcons.chevron_down, color: AppColors.pinkLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({required String label, File? imageFile, required VoidCallback onTap}) {
    // ... (This function remains unchanged)
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.pink.withOpacity(0.3), width: 1),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.camera_fill, color: AppColors.pinkLight, size: 40),
                      const SizedBox(height: 8),
                      Text('Tap to upload', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
