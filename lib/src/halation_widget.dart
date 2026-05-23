// lib/src/halation_widget.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A widget that renders a halation effect over a provided background image.
///
/// Halation is a photographic phenomenon where light bleeds beyond its proper
/// boundaries, producing a glow or haze — most visible in vintage film and
/// character lenses. This widget replicates that look via a custom GLSL
/// fragment shader, combining four optical effects:
///
/// * **Progressive blur** — zero at the centre, maximum at the edges.
/// * **Dirty-lens overlay** — a faint unblurred layer bleeds through.
/// * **Chromatic aberration** — per-tap RGB split applied behind the blur,
///   so the fringe is thick and sits underneath the haze.
/// * **Frost** — fine two-octave noise with a cold blue-white tint.
///
/// ### Minimal example
///
/// ```dart
/// Halation(
///   image: myUiImage,
///   uvRect: Rect.fromLTRB(0.25, 0.35, 0.75, 0.65),
///   borderRadius: 28,
///   child: Center(child: Text('halation')),
/// )
/// ```
///
/// ### `image`
/// A decoded [ui.Image] of the scene behind this widget. You are responsible
/// for supplying it — load it from an asset, decode video frames, or capture a
/// [RepaintBoundary].
///
/// ### `uvRect`
/// A normalised [Rect] (all values 0–1) that maps this widget's area onto
/// [image]. See the package README for a ready-made helper.
class Halation extends StatefulWidget {
  const Halation({
    super.key,
    required this.image,
    required this.uvRect,
    this.child,
    this.borderRadius = 24,
  });

  /// The full background image passed to the shader as a texture.
  final ui.Image image;

  /// Normalised UV rect (0–1) in [image] space that this widget covers.
  final Rect uvRect;

  /// Content rendered on top of the halation effect.
  final Widget? child;

  /// Corner radius applied via [ClipRRect]. Defaults to `24`.
  final double borderRadius;

  @override
  State<Halation> createState() => _HalationState();
}

class _HalationState extends State<Halation> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'packages/halation/shaders/halation.frag',
      );
      if (mounted) setState(() => _program = program);
    } catch (e, st) {
      debugPrint('[Halation] shader load failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = _program;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: CustomPaint(
        painter: program != null
            ? _HalationPainter(
                program: program,
                image: widget.image,
                uvRect: widget.uvRect,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

class _HalationPainter extends CustomPainter {
  _HalationPainter({
    required this.program,
    required this.image,
    required this.uvRect,
  });

  final ui.FragmentProgram program;
  final ui.Image image;
  final Rect uvRect;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniform layout — must match the shader declaration order exactly:
    //   uniform vec2  uResolution  → float index 0, 1
    //   uniform vec4  uUVRect      → float index 2, 3, 4, 5
    //   uniform sampler2D uImage   → sampler index 0
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, uvRect.left);
    shader.setFloat(3, uvRect.top);
    shader.setFloat(4, uvRect.right);
    shader.setFloat(5, uvRect.bottom);
    shader.setImageSampler(0, image);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _HalationPainter old) =>
      !identical(old.image, image) ||
      old.uvRect != uvRect ||
      old.program != program;
}
