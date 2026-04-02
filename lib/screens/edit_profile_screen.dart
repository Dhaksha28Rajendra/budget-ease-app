import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_colors.dart';
import '../data/database/student_dao.dart';
import '../services/session_manager.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _selectedAcademicYear;

  final List<String> _academicYears = [
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  final StudentDAO _dao = StudentDAO();
  bool _saving = false;

  final GlobalKey _photoMenuKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  String? _profileImagePath;

  Future<String> _saveImagePermanently(String pickedPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = p.extension(pickedPath);

    final fileName = "profile_${DateTime.now().millisecondsSinceEpoch}$ext";
    final newPath = p.join(dir.path, fileName);

    final newFile = await File(pickedPath).copy(newPath);
    return newFile.path;
  }

  @override
  void initState() {
    super.initState();
    _loadProfileFromDb();
  }

  Future<void> _loadProfileFromDb() async {
    final email = SessionManager.currentEmail;
    if (email == null || email.trim().isEmpty) return;

    final data = await _dao.getProfileByEmail(email);
    if (!mounted || data == null) return;

    final year = (data['Academic_year'] ?? '').toString().trim();
    final imgPath = (data['Profile_image'] ?? '').toString().trim();

    setState(() {
      _firstNameController.text = (data['First_name'] ?? '').toString();
      _lastNameController.text = (data['Last_name'] ?? '').toString();

      _selectedAcademicYear = _academicYears.contains(year) ? year : null;

      _profileImagePath = imgPath.isNotEmpty ? imgPath : null;

      if (_profileImagePath != null &&
          _profileImagePath!.isNotEmpty &&
          File(_profileImagePath!).existsSync()) {
        _profileImage = File(_profileImagePath!);
      } else {
        _profileImage = null;
      }
    });

    debugPrint("🖼️ EDIT SCREEN image path from DB => $imgPath");
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final email = SessionManager.currentEmail;
    if (email == null || email.trim().isEmpty) {
      _showSnack('Session expired. Please login again.', isError: true);
      return;
    }

    if (_selectedAcademicYear == null ||
        _selectedAcademicYear!.trim().isEmpty) {
      _showSnack('Please select your academic year', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final rows = await _dao.updateProfileByEmail(
        email: email,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        academicYear: _selectedAcademicYear!,
        profileImagePath: _profileImagePath,
      );

      if (!mounted) return;

      if (rows > 0) {
        _showSnack('Profile saved successfully');
        Navigator.pop(context);
      } else {
        _showSnack('Profile update failed', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ================= IMAGE FUNCTIONS =================

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final permanentPath = await _saveImagePermanently(image.path);

      setState(() {
        _profileImagePath = permanentPath;
        _profileImage = File(permanentPath);
      });

      debugPrint("✅ Saved profile image path: $_profileImagePath");
      _showSnack('Photo selected');
    } catch (e) {
      _showSnack('Gallery error: $e', isError: true);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) return;

      final permanentPath = await _saveImagePermanently(image.path);

      setState(() {
        _profileImagePath = permanentPath;
        _profileImage = File(permanentPath);
      });

      debugPrint("✅ Saved profile image path: $_profileImagePath");
      _showSnack('Photo captured');
    } catch (e) {
      _showSnack('Camera error: $e', isError: true);
    }
  }

  Future<void> _deletePhoto() async {
    final email = SessionManager.currentEmail;
    if (email == null || email.trim().isEmpty) return;

    try {
      final oldPath = _profileImagePath;

      // optional: remove file from disk
      if (oldPath != null && oldPath.isNotEmpty) {
        final f = File(oldPath);
        if (await f.exists()) {
          await f.delete();
        }
      }

      await _dao.clearProfileImageByEmail(email);

      if (!mounted) return;

      setState(() {
        _profileImage = null;
        _profileImagePath = null;
      });

      _showSnack('Photo removed');
    } catch (e) {
      _showSnack('Delete error: $e', isError: true);
    }
  }

  // ================= POPUP MENU =================

  Future<void> _showPhotoPopupMenu() async {
    final RenderBox box =
        _photoMenuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx - 170,
      offset.dy + size.height + 10,
      offset.dx,
      offset.dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      items: [
        PopupMenuItem(
          value: 'gallery',
          child: _popupRow(
            icon: Icons.image_outlined,
            text: 'Choose from Library',
            color: AppColors.primaryBlue,
          ),
        ),
        PopupMenuItem(
          value: 'camera',
          child: _popupRow(
            icon: Icons.camera_alt_outlined,
            text: 'Take Photo',
            color: AppColors.primaryBlue,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: _popupRow(
            icon: Icons.delete_outline,
            text: 'Delete',
            color: Colors.red,
          ),
        ),
      ],
    );

    if (selected == null) return;

    if (selected == 'gallery') {
      await _pickFromGallery();
    } else if (selected == 'camera') {
      await _takePhoto();
    } else if (selected == 'delete') {
      await _deletePhoto();
    }
  }

  Widget _popupRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : AppColors.primaryBlue,
      ),
    );
  }

  // ================= iOS GROUPED UI HELPERS =================

  Widget _groupCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.25), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _groupRow({required Widget child, bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: child,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.22),
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }

  InputDecoration _iosInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade700),
      border: InputBorder.none, // ✅ iOS style (no border)
      isDense: true,
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/MainScreens.jpeg',
                  fit: BoxFit.cover,
                ),
              ),

              // slightly stronger overlay for iOS clean readability
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.06)),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _topBar(),
                            const SizedBox(height: 14),

                            // avatar
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.primaryBlue,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : null,
                                  child: _profileImage == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                GestureDetector(
                                  key: _photoMenuKey,
                                  onTap: _showPhotoPopupMenu,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.25),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // ✅ iOS Grouped List (one card with rows)
                            _groupCard(
                              children: [
                                _groupRow(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _iosInputDecoration(
                                      label: 'First Name',
                                      icon: Icons.person_outline,
                                      hint:
                                          null, // you can keep null to remove placeholder
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Please enter your first name'
                                        : null,
                                  ),
                                ),
                                _groupRow(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _iosInputDecoration(
                                      label: 'Last Name',
                                      icon: Icons.person_outline,
                                      hint: null,
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Please enter your last name'
                                        : null,
                                  ),
                                ),
                                _groupRow(
                                  showDivider: false,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedAcademicYear,
                                    dropdownColor: Colors.white,
                                    icon: Icon(
                                      Icons.expand_more,
                                      color: Colors.grey.shade700,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: _iosInputDecoration(
                                      label: 'Academic Year',
                                      icon: Icons.school_outlined,
                                      hint: null,
                                    ),
                                    items: _academicYears
                                        .map(
                                          (year) => DropdownMenuItem(
                                            value: year,
                                            child: Text(year),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (newValue) => setState(
                                      () => _selectedAcademicYear = newValue,
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? 'Please select your academic year'
                                        : null,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  _saving ? 'Saving...' : 'Save Changes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.withOpacity(0.45),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.white.withOpacity(
                                    0.55,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back,
                size: 28,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
