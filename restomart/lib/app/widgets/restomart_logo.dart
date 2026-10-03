/// RestoMart logo widget.
///
/// Renders the "RM" icon + "RestoMart" text.
/// Since the client hasn't provided the logo PNG/SVG yet, we build it
/// with Flutter widgets (Icon placeholder + styled text).
/// Once the client provides the actual logo file, swap the Icon for
/// an Image.asset() call.
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import 'package:google_fonts/google_fonts.dart';

class RestoMartLogo extends StatelessWidget {
  /// Size of the circular icon container.
  final double size;

  /// Whether to show the text below the icon.
  final bool showText;

  /// Text color for "Mart" — white on dark backgrounds, primary on light.
  final Color martColor;

  /// Whether to arrange the logo and text horizontally.
  final bool isHorizontal;

  const RestoMartLogo({
    super.key,
    this.size = AppDimensions.logoSizeLogin,
    this.showText = true,
    this.martColor = AppColors.textOnPrimary,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = ClipOval(
      child: Image.asset(
        'assets/images/restomart_circular_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    final textWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Resto',
            style: GoogleFonts.poppins(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          TextSpan(
            text: 'Mart',
            style: GoogleFonts.poppins(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              color: martColor,
            ),
          ),
        ],
      ),
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          if (showText) ...[
            SizedBox(width: size * 0.2),
            textWidget,
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        if (showText) ...[
          SizedBox(height: size * 0.1),
          textWidget,
        ],
      ],
    );
  }
}
