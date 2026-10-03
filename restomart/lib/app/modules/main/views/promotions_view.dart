import 'package:flutter/material.dart';

class PromotionsView extends StatelessWidget {
  const PromotionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Promotions',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('All', true),
                  const SizedBox(width: 8),
                  _buildTab('Weekly Deals', false),
                  const SizedBox(width: 8),
                  _buildTab('Regular Deals', false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hero Banner
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // Pager indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(true),
                _buildDot(false),
                _buildDot(false),
                _buildDot(false),
              ],
            ),
            const SizedBox(height: 24),

            // Featured Promotions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Promotions',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF3F51B5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF3F51B5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Featured Grid
            Row(
              children: [
                Expanded(
                  child: _buildFeaturedCard(
                    'Buy 2 Get 1 Free',
                    'on Selected Beverages',
                    'assets/images/beverages.webp',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFeaturedCard(
                    'Flat 20% Off',
                    'on Cooking Oils',
                    'assets/images/sufioilCan.webp',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bottom Banner
            _buildBottomBanner(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? const Color(0xFF2C3E50) : const Color(0xFF3F51B5),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3F51B5) : const Color(0xFFC5CAE9),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Simulate the slanted two-tone background with a gradient
        gradient: const LinearGradient(
          colors: [Color(0xFFFFDF00), Color(0xFF1E3A8A)],
          stops: [0.45, 0.45],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SPECIAL OFFER',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'UP TO',
                  style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold, height: 1.0),
                ),
                const Text(
                  '70% OFF',
                  style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 32, fontWeight: FontWeight.w900, height: 1.0),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fresh Groceries | Dairy | Beverages | More',
                  style: TextStyle(color: Colors.black87, fontSize: 9),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Shop Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Placeholder Image on the Right
          Positioned(
            right: 0,
            bottom: 10,
            top: 20,
            child: Image.asset(
              'assets/images/splash_products.jpeg',
              width: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 160),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF3F51B5), fontSize: 11),
          ),
          const SizedBox(height: 8),
          Center(
            child: Image.asset(
              imagePath,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Shop Now', style: TextStyle(color: Color(0xFF2C3E50), fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Color(0xFF2C3E50), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Dark blue
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Baking Essentials\nUp to 25% Off',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Shop Now', style: TextStyle(color: Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Color(0xFF2C3E50), size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
              child: Image.asset(
                'assets/images/dryFruits.webp',
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(width: 140),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
