// https://www.a1k0n.net/2011/07/20/donut-math.html

import 'dart:math';
import 'dart:io';

const double thetaSpacing = 0.07;
const double phiSpacing = 0.02;
const double R1 = 1;
const double R2 = 2;
const double K2 = 5;

const int screenWidth = 80;
const int screenHeight = 40;

final double K1 = screenWidth * K2 * 3 / (8 * (R1 + R2));

void renderFrame(double A, double B) {
  double cosA = cos(A), sinA = sin(A);
  double cosB = cos(B), sinB = sin(B);

  // 描画用の2D配列output
  List<List<String>> output = List.generate(
    screenHeight,
    (_) => List.filled(screenWidth, ' '),
  );

  //照度の2D配列zBuffer
  List<List<double>> zBuffer = List.generate(
    screenHeight,
    (_) => List.filled(screenWidth, 0.0),
  );

  // 0 < θ < 2π
  for (double theta = 0; theta < 2 * pi; theta += thetaSpacing) {
    double costheta = cos(theta), sintheta = sin(theta);

    // 0 < φ < 2π
    for (double phi = 0; phi < 2 * pi; phi += phiSpacing) {
      double cosphi = cos(phi), sinphi = sin(phi);

      double circlex = R2 + R1 * costheta;
      double circley = R1 * sintheta;

      // 3D空間での回転
      double x = circlex * (cosB * cosphi + sinA * sinB * sinphi) - circley * cosA * sinB;
      double y = circlex * (sinB * cosphi - sinA * cosB * sinphi) + circley * cosA * cosB;
      double z = K2 + cosA * circlex * sinphi + circley * sinA;
      double ooz = 1 / z;

      int xp = (screenWidth ~/ 2 + (K1 * ooz * x)).toInt();
      int yp = (screenHeight ~/ 2 - (K1 * ooz * y)).toInt();

      double L = cosphi * costheta * sinB -
                 cosA * costheta * sinphi -
                 sinA * sintheta +
                 cosB * (cosA * sintheta - costheta * sinA * sinphi);

      if (L > 0) {
        if (xp >= 0 && xp < screenWidth && yp >= 0 && yp < screenHeight) {
          if (ooz > zBuffer[yp][xp]) {
            zBuffer[yp][xp] = ooz;
            int luminanceIndex = (L * 8).toInt();
            const String luminanceChars = '.,-~:;=!*#\$@';
            luminanceIndex = luminanceIndex.clamp(0, luminanceChars.length - 1);
            output[yp][xp] = luminanceChars[luminanceIndex];
          }
        }
      }
    }
  }

  // 画面クリアして出力
  stdout.write('\x1b[H'); //moves cursor to home position (0, 0)
  for (var row in output) {
    stdout.writeln(row.join());
  }
}

void main() async {
  double A = 0; // X軸 の周りに回転する角度
  double B = 0; // Y軸 の周りに回転する角度
  while (true) {
    renderFrame(A, B);
    A += 0.04;
    B += 0.02;
    await Future.delayed(Duration(milliseconds: 30));
  }
}
