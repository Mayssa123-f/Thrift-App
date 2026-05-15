import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Mayssa Faraj");
  final TextEditingController _bioController = TextEditingController(text: "Curating the best vintage finds in Lebanon.");
  final TextEditingController _locationController = TextEditingController(text: "Zahle, Lebanon");

  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: GoogleFonts.inter(color: Colors.black)),
        ),
        title: Text(
          "EDIT PROFILE",
          style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text("Done", style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 👤 PROFILE PHOTO EDIT
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
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _pickImage,
              child: Text("Change Profile Photo", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)),
            ),

            const SizedBox(height: 40),

            // 📝 INPUT FIELDS
            _buildEditField("FULL NAME", _nameController),
            _buildEditField("BIO", _bioController, maxLines: 3),
            _buildEditField("LOCATION", _locationController),

            const SizedBox(height: 30),

            // 🔒 PRIVATE INFO SECTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "PRIVATE INFORMATION",
                style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black45),
              ),
            ),
            const SizedBox(height: 15),
            _buildEditField("EMAIL", TextEditingController(text: "mayssa@example.com"), enabled: false),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black45),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: enabled ? Colors.black : Colors.grey),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    // Implement your update logic here (API call to Laravel/Firebase)
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }
}