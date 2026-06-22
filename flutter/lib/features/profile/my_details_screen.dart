import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../config/app_colors.dart';
import '../../core/api/api_client.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/widgets/widgets.dart';
import '../authentication/bloc/auth_bloc.dart';
import '../authentication/bloc/auth_event.dart';
import '../authentication/bloc/auth_state.dart';
import '../authentication/data/models/user_model.dart';

class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key, required this.user});

  final User user;

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked =
          await picker.pickImage(source: source, imageQuality: 80);
      if (!mounted) return;
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (_) {
      // Permission denied, no camera available, plugin error, etc.
      // Surface an error toast instead of letting the exception crash.
      if (!mounted) return;
      AppToast.show(
        context,
        'Could not access the image. Please check the app permissions.',
        type: AppToastType.error,
      );
    }
  }

  Future<String?> _uploadImageToS3(String filePath) => uploadImageToS3(
        apiClient: context.read<ApiClient>(),
        iiaApiKey: ApiConfig.iiaApiKey,
        filePath: filePath,
      );

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    String? uploadedUrl;

    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      try {
        uploadedUrl = await _uploadImageToS3(_selectedImage!.path);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        AppToast.show(
          context,
          'Image upload failed: $e',
          type: AppToastType.error,
        );
        return;
      }
      if (mounted) setState(() => _isUploading = false);
    }

    if (!mounted) return;

    context.read<AuthBloc>().add(
          AuthProfileUpdateRequested(
            firstName:
                firstName != widget.user.firstName ? firstName : null,
            lastName: lastName != widget.user.lastName ? lastName : null,
            email: email != widget.user.email ? email : null,
            profilePictureUrl: uploadedUrl,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthProfileUpdated) {
          AppToast.show(context, 'Profile updated successfully.');
          Navigator.of(context).pop();
        } else if (state is AuthProfileError) {
          AppToast.show(context, state.error, type: AppToastType.error);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'My Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture area
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.inputBorder,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                )
                              : widget.user.profilePictureUrl != null &&
                                      widget.user.profilePictureUrl!
                                          .isNotEmpty
                                  ? Image.network(
                                      widget.user.profilePictureUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder: (_, _, _) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'File Formats: PNG, JPG, WEBP.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Recommended Dimensions: 500px by 500px',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Recommended File Size: 500 KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'UPLOAD IMAGE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              AppTextField(
                label: 'First Name',
                controller: _firstNameController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Last Name',
                controller: _lastNameController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 48),

              // Action buttons
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading || _isUploading;
                  return Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'CANCEL',
                          fontSize: 12,
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'UPDATE MY DETAILS',
                          fontSize: 12,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey.shade100,
      child: Center(
        child: Text(
          'Drag and drop\nthe file or add\nan image',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
