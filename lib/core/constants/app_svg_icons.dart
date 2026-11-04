import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  static String _hex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
  }

  static Widget inbox({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M7 2.5C5.59269 2.66536 4.62427 3.01488 3.89124 3.75363C2.5 5.15575 2.5 7.41242 2.5 11.9258C2.5 16.4391 2.5 18.6958 3.89124 20.0979C5.28249 21.5 7.52166 21.5 12 21.5C16.4783 21.5 18.7175 21.5 20.1088 20.0979C21.5 18.6958 21.5 16.4391 21.5 11.9258C21.5 7.41242 21.5 5.15575 20.1088 3.75363C19.3757 3.01488 18.4073 2.66536 17 2.5" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
<path d="M9.5 8C9.99153 8.5057 11.2998 10.5 12 10.5M14.5 8C14.0085 8.5057 12.7002 10.5 12 10.5M12 10.5V2.5" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
<path d="M21.5 13.5H16.5743C15.7322 13.5 15.0706 14.2036 14.6995 14.9472C14.2963 15.7551 13.4889 16.5 12 16.5C10.5111 16.5 9.70373 15.7551 9.30054 14.9472C8.92942 14.2036 8.26777 13.5 7.42566 13.5H2.5" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget bell({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M15.5 18C15.5 19.933 13.933 21.5 12 21.5C10.067 21.5 8.5 19.933 8.5 18" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
<path d="M19.2311 18H4.76887C3.79195 18 3 17.208 3 16.2311C3 15.762 3.18636 15.3121 3.51809 14.9803L4.12132 14.3771C4.68393 13.8145 5 13.0514 5 12.2558V9.5C5 5.63401 8.13401 2.5 12 2.5C15.866 2.5 19 5.634 19 9.5V12.2558C19 13.0514 19.3161 13.8145 19.8787 14.3771L20.4819 14.9803C20.8136 15.3121 21 15.762 21 16.2311C21 17.208 20.208 18 19.2311 18Z" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget calls({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M6.62 10.79a15.053 15.053 0 0 0 6.59 6.59l2.2-2.2a1 1 0 0 1 1.01-.24c1.12.37 2.33.57 3.58.57a1 1 0 0 1 1 1V20a1 1 0 0 1-1 1C10.61 21 3 13.39 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1c0 1.25.2 2.45.57 3.57a1 1 0 0 1-.25 1.02L6.62 10.79z" stroke="#$hex" stroke-width="1.8" fill="none"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget gear({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M21.3175 7.14139L20.8239 6.28479C20.4506 5.63696 20.264 5.31305 19.9464 5.18388C19.6288 5.05472 19.2696 5.15664 18.5513 5.36048L17.3311 5.70418C16.8725 5.80994 16.3913 5.74994 15.9726 5.53479L15.6357 5.34042C15.2766 5.11043 15.0004 4.77133 14.8475 4.37274L14.5136 3.37536C14.294 2.71534 14.1842 2.38533 13.9228 2.19657C13.6615 2.00781 13.3143 2.00781 12.6199 2.00781H11.5051C10.8108 2.00781 10.4636 2.00781 10.2022 2.19657C9.94085 2.38533 9.83106 2.71534 9.61149 3.37536L9.27753 4.37274C9.12465 4.77133 8.84845 5.11043 8.48937 5.34042L8.15249 5.53479C7.73374 5.74994 7.25259 5.80994 6.79398 5.70418L5.57375 5.36048C4.85541 5.15664 4.49625 5.05472 4.17867 5.18388C3.86109 5.31305 3.67445 5.63696 3.30115 6.28479L2.80757 7.14139C2.45766 7.74864 2.2827 8.05227 2.31666 8.37549C2.35061 8.69871 2.58483 8.95918 3.05326 9.48012L4.0843 10.6328C4.3363 10.9518 4.51521 11.5078 4.51521 12.0077C4.51521 12.5078 4.33636 13.0636 4.08433 13.3827L3.05326 14.5354C2.58483 15.0564 2.35062 15.3168 2.31666 15.6401C2.2827 15.9633 2.45766 16.2669 2.80757 16.8741L3.30114 17.7307C3.67443 18.3785 3.86109 18.7025 4.17867 18.8316C4.49625 18.9608 4.85542 18.8589 5.57377 18.655L6.79394 18.3113C7.25263 18.2055 7.73387 18.2656 8.15267 18.4808L8.4895 18.6752C8.84851 18.9052 9.12464 19.2442 9.2775 19.6428L9.61149 20.6403C9.83106 21.3003 9.94085 21.6303 10.2022 21.8191C10.4636 22.0078 10.8108 22.0078 11.5051 22.0078H12.6199C13.3143 22.0078 13.6615 22.0078 13.9228 21.8191C14.1842 21.6303 14.294 21.3003 14.5136 20.6403L14.8476 19.6428C15.0004 19.2442 15.2765 18.9052 15.6356 18.6752L15.9724 18.4808C16.3912 18.2656 16.8724 18.2055 17.3311 18.3113L18.5513 18.655C19.2696 18.8589 19.6288 18.9608 19.9464 18.8316C20.264 18.7025 20.4506 18.3785 20.8239 17.7307L21.3175 16.8741C21.6674 16.2669 21.8423 15.9633 21.8084 15.6401C21.7744 15.3168 21.5402 15.0564 21.0718 14.5354L20.0407 13.3827C19.7887 13.0636 19.6098 12.5078 19.6098 12.0077C19.6098 11.5078 19.7888 10.9518 20.0407 10.6328L21.0718 9.48012C21.5402 8.95918 21.7744 8.69871 21.8084 8.37549C21.8423 8.05227 21.6674 7.74864 21.3175 7.14139Z" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
<path d="M15.5195 12C15.5195 13.933 13.9525 15.5 12.0195 15.5C10.0865 15.5 8.51953 13.933 8.51953 12C8.51953 10.067 10.0865 8.5 12.0195 8.5C13.9525 8.5 15.5195 10.067 15.5195 12Z" stroke="#$hex" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget hamburger({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M3 6h18M3 12h18M3 18h18" stroke="#$hex" stroke-width="2" stroke-linecap="round"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget search({required Color color, double size = 20}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<circle cx="11" cy="11" r="8" stroke="#$hex" stroke-width="2"/>
<path d="m21 21-4.35-4.35" stroke="#$hex" stroke-width="2" stroke-linecap="round"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget filter({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<path d="M3 6h18M7 12h10M11 18h2" stroke="#$hex" stroke-width="2" stroke-linecap="round"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget userCircle({required Color color, double size = 22}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="12" r="10" stroke="#$hex" stroke-width="1.8"/>
<circle cx="12" cy="9" r="3" stroke="#$hex" stroke-width="1.8"/>
<path d="M5.5 20c0-3 3-5 6.5-5s6.5 2 6.5 5" stroke="#$hex" stroke-width="1.8" stroke-linecap="round"/>
<circle cx="18" cy="5" r="4" fill="#2CA54A"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget snooze({required Color color, double size = 20}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="13" r="8" stroke="#$hex" stroke-width="1.8"/>
<path d="M12 9v4l2.5 2.5" stroke="#$hex" stroke-width="1.8" stroke-linecap="round"/>
<path d="M8 3l4 2 4-2" stroke="#$hex" stroke-width="1.5" stroke-linecap="round"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget resolve({required Color color, double size = 20}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<circle cx="12" cy="12" r="10" stroke="#$hex" stroke-width="1.8"/>
<path d="M7 12l3.5 3.5L17 9" stroke="#$hex" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }

  static Widget more({required Color color, double size = 20}) {
    final hex = _hex(color);
    final svgString = '''<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none">
<circle cx="5" cy="12" r="1.5" fill="#$hex"/>
<circle cx="12" cy="12" r="1.5" fill="#$hex"/>
<circle cx="19" cy="12" r="1.5" fill="#$hex"/>
</svg>''';
    return SvgPicture.string(svgString, width: size, height: size);
  }
}
