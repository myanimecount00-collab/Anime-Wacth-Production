import 'package:flutter/material.dart';

/// Wraps any child in an animated shimmer sweep.
/// Used to turn flat skeleton blocks into a "loading" effect
/// without needing the shimmer package as a dependency.
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFF1B2236),
                Color(0xFF35305C),
                Color(0xFF1B2236),
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 + dx * 3, 0),
              end: Alignment(1 + dx * 3, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single flat placeholder block. Color itself does not matter much
/// since ShimmerEffect repaints it with the moving gradient, but it
/// needs to be opaque so the shader has something to mask.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2236),
        borderRadius: borderRadius ?? BorderRadius.circular(6),
      ),
    );
  }
}

/// Full-page skeleton that mirrors the real AnimeDetailPage layout:
/// hero header, poster, title, badge row, genre chips, synopsis lines
/// and a handful of episode rows. Shown while the real data is loading,
/// instead of a centered spinner.
class AnimeDetailSkeleton extends StatelessWidget {
  const AnimeDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header skeleton
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFF14172A),
              child: Center(
                child: ShimmerBox(
                  width: 140,
                  height: 190,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 220, height: 26),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      ShimmerBox(
                        width: 78,
                        height: 26,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      SizedBox(width: 10),
                      ShimmerBox(width: 50, height: 18),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ShimmerBox(
                        width: 64,
                        height: 28,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      ShimmerBox(
                        width: 110,
                        height: 28,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      ShimmerBox(
                        width: 70,
                        height: 28,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      ShimmerBox(
                        width: 90,
                        height: 28,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const ShimmerBox(width: 100, height: 20),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 220, height: 14),
                  const SizedBox(height: 30),
                  const ShimmerBox(width: 110, height: 20),
                  const SizedBox(height: 14),
                  for (int i = 0; i < 4; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          ShimmerBox(width: 28, height: 22),
                          SizedBox(width: 14),
                          Expanded(
                            child: ShimmerBox(
                              width: double.infinity,
                              height: 14,
                            ),
                          ),
                          SizedBox(width: 14),
                          ShimmerBox(
                            width: 28,
                            height: 28,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                        ],
                      ),
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