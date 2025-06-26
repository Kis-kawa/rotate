// ignore_for_file: unused_local_variable

import 'dart:math';
import 'dart:io';

const double cubeStep = 0.08; // 立方体の表面の点をサンプリングする間隔
const double K2 = 5;

const int screenWidth = 80;
const int screenHeight = 40;

final double K1 = screenWidth * K2 * 1 / 8;

// 描画用の2D配列
List<List<String>> output = List.generate(
  screenHeight,
  (_) => List.filled(screenWidth, ' '),
);

// 奥行き判定用
List<List<double>> zBuffer = List.generate(
  screenHeight,
  (_) => List.filled(screenWidth, 0.0),
);

// 3Dの点とその法線を回転させ、スクリーンに投影する関数
void processPoint(double px, double py, double pz, // 点の座標
                  double nx, double ny, double nz, // 法線ベクトル
                  double cosA, double sinA,
                  double cosB, double sinB,
                  double cosC, double sinC)
{
  // Z軸周りの回転行列で回転させる
  double x1 = px * cosC - py * sinC;
  double y1 = px * sinC + py * cosC;
  double z1 = pz;
  double nx1 = nx * cosC - ny * sinC;
  double ny1 = nx * sinC + ny * cosC;
  double nz1 = nz;

  // X軸周りの回転行列で回転させる
  double x2 = x1;
  double y2 = y1 * cosA - z1 * sinA;
  double z2 = y1 * sinA + z1 * cosA;
  double nx2 = nx1;
  double ny2 = ny1 * cosA - nz1 * sinA;
  double nz2 = ny1 * sinA + nz1 * cosA;

  // Y軸周りの回転行列で回転させる
  double x3 = x2 * cosB + z2 * sinB;
  double y3 = y2;
  double z3 = -x2 * sinB + z2 * cosB;
  double nx3 = nx2 * cosB + nz2 * sinB;
  double ny3 = ny2;
  double nz3 = -nx2 * sinB + nz2 * cosB;

  double finalZ = K2 + z3;
  double ooz = 1 / finalZ;

  // スクリーン座標への投影
  int xp = (screenWidth / 2 + K1 * ooz * x3).toInt();
  int yp = (screenHeight / 2 - K1 * ooz * y3).toInt();

  // 照度の計算　＝　法線ベクトルと光源ベクトル(0,0,-1)の内積
  // (nx3×0)+(ny3×0)+(nz3×−1) = -nz3
  double L = -nz3;

  //こっち向いている
  if (L > 0) {
    // スクリーン範囲内かつ、既存の点より手前にある場合のみ描画
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


// フレーム描画
void renderFrame(double A, double B, double C) {

  double cosA = cos(A), sinA = sin(A);
  double cosB = cos(B), sinB = sin(B);
  double cosC = cos(C), sinC = sin(C);

  // バッファをクリア
  output = List.generate(screenHeight, (_) => List.filled(screenWidth, ' '));
  zBuffer = List.generate(screenHeight, (_) => List.filled(screenWidth, 0.0));

  // 立方体の6つの面をスキャンし、表面の点を処理する
  for (double u = -1; u <= 1; u += cubeStep) {
    for (double v = -1; v <= 1; v += cubeStep) {
      // 6面、表面上の点 (u, v) とその法線を processPoint に渡す
      // 立方体の各面は、座標軸に平行な平面である

      // Z方向の面
      processPoint(u, v, 1,  0, 0, 1,  cosA, sinA, cosB, sinB, cosC, sinC); // Front
      processPoint(u, v, -1, 0, 0, -1, cosA, sinA, cosB, sinB, cosC, sinC); // Back

      // Y方向の面
      processPoint(u, 1, v,  0, 1, 0,  cosA, sinA, cosB, sinB, cosC, sinC); // Top
      processPoint(u, -1, v, 0, -1, 0, cosA, sinA, cosB, sinB, cosC, sinC); // Bottom

      // X方向の面
      processPoint(1, u, v,  1, 0, 0,  cosA, sinA, cosB, sinB, cosC, sinC); // Right
      processPoint(-1, u, v, -1, 0, 0, cosA, sinA, cosB, sinB, cosC, sinC); // Left
    }
  }

  stdout.write('\x1b[H'); // ANSIエスケープコード: moves cursor to home position (0, 0)
  for (var row in output) {
    stdout.writeln(row.join());
  }
}


void main() async {
  // PitchとRollとYawらしい
  double A = 0; // X軸 の周りに回転する角度
  double B = 0; // Y軸 の周りに回転する角度
  double C = 0; // Z軸 の周りに回転する角度

  while (true) {
    renderFrame(A, B, C);
    A += 0.03;
    B += 0.02;
    C += 0.04;
    await Future.delayed(Duration(milliseconds: 30));
  }
}
