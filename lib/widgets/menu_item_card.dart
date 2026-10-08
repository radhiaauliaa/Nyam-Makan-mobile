// widgets/menu_item_card.dart
import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/theme.dart';

class MenuItemCard extends StatefulWidget {
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final double rating;
  final String reviewCount;
  final List<String> images;
  final String? imageUrl;
  final String category;
  final bool isPopular;
  final VoidCallback? onTap;
  final Function(int)? onQuantityChanged;
  final bool showQuantity;
  final int initialQuantity;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.rating = 0.0,
    this.reviewCount = '0',
    required this.images,
    this.imageUrl,
    required this.category,
    this.isPopular = false,
    this.onTap,
    this.onQuantityChanged,
    this.showQuantity = false, // Default false
    this.initialQuantity = 0, // Default 0
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
  }

  void _increment() {
    setState(() => quantity++);
    widget.onQuantityChanged?.call(quantity);
  }

  void _decrement() {
    if (quantity > 0) {
      setState(() => quantity--);
      widget.onQuantityChanged?.call(quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuImage(),
              const SizedBox(width: 12),
              Expanded(child: _buildMenuDetails()),
              const SizedBox(width: 8),
              _buildPriceAndQuantitySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuImage() {
    // PERUBAHAN: Ambil gambar pertama dari list images
    final String? imageUrl = widget.images.isNotEmpty ? widget.images.first : null;
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? const Icon(Icons.fastfood, color: Colors.grey, size: 30)
          : null,
    );
  }

  Widget _buildMenuDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isPopular)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Popular',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (widget.rating > 0) ...[
              const Icon(Icons.star, color: AppColors.primaryOrange, size: 14),
              const SizedBox(width: 4),
              Text('${widget.rating}', style: const TextStyle(fontSize: 12)),
              Text(
                ' (${widget.reviewCount})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.category,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndQuantitySection() {
    final hasDiscount =
        widget.originalPrice != null && widget.originalPrice! > widget.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDiscount) ...[
          Text(
            Helpers.formatCurrency(widget.originalPrice!),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          Helpers.formatCurrency(widget.price),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.showQuantity)
          _buildQuantitySelector()
        else
          _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 80,
      child: ElevatedButton(
        onPressed: _increment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Tambah', style: TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lightOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _decrement,
            icon: const Icon(
              Icons.remove_circle,
              color: AppColors.primaryOrange,
            ),
            iconSize: 20,
            padding: EdgeInsets.zero,
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          IconButton(
            onPressed: _increment,
            icon: const Icon(Icons.add_circle, color: AppColors.primaryOrange),
            iconSize: 20,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
