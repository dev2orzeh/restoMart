import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : Get.put(AuthController());
    nameController = TextEditingController(text: authController.userName.value);
    emailController = TextEditingController(text: authController.userEmail.value);
    phoneController = TextEditingController(text: authController.userPhone.value);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    // Simulate API Call
    await Future.delayed(const Duration(seconds: 1));
    
    final authController = Get.find<AuthController>();
    authController.userName.value = nameController.text.trim();
    authController.userEmail.value = emailController.text.trim();
    authController.userPhone.value = phoneController.text.trim();
    
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
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFF0F0FF),
                      child: Text(
                        authController.userName.value.isNotEmpty 
                            ? authController.userName.value.substring(0, 1).toUpperCase() 
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFF25258F),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          'Change Photo',
                          'Profile photo upload requires a backend storage bucket which will be linked soon.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                          colorText: Colors.black,
                        );
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
                hintText: 'Restaurant Name',
                prefixIcon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              
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
}
