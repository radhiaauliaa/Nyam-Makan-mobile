// widgets/image_picker.dart
import 'package:flutter/material.dart';

class ImageLinkInputWidget extends StatefulWidget {
  final List<String>? initialImages;
  final void Function(List<String>)? onImagesChanged;
  final int maxImages;
  final String title;
  final bool isRequired;
  final String hintText;

  const ImageLinkInputWidget({
    super.key,
    this.initialImages,
    this.onImagesChanged,
    this.maxImages = 3,
    this.title = 'Link Gambar Restoran',
    this.isRequired = false,
    this.hintText = 'Masukkan link gambar (pisahkan dengan koma untuk multiple)',
  });

  @override
  State<ImageLinkInputWidget> createState() => _ImageLinkInputWidgetState();
}

class _ImageLinkInputWidgetState extends State<ImageLinkInputWidget> {
  final TextEditingController _linkController = TextEditingController();
  final List<String> _imageLinks = [];
  final Map<String, bool> _imageLoadErrors = {};

  @override
  void initState() {
    super.initState();
    _imageLinks.addAll(widget.initialImages ?? []);
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

        // Link Input Field
        TextFormField(
          controller: _linkController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_link),
              onPressed: _addImageLink,
            ),
          ),
          onFieldSubmitted: (_) => _addImageLink(),
        ),

        const SizedBox(height: 8),

        // Add Link Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addImageLink,
            icon: const Icon(Icons.add),
            label: const Text('Tambahkan Link Gambar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Selected Images Grid
        if (_imageLinks.isNotEmpty) ...[
          const Text(
            'Gambar yang akan digunakan:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _imageLinks.length,
            itemBuilder: (context, index) {
              return _buildImageItem(index);
            },
          ),
          const SizedBox(height: 8),
        ],

        // Info Text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contoh link gambar yang bisa digunakan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '• https://example.com/resto1.jpg\n'
                '• https://picsum.photos/400/300\n'
                '• https://via.placeholder.com/400x300\n'
                '• Maksimal ${widget.maxImages} gambar',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(int index) {
    final String imageUrl = _imageLinks[index];
    final bool hasError = _imageLoadErrors[imageUrl] ?? false;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: hasError
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 20, color: Colors.grey),
                    SizedBox(height: 4),
                    Text(
                      'Invalid',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Mark this image as having error
                    _imageLoadErrors[imageUrl] = true;
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          'Error',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
        ),
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
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _addImageLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan link gambar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_imageLinks.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal ${widget.maxImages} gambar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _imageLinks.add(link);
      _linkController.clear();
    });

    // Notify parent
    widget.onImagesChanged?.call(_imageLinks);
  }

  void _removeImage(int index) {
    final removedUrl = _imageLinks[index];
    setState(() {
      _imageLinks.removeAt(index);
      _imageLoadErrors.remove(removedUrl);
    });

    // Notify parent
    widget.onImagesChanged?.call(_imageLinks);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}

// Single Image Link Input
class SingleImageLinkInput extends StatefulWidget {
  final String? initialImage;
  final void Function(String?)? onImageChanged;
  final String title;
  final bool isRequired;
  final String hintText;

  const SingleImageLinkInput({
    super.key,
    this.initialImage,
    this.onImageChanged,
    this.title = 'Link Gambar',
    this.isRequired = false,
    this.hintText = 'Masukkan link gambar',
  });

  @override
  State<SingleImageLinkInput> createState() => _SingleImageLinkInputState();
}

class _SingleImageLinkInputState extends State<SingleImageLinkInput> {
  final TextEditingController _linkController = TextEditingController();
  String? _imageUrl;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImage;
    _linkController.text = widget.initialImage ?? '';
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

        // Link Input Field
        TextFormField(
          controller: _linkController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imageUrl != null && !_hasError)
                  const Icon(Icons.check, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.add_link),
                  onPressed: _updateImageLink,
                ),
              ],
            ),
          ),
          onChanged: (_) => _updateImageLink(),
          onFieldSubmitted: (_) => _updateImageLink(),
        ),

        const SizedBox(height: 8),

        // Image Preview
        if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
          const Text(
            'Preview:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: _hasError
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Gambar tidak dapat dimuat'),
                    ],
                  )
                : Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _hasError = true;
                          });
                        }
                      });
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Gambar tidak dapat dimuat'),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],

        // Info Text
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Masukkan link gambar yang valid (contoh: https://example.com/image.jpg)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _updateImageLink() {
    final link = _linkController.text.trim();
    setState(() {
      _imageUrl = link.isNotEmpty ? link : null;
      _hasError = false; // Reset error state when URL changes
    });

    // Notify parent
    widget.onImageChanged?.call(_imageUrl);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}