import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/image_upload_provider.dart';

class ProfileEditorDialog extends ConsumerStatefulWidget {
  final AppUser user;
  final String title;
  final String subtitle;

  const ProfileEditorDialog({
    super.key,
    required this.user,
    required this.title,
    required this.subtitle,
  });

  @override
  ConsumerState<ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends ConsumerState<ProfileEditorDialog> {
  late final TextEditingController _nameController;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null) {
      return;
    }

    final file = result.files.single;
    setState(() {
      _selectedImageName = file.name;
      _selectedImageBytes = file.bytes;
      _selectedImageFile = file.path != null ? File(file.path!) : null;
    });
  }

  Future<void> _saveProfile() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String avatarUrl = widget.user.avatarUrl;
      if (_selectedImageBytes != null && _selectedImageName != null) {
        final uploaded = await ref
            .read(imageUploadProvider.notifier)
            .uploadBytes(_selectedImageBytes!, filename: _selectedImageName!);
        if (uploaded != null) avatarUrl = uploaded;
      } else if (_selectedImageFile != null) {
        final uploaded = await ref
            .read(imageUploadProvider.notifier)
            .upload(_selectedImageFile!);
        if (uploaded != null) avatarUrl = uploaded;
      }

      await ref.read(authControllerProvider).updateUserProfile(
            uid: widget.user.uid,
            fullName: fullName,
            avatarUrl: avatarUrl,
          );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  ImageProvider<Object>? _avatarImage() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    }
    if (widget.user.avatarUrl.trim().isNotEmpty && widget.user.avatarUrl != 'null') {
      return NetworkImage(widget.user.avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _avatarImage();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: kNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: TextStyle(color: Colors.blueGrey.shade700),
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: kAcademicGray,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? const Icon(Icons.person, size: 40, color: kNavy)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: kNavy,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isSaving ? null : _pickAvatar,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImageName != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _selectedImageName!,
                    style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kAcademicGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: kNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kNavy,
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
