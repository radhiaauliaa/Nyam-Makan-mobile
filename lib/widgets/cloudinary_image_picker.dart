// widgets/cloudinary_image_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../utils/theme.dart';

/// Widget untuk upload gambar ke Cloudinary
/// Menggantikan ImageLinkInputWidget yang pakai URL manual
class CloudinaryImagePicker extends StatefulWidget {
  final List<String>? initialImages;
  final void Function(List<String>)? onImagesChanged;
  final int maxImages;
  final String title;
  final bool isRequired;
  final String folder; // Folder di Cloudinary (e.g., 'restaurants', 'menus')

  const CloudinaryImagePicker({
    super.key,
    this.initialImages,
    this.onImagesChanged,
    this.maxImages = 3,
    this.title = 'Foto',
    this.isRequired = false,
    this.folder = 'uploads',
  });

  @override
  State<CloudinaryImagePicker> createState() => _CloudinaryImagePickerState();
}

class _CloudinaryImagePickerState extends State<CloudinaryImagePicker> {
  final List<String> _uploadedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrls.addAll(widget.initialImages ?? []);
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadedImageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal ${widget.maxImages} gambar'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    // Show dialog untuk pilih sumber gambar
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryOrange),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress untuk hemat bandwidth
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: widget.folder,
      );

      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrls.add(uploadedUrl);
          _isUploading = false;
        });

        // Notify parent
        widget.onImagesChanged?.call(_uploadedImageUrls);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
    widget.onImagesChanged?.call(_uploadedImageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Upload Button
        if (!_isUploading)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                _uploadedImageUrls.isEmpty
                    ? 'Upload Gambar dari Galeri'
                    : 'Tambah Gambar (${_uploadedImageUrls.length}/${widget.maxImages})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

        // Loading Indicator
        if (_isUploading)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Mengupload gambar...'),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Uploaded Images Grid
        if (_uploadedImageUrls.isNotEmpty) ...[
          const Text(
            'Gambar yang diupload:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _uploadedImageUrls.length,
            itemBuilder: (context, index) {
              return _buildImageThumbnail(index);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    final imageUrl = _uploadedImageUrls[index];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Remove Button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget untuk upload single image ke Cloudinary
class CloudinarySingleImagePicker extends StatefulWidget {
  final String? initialImage;
  final void Function(String?)? onImageChanged;
  final String title;
  final bool isRequired;
  final String folder;

  const CloudinarySingleImagePicker({
    super.key,
    this.initialImage,
    this.onImageChanged,
    this.title = 'Foto',
    this.isRequired = false,
    this.folder = 'uploads',
  });

  @override
  State<CloudinarySingleImagePicker> createState() =>
      _CloudinarySingleImagePickerState();
}

class _CloudinarySingleImagePickerState
    extends State<CloudinarySingleImagePicker> {
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = widget.initialImage;
  }

  Future<void> _pickAndUploadImage() async {
    // Show dialog untuk pilih sumber gambar
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryOrange,
                  ),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryOrange),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      // Pick image from gallery
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      // Upload to Cloudinary
      final imageFile = File(pickedFile.path);
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile,
        folder: widget.folder,
      );

      if (uploadedUrl != null) {
        setState(() {
          _uploadedImageUrl = uploadedUrl;
          _isUploading = false;
        });

        // Notify parent
        widget.onImageChanged?.call(_uploadedImageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar berhasil diupload'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal upload gambar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _uploadedImageUrl = null;
    });
    widget.onImageChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Preview or Upload Button
        if (_uploadedImageUrl == null && !_isUploading)
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Tap untuk upload gambar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        // Loading
        if (_isUploading)
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Mengupload gambar...'),
                ],
              ),
            ),
          ),

        // Uploaded Image Preview
        if (_uploadedImageUrl != null && !_isUploading)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Remove and Change Buttons
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    // Change Button
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Remove Button
                    GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
