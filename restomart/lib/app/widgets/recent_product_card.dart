import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class RecentProductCard extends StatelessWidget {
  final String imagePath;
  final String name;
  final double price;

  const RecentProductCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Full Image Background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imagePath.isEmpty
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : imagePath.startsWith('http')
                    ? Image.network(imagePath, width: 140, height: 180, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                    : Image.asset(imagePath, width: 140, height: 180, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
          ),
          // Dark Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Text Content at Bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${price.toInt()}Rs.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
