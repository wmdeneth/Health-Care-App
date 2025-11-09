import 'package:flutter/material.dart';

class WaveHeader extends StatelessWidget {
  final Color color;
  final double height;
  final Widget? child;

  const WaveHeader({
    super.key,
    this.color = const Color(0xFF4285F4),
    this.height = 180,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: color,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.65);

    final firstControl = Offset(size.width * 0.25, size.height);
    final firstEnd = Offset(size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
      firstControl.dx,
      firstControl.dy,
      firstEnd.dx,
      firstEnd.dy,
    );

    final secondControl = Offset(size.width * 0.75, size.height * 0.6);
    final secondEnd = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(
      secondControl.dx,
      secondControl.dy,
      secondEnd.dx,
      secondEnd.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
