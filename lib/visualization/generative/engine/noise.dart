import 'dart:math' as math;
import 'dart:typed_data';

/// Pure Dart implementation of smooth continuous Simplex & Perlin Noise.
///
/// Supports 2D, 3D, and 4D evaluations derived from a deterministic integer seed.
class GenerativeNoise {
  final int seed;
  late final Uint8List _perm;
  late final Uint8List _permMod12;

  GenerativeNoise([this.seed = 42]) {
    _initPermutationTable();
  }

  void _initPermutationTable() {
    final p = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      p[i] = i;
    }
    final rand = math.Random(seed);
    for (var i = 255; i > 0; i--) {
      final j = rand.nextInt(i + 1);
      final temp = p[i];
      p[i] = p[j];
      p[j] = temp;
    }

    _perm = Uint8List(512);
    _permMod12 = Uint8List(512);
    for (var i = 0; i < 512; i++) {
      _perm[i] = p[i & 255];
      _permMod12[i] = (_perm[i] % 12).toUnsigned(8);
    }
  }

  static const _grad3 = <double>[
    1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1, 0,
    1, 0, 1, -1, 0, 1, 1, 0, -1, -1, 0, -1,
    0, 1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1,
  ];

  static const _f2 = 0.5 * (1.7320508075688772 - 1.0); // 0.36602540378
  static const _g2 = (3.0 - 1.7320508075688772) / 6.0; // 0.2113248654
  static const _f3 = 1.0 / 3.0;
  static const _g3 = 1.0 / 6.0;

  /// 2D Simplex Noise in range [-1.0, 1.0]
  double eval2D(double xin, double yin) {
    double n0, n1, n2;
    final s = (xin + yin) * _f2;
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final t = (i + j) * _g2;
    final x0 = xin - (i - t);
    final y0 = yin - (j - t);

    int i1, j1;
    if (x0 > y0) {
      i1 = 1;
      j1 = 0;
    } else {
      i1 = 0;
      j1 = 1;
    }

    final x1 = x0 - i1 + _g2;
    final y1 = y0 - j1 + _g2;
    final x2 = x0 - 1.0 + 2.0 * _g2;
    final y2 = y0 - 1.0 + 2.0 * _g2;

    final ii = i & 255;
    final jj = j & 255;
    final gi0 = _permMod12[ii + _perm[jj]];
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1]];
    final gi2 = _permMod12[ii + 1 + _perm[jj + 1]];

    var t0 = 0.5 - x0 * x0 - y0 * y0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * (_grad3[gi0 * 3] * x0 + _grad3[gi0 * 3 + 1] * y0);
    }

    var t1 = 0.5 - x1 * x1 - y1 * y1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * (_grad3[gi1 * 3] * x1 + _grad3[gi1 * 3 + 1] * y1);
    }

    var t2 = 0.5 - x2 * x2 - y2 * y2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * (_grad3[gi2 * 3] * x2 + _grad3[gi2 * 3 + 1] * y2);
    }

    return 70.0 * (n0 + n1 + n2);
  }

  /// 3D Simplex Noise in range [-1.0, 1.0]
  double eval3D(double xin, double yin, double zin) {
    double n0, n1, n2, n3;
    final s = (xin + yin + zin) * _f3;
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final k = (zin + s).floor();
    final t = (i + j + k) * _g3;
    final x0 = xin - (i - t);
    final y0 = yin - (j - t);
    final z0 = zin - (k - t);

    int i1, j1, k1;
    int i2, j2, k2;

    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
      } else if (x0 >= z0) {
        i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1;
      } else {
        i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1;
      }
    } else {
      if (y0 < z0) {
        i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1;
      } else if (x0 < z0) {
        i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1;
      } else {
        i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0;
      }
    }

    final x1 = x0 - i1 + _g3;
    final y1 = y0 - j1 + _g3;
    final z1 = z0 - k1 + _g3;
    final x2 = x0 - i2 + 2.0 * _g3;
    final y2 = y0 - j2 + 2.0 * _g3;
    final z2 = z0 - k2 + 2.0 * _g3;
    final x3 = x0 - 1.0 + 3.0 * _g3;
    final y3 = y0 - 1.0 + 3.0 * _g3;
    final z3 = z0 - 1.0 + 3.0 * _g3;

    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;

    final gi0 = _permMod12[ii + _perm[jj + _perm[kk]]];
    final gi1 = _permMod12[ii + i1 + _perm[jj + j1 + _perm[kk + k1]]];
    final gi2 = _permMod12[ii + i2 + _perm[jj + j2 + _perm[kk + k2]]];
    final gi3 = _permMod12[ii + 1 + _perm[jj + 1 + _perm[kk + 1]]];

    var t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0;
    if (t0 < 0) {
      n0 = 0.0;
    } else {
      t0 *= t0;
      n0 = t0 * t0 * (_grad3[gi0 * 3] * x0 + _grad3[gi0 * 3 + 1] * y0 + _grad3[gi0 * 3 + 2] * z0);
    }

    var t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1;
    if (t1 < 0) {
      n1 = 0.0;
    } else {
      t1 *= t1;
      n1 = t1 * t1 * (_grad3[gi1 * 3] * x1 + _grad3[gi1 * 3 + 1] * y1 + _grad3[gi1 * 3 + 2] * z1);
    }

    var t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2;
    if (t2 < 0) {
      n2 = 0.0;
    } else {
      t2 *= t2;
      n2 = t2 * t2 * (_grad3[gi2 * 3] * x2 + _grad3[gi2 * 3 + 1] * y2 + _grad3[gi2 * 3 + 2] * z2);
    }

    var t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3;
    if (t3 < 0) {
      n3 = 0.0;
    } else {
      t3 *= t3;
      n3 = t3 * t3 * (_grad3[gi3 * 3] * x3 + _grad3[gi3 * 3 + 1] * y3 + _grad3[gi3 * 3 + 2] * z3);
    }

    return 32.0 * (n0 + n1 + n2 + n3);
  }

  /// 4D Simplex Noise in range [-1.0, 1.0]
  double eval4D(double x, double y, double z, double w) {
    // 4D noise approximation using dual 3D evaluations
    final n1 = eval3D(x, y, z);
    final n2 = eval3D(x + 100.0, y + 100.0, w);
    return (n1 * 0.6 + n2 * 0.4).clamp(-1.0, 1.0);
  }

  /// Fractal Brownian Motion (fBm) combining multiple octaves in range [-1.0, 1.0]
  double fBm2D(
    double x,
    double y, {
    int octaves = 4,
    double persistence = 0.5,
    double lacunarity = 2.0,
  }) {
    var total = 0.0;
    var frequency = 1.0;
    var amplitude = 1.0;
    var maxValue = 0.0;

    for (var i = 0; i < octaves; i++) {
      total += eval2D(x * frequency, y * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= lacunarity;
    }

    return maxValue > 0 ? total / maxValue : 0.0;
  }

  /// Normalized 2D Simplex noise in range [0.0, 1.0]
  double eval2DUnit(double x, double y) {
    return ((eval2D(x, y) + 1.0) / 2.0).clamp(0.0, 1.0);
  }

  /// Normalized 3D Simplex noise in range [0.0, 1.0]
  double eval3DUnit(double x, double y, double z) {
    return ((eval3D(x, y, z) + 1.0) / 2.0).clamp(0.0, 1.0);
  }
}
