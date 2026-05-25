import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController authController = AuthController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _profileImage;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final UserModel user = await authController.getProfile();

      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _bioController.text = user.bio ?? "";
      _locationController.text = user.location ?? "";
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      await authController.updateProfile(
        fullName: _nameController.text,
        bio: _bioController.text,
        location: _locationController.text,
        profileImageUrl: null,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.black45,
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: enabled ? Colors.black : Colors.grey,
            ),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context, false),
          child: Text("Cancel", style: GoogleFonts.inter(color: Colors.black)),
        ),
        title: Text(
          "EDIT PROFILE",
          style: GoogleFonts.syne(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: isSaving ? null : _saveProfile,
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    "Done",
                    style: GoogleFonts.inter(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : null,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: _pickImage,
                    child: Text(
                      "Change Profile Photo",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildEditField("FULL NAME", _nameController),
                  _buildEditField("BIO", _bioController, maxLines: 3),
                  _buildEditField("LOCATION", _locationController),

                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "PRIVATE INFORMATION",
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildEditField("EMAIL", _emailController, enabled: false),
                ],
              ),
            ),
    );
  }
}
