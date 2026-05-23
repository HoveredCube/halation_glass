# halation

A Flutter package that renders a **halation effect** through a custom GLSL fragment shader.

Halation is a photographic phenomenon — light bleeds beyond its proper boundaries, producing a glow or haze around bright areas. It's the signature look of vintage film stock and "character" cinema lenses. This package replicates it on any Flutter widget by layering four optical effects:

| Effect | Description |
|---|---|
| **Progressive blur** | Sharp at the centre, heavily blurred toward the edges |
| **Dirty-lens overlay** | A faint unblurred version of the background bleeds through, creating bloom around bright areas |
| **Chromatic aberration** | RGB channels split radially at the edges; applied per blur-tap so the fringe sits *behind* the haze |
| **Frost** | Fine two-octave noise with a cold blue-white tint and uniform darkening |

---

## Platform support

| Platform | Supported |
|---|---|
| Android | ✅ |
| iOS | ✅ |
| macOS | ✅ |
| Windows | ✅ |
| Linux | ✅ |
| Web | ⚠️ Depends on browser WebGL support |

Requires Flutter **≥ 3.0** (fragment shader API).

---

## Installation

```yaml
dependencies:
  halation: ^0.0.1
```

---

## Usage

`Halation` needs two things from the caller:

1. **`image`** — the background as a `dart:ui` `Image`. You are responsible for providing this (loaded from an asset, decoded from bytes, or captured from a `RepaintBoundary`).
2. **`uvRect`** — a normalised `Rect` (all values 0–1) describing which part of `image` sits behind this widget.

```dart
import 'dart:ui' as ui;
import 'package:halation/halation.dart';

// 1. Load your background image once (e.g. in initState).
final ui.Image bgImage = await loadUiImage('assets/bg.jpg');

// 2. Compute the UV rect.
//    If the glass is centred in a 400×800 body and is 260×130:
final uvRect = Rect.fromLTRB(
  (400 / 2 - 130) / 400,  // left
  (800 / 2 - 65)  / 800,  // top
  (400 / 2 + 130) / 400,  // right
  (800 / 2 + 65)  / 800,  // bottom
);

// 3. Drop it in your widget tree.
Halation(
  image: bgImage,
  uvRect: uvRect,
  borderRadius: 28,
  child: Center(
    child: Text('halation', style: TextStyle(color: Colors.white)),
  ),
)
```

### Loading a `ui.Image` from an asset

```dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

Future<ui.Image> loadUiImage(String assetPath) async {
  final data  = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  final c     = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, c.complete);
  return c.future;
}
```

### Computing `uvRect` for a `BoxFit.cover` background

```dart
import 'dart:math';

Rect computeUVRect({
  required Size imageSize,
  required Size screenSize,
  required Rect widgetRect,
}) {
  final scale = max(screenSize.width  / imageSize.width,
                    screenSize.height / imageSize.height);
  final dx = (screenSize.width  - imageSize.width  * scale) / 2;
  final dy = (screenSize.height - imageSize.height * scale) / 2;
  return Rect.fromLTRB(
    (widgetRect.left   - dx) / scale / imageSize.width,
    (widgetRect.top    - dy) / scale / imageSize.height,
    (widgetRect.right  - dx) / scale / imageSize.width,
    (widgetRect.bottom - dy) / scale / imageSize.height,
  );
}
```

---

## API

### `Halation`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `image` | `ui.Image` | required | Background image passed to the shader as a texture |
| `uvRect` | `Rect` | required | Normalised UV rect (0–1) of `image` visible through the effect |
| `child` | `Widget?` | `null` | Content rendered on top of the effect |
| `borderRadius` | `double` | `24` | Corner radius of the clipping rect |

---

## How it works

The effect is entirely GPU-side. A single GLSL fragment shader (`shaders/halation.frag`) receives the background image as a `sampler2D` and the UV rect as a `vec4`, then:

1. Computes a per-fragment radial distance from the widget centre.
2. Runs a **16-tap Poisson-disc blur** whose radius scales with `distance²`.
3. Applies **chromatic aberration** by offsetting R and B channels in opposite radial directions *inside each tap*, so the fringe is smeared by the blur.
4. Mixes in the **clean unblurred sample** at low opacity (dirty-lens effect).
5. Adds a **4-tap wide bloom** pass.
6. Overlays **two-octave hash noise** for frost texture with a cold tint.
7. Applies a final **uniform darkening**.
