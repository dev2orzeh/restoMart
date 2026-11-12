import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController businessNameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  bool isGoogleLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      for (var info in user.providerData) {
        if (info.providerId == 'google.com') return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : Get.put(AuthController());
    nameController = TextEditingController(text: authController.userName.value);
    emailController = TextEditingController(text: authController.userEmail.value);
    phoneController = TextEditingController(text: authController.userPhone.value);
    businessNameController = TextEditingController(text: authController.businessName.value);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    businessNameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    // Simulate API Call
    await Future.delayed(const Duration(seconds: 1));
    
    final authController = Get.find<AuthController>();
    authController.userName.value = nameController.text.trim();
    if (!isGoogleLogin()) {
      authController.userEmail.value = emailController.text.trim();
    }
    authController.userPhone.value = phoneController.text.trim();
    authController.businessName.value = businessNameController.text.trim();
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      await prefs.setString('local_business_name_$uid', businessNameController.text.trim());
      await prefs.setString('cached_user_business_$uid', businessNameController.text.trim());
      await prefs.setString('cached_user_name_$uid', nameController.text.trim());
      await prefs.setString('cached_user_phone_$uid', phoneController.text.trim());
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'businessName': businessNameController.text.trim(),
          'restaurantName': businessNameController.text.trim(),
          'displayName': nameController.text.trim(),
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating Firestore profile: $e');
      }
    }
    
    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(nameController.text.trim());
    } catch (e) {
      // Ignore firebase update errors if user is null or offline
    }
    
    setState(() => isLoading = false);
    
    Get.back();
    Get.snackbar(
      'Profile Updated',
      'Your profile information has been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade800,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Profile Image ─────────────────────────
              Stack(
                children: [
                  Obx(() {
                    final authController = Get.find<AuthController>();
                    final imgProvider = _getProfileImageProvider(authController.profileImagePath.value);
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF0F0FF),
                      backgroundImage: imgProvider,
                      child: imgProvider == null 
                          ? Text(
                              authController.userName.value.isNotEmpty 
                                  ? authController.userName.value.substring(0, 1).toUpperCase() 
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF25258F),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Get.find<AuthController>().pickProfileImage();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // ── Fields ───────────────────────────────
              CustomTextField(
                controller: nameController,
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: businessNameController,
                hintText: 'Business / Restaurant Name (Optional)',
                prefixIcon: Icons.storefront_outlined,
                validator: (value) => null, // Optional
              ),
              const SizedBox(height: 16),
              
              if (!isGoogleLogin()) ...[
                CustomTextField(
                  controller: emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an email';
                    if (!GetUtils.isEmail(value)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              CustomTextField(
                controller: phoneController,
                hintText: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 48),
              
              // ── Save Button ──────────────────────────
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImageProvider(String path) {
    if (path.isEmpty) return null;
    try {
      if (path.startsWith('data:image')) {
        final clean = path.split(',').last;
        return MemoryImage(base64Decode(clean));
      } else if (path.startsWith('http')) {
        return NetworkImage(path);
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    } catch (e) {
      debugPrint('Error parsing profile image provider: $e');
    }
    return null;
  }
}
