import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent, // Yellow border
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: imagePath.isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : imagePath.startsWith('http')
                        ? Image.network(imagePath, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                        : Image.asset(imagePath, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 8, right: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
