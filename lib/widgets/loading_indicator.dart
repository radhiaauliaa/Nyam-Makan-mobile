// widgets/loading_indicator.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40.0,
    this.color = AppColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 3.0,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class ButtonLoadingIndicator extends StatelessWidget {
  final Color color;

  const ButtonLoadingIndicator({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 2.0,
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Loading states for different components
class RestaurantCardLoading extends StatelessWidget {
  const RestaurantCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const ShimmerLoading(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const ShimmerLoading(width: 120, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  const ShimmerLoading(width: 80, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const ShimmerLoading(
                        width: 60,
                        height: 20,
                        borderRadius: 10,
                      ),
                      const Spacer(),
                      const ShimmerLoading(
                        width: 40,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemLoading extends StatelessWidget {
  const MenuItemLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const ShimmerLoading(width: 80, height: 80, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerLoading(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerLoading(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerLoading(width: 60, height: 30, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String message;

  const FullScreenLoading({super.key, this.message = 'Memuat...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(size: 50.0),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
