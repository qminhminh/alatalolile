import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
    super.key,
  });
  final double width, height, radius;
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(-1.5 + controller.value * 3, 0),
          end: Alignment(-.5 + controller.value * 3, 0),
          colors: const [
            Color(0xFF1A1A1D),
            Color(0xFF303035),
            Color(0xFF1A1A1D),
          ],
        ),
      ),
    ),
  );
}

class MovieSkeletonGrid extends StatelessWidget {
  const MovieSkeletonGrid({super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(30),
    itemCount: 12,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: 410,
      crossAxisSpacing: 18,
      mainAxisSpacing: 24,
    ),
    itemBuilder: (context, index) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: SkeletonBox(width: double.infinity, height: 230, radius: 10),
        ),
        const SizedBox(height: 10),
        SkeletonBox(width: 145, height: 16),
        const SizedBox(height: 8),
        SkeletonBox(width: 110, height: 13),
        const SizedBox(height: 8),
        SkeletonBox(width: 125, height: 12),
      ],
    ),
  );
}
