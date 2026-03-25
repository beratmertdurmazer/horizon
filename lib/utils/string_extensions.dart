import 'package:google_fonts/google_fonts.dart';

extension TurkishUpperCase on String {
  String toTurkishUpperCase() {
    const trMap = {
      'i': 'İ',
      'ı': 'I',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ş': 'Ş',
      'ö': 'Ö',
      'ç': 'Ç',
    };
    
    String result = "";
    for (int i = 0; i < this.length; i++) {
      String char = this[i];
      result += trMap[char] ?? char.toUpperCase();
    }
    return result;
  }
}
