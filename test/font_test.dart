import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GoogleFonts ibmPlexSansArabic resolves properly', () {
    final style = GoogleFonts.ibmPlexSansArabic();
    // ignore: avoid_print
    print('FAMILY: ${style.fontFamily}');
    expect(style.fontFamily, isNotNull);
  });
}
