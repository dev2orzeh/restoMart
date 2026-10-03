import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const FilterBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 10000);
  final List<String> _selectedFilters = ['Grocery']; // Default mock selection

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Balance for close icon
                Text(
                  'Filter',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFilterOption('Category', trailingText: 'Grocery'),
                  const SizedBox(height: 12),
                  _buildFilterOption('Brand'),
                  const SizedBox(height: 12),
                  _buildFilterOption('Sale'),
                  const SizedBox(height: 12),

                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        // Mock Price Curve (Visual only)
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _PriceCurvePainter(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 20000,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.grey.shade200,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPriceInput('Rs. ${_priceRange.start.toInt()}'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('-', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: _buildPriceInput('Rs. ${_priceRange.end.toInt()}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOption('Rating', trailingText: '4 Stars & Up'),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilters.clear();
                        _priceRange = const RangeValues(0, 20000);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Clear all (${_selectedFilters.length})', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back(); // Close filter
                      Get.snackbar(
                        'Filters Applied', 
                        'Price: Rs.${_priceRange.start.toInt()} - Rs.${_priceRange.end.toInt()}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Show Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, {String? trailingText}) {
    final isSelected = _selectedFilters.contains(title);
    return InkWell(
      onTap: () => _toggleFilter(title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
          boxShadow: isSelected ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                if (isSelected) const SizedBox(width: 12),
                Text(
                  title, 
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (trailingText != null)
                  Text(trailingText, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// Custom Painter for the mock distribution curve in the price slider
class _PriceCurvePainter extends CustomPainter {
  final Color color;

  _PriceCurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.3, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.4, 0, size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.6, size.width * 0.8, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.9, size.height, size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
