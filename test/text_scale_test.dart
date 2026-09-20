import 'package:comic_reader_app/utils/text_scale.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('limits an oversized system text scale for interface controls', () {
    final scaler = AppTextScale.forInterface(TextScaler.linear(1.5));

    expect(scaler.scale(100), closeTo(115, 0.0001));
  });

  test('does not enlarge a normal system text scale', () {
    final scaler = AppTextScale.forInterface(TextScaler.linear(1));

    expect(scaler.scale(100), 100);
  });
}
