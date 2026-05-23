// shaders/halation.frag

#include <flutter/runtime_effect.glsl>

uniform vec2      uResolution;
uniform vec4      uUVRect;
uniform sampler2D uImage;

out vec4 fragColor;

// ── Frost noise ───────────────────────────────────────────────────────────────
float hash21(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / uResolution;
    vec2 imageUV   = uUVRect.xy + uv * (uUVRect.zw - uUVRect.xy);

    vec2  centered = uv - 0.5;
    float dist     = clamp(length(centered) * 2.0, 0.0, 1.0);
    float distSq   = dist * dist;

    // ── Progressive blur ──────────────────────────────────────────────────────
    float maxBlur    = 0.045;
    float blurRadius = distSq * maxBlur;

    // ── Chromatic aberration — per tap, behind the blur ───────────────────────
    // Applied inside each blur sample so the blur smears the CA fringe,
    // making it appear thicker and sitting behind the haze.
    float caStrength = distSq * 0.0028;
    vec2  ca = (dist > 0.01) ? normalize(centered) * caStrength : vec2(0.0);

    // 16-tap Poisson disc. Each tap fetches R at (off + ca), G at (off),
    // B at (off − ca). CA is baked into every sample before averaging.
    vec3 blurred = vec3(0.0);
    vec2 off;

    off = vec2(-0.9420162, -0.3990622) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.9455861, -0.7689073) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.0941841, -0.9293887) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.3449594,  0.2938776) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.9158858,  0.4577143) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.8154423, -0.8791246) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.3827754,  0.2767685) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.9748440,  0.7564838) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.4432333, -0.9751155) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.5374298, -0.4737342) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.2649691, -0.4189302) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.7919751,  0.1909019) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.2418884,  0.9970651) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2(-0.8140996,  0.9143759) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.1998413,  0.7864137) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    off = vec2( 0.1438316, -0.1410079) * blurRadius;
    blurred.r += texture(uImage, imageUV + off + ca).r;
    blurred.g += texture(uImage, imageUV + off     ).g;
    blurred.b += texture(uImage, imageUV + off - ca).b;

    blurred /= 16.0;

    // ── Dirty-lens clean overlay ──────────────────────────────────────────────
    vec3  clean    = texture(uImage, imageUV).rgb;
    float cleanMix = 0.15 * (1.0 - dist * 0.55);
    vec3  result   = mix(blurred, clean, cleanMix);

    // ── Bloom (4 wide taps, no CA) ────────────────────────────────────────────
    float bloomR = maxBlur * 0.55;
    vec3  bloom  = vec3(0.0);
    bloom += texture(uImage, imageUV + vec2( 0.707,  0.000) * bloomR).rgb;
    bloom += texture(uImage, imageUV + vec2(-0.707,  0.000) * bloomR).rgb;
    bloom += texture(uImage, imageUV + vec2( 0.000,  0.707) * bloomR).rgb;
    bloom += texture(uImage, imageUV + vec2( 0.000, -0.707) * bloomR).rgb;
    bloom /= 4.0;
    result = mix(result, bloom, 0.06 + distSq * 0.04);

    // ── Frost ─────────────────────────────────────────────────────────────────
    float grain = hash21(uv * 480.0)        * 0.035
                + hash21(uv * 200.0 + 0.37) * 0.018;
    result = mix(result, vec3(0.93, 0.96, 1.0), grain);
    result = mix(result, vec3(0.90, 0.94, 1.0), 0.07);

    // ── Darken ────────────────────────────────────────────────────────────────
    result *= 0.78;

    fragColor = vec4(result, 1.0);
}
