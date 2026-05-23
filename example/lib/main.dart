import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:halation/halation.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> with TickerProviderStateMixin {
  static const _assets = ['assets/1.jpg', 'assets/2.jpg', 'assets/3.jpg'];

  // ── Background ───────────────────────────────────────────────────────────
  late final String _assetPath;
  bool _imageReady = false;

  // ── Pan/zoom animation ───────────────────────────────────────────────────
  late final AnimationController _anim;

  // ── Frame capture ────────────────────────────────────────────────────────
  final _bgKey = GlobalKey();
  ui.Image? _frame;
  bool _capturing = false;
  late final Ticker _ticker;

  Size? _bodySize;

  @override
  void initState() {
    super.initState();
    _assetPath = _assets[Random().nextInt(_assets.length)];

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _ticker = createTicker((_) => _captureFrame())..start();

    _loadImage();
  }

  @override
  void dispose() {
    _anim.dispose();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    await rootBundle.load(_assetPath); // ensure bytes are in the asset bundle
    if (!mounted) return;
    await precacheImage(AssetImage(_assetPath), context);
    if (mounted) setState(() => _imageReady = true);
  }

  Future<void> _captureFrame() async {
    if (_capturing || !_imageReady) return;
    _capturing = true;
    try {
      final boundary =
          _bgKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      // pixelRatio:1 → image px == logical px → UV = widgetRect / bodySize.
      final img = await boundary.toImage(pixelRatio: 1.0);
      if (mounted) setState(() => _frame = img);
    } finally {
      _capturing = false;
    }
  }

  Widget _animatedBackground(Size body) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final t  = _anim.value * 2 * pi;
        final dx = sin(t * 0.70) * body.width  * 0.04;
        final dy = cos(t * 0.53) * body.height * 0.04;
        final sc = 1.10 + sin(t * 0.31) * 0.04;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(sc)
            ..translate(dx, dy),
          child: child,
        );
      },
      child: Image.asset(
        _assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Rect _uvRect(Size body, double w, double h) {
    final l = (body.width  - w) / 2;
    final t = (body.height - h) / 2;
    return Rect.fromLTRB(
      l / body.width,
      t / body.height,
      (l + w) / body.width,
      (t + h) / body.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _bodySize = Size(constraints.maxWidth, constraints.maxHeight);
          const glassW = 260.0, glassH = 130.0;
          final frame = _frame;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background — wrapped in RepaintBoundary so toImage()
              // captures only this layer, not the Halation widget on top.
              RepaintBoundary(
                key: _bgKey,
                child: _imageReady
                    ? _animatedBackground(_bodySize!)
                    : const ColoredBox(color: Color(0xFF0A0A0A)),
              ),

              if (frame != null)
                Center(
                  child: SizedBox(
                    width: glassW,
                    height: glassH,
                    child: Halation(
                      image: frame,
                      uvRect: _uvRect(_bodySize!, glassW, glassH),
                      borderRadius: 32,
                      child: const Center(
                        child: Text(
                          'halation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
