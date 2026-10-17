import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/core/utils/utils.dart';

void main() {
  test('smoke: Utils.sanitizeFileName strips invalid characters', () {
    expect(Utils.sanitizeFileName('a<b>:c"d/e\\f|g?h*i'), 'a_b__c_d_e_f_g_h_i');
  });

  test('smoke: Utils.formatDurationToMinutesAndSeconds pads seconds', () {
    expect(Utils.formatDurationToMinutesAndSeconds(const Duration(seconds: 5)),
        '0:05');
    expect(Utils.formatDurationToMinutesAndSeconds(const Duration(minutes: 61)),
        '61:00');
  });
}
