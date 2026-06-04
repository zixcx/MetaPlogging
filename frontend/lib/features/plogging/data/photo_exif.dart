import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';

/// 앨범 사진의 EXIF에서 GPS 좌표와 촬영 일시를 추출한다.
/// 값이 없거나 파싱 실패 시 해당 항목은 null.
Future<({double? lat, double? lng, DateTime? takenAt})> readPhotoMetadata(
  File file,
) async {
  try {
    final data = await readExifFromFile(file);
    if (data.isEmpty) return (lat: null, lng: null, takenAt: null);

    final lat = _dmsToDecimal(
      data['GPS GPSLatitude'],
      data['GPS GPSLatitudeRef'],
      negativeRef: 'S',
    );
    final lng = _dmsToDecimal(
      data['GPS GPSLongitude'],
      data['GPS GPSLongitudeRef'],
      negativeRef: 'W',
    );
    final takenAt = _parseExifDate(data['EXIF DateTimeOriginal']?.printable);

    return (lat: lat, lng: lng, takenAt: takenAt);
  } catch (e) {
    debugPrint('[Exif] readPhotoMetadata failed: $e');
    return (lat: null, lng: null, takenAt: null);
  }
}

// 도/분/초(Ratio 3개) + 방향 기준(N/S/E/W)을 십진수 좌표로 변환.
double? _dmsToDecimal(IfdTag? coord, IfdTag? ref, {required String negativeRef}) {
  if (coord == null) return null;
  final parts = coord.values.toList();
  if (parts.length < 3) return null;

  double? toDouble(dynamic v) => v is Ratio ? v.toDouble() : null;
  final deg = toDouble(parts[0]);
  final min = toDouble(parts[1]);
  final sec = toDouble(parts[2]);
  if (deg == null || min == null || sec == null) return null;

  var result = deg + min / 60 + sec / 3600;
  final refStr = ref?.printable.trim().toUpperCase() ?? '';
  if (refStr == negativeRef) result = -result;
  return result;
}

// EXIF DateTimeOriginal 포맷 "YYYY:MM:DD HH:MM:SS" → DateTime(local).
DateTime? _parseExifDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parts = raw.trim().split(' ');
  if (parts.length != 2) return null;
  final d = parts[0].split(':');
  final t = parts[1].split(':');
  if (d.length != 3 || t.length != 3) return null;
  try {
    return DateTime(
      int.parse(d[0]),
      int.parse(d[1]),
      int.parse(d[2]),
      int.parse(t[0]),
      int.parse(t[1]),
      int.parse(t[2]),
    );
  } catch (_) {
    return null;
  }
}
