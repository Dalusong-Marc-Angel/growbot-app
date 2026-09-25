import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG path strings for social brand logos
class SocialSvgIcons {
  static const String google = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.28-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  static const String apple = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 170 170">
  <path fill="currentColor" d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-5.01.12-9.87-1.93-14.59-6.14-3.13-2.72-7.01-7.39-11.64-14.02-6.1-8.73-10.86-18.42-14.28-29.08-3.42-10.66-5.13-20.89-5.13-30.68 0-13.06 3.27-24.08 9.8-33.06 6.53-8.98 14.82-13.59 24.87-13.83 4.25 0 9.21 1.17 14.89 3.52 5.68 2.35 9.4 3.59 11.16 3.73 2.17 0 6.09-1.29 11.75-3.87 5.67-2.58 10.45-3.76 14.35-3.53 10.12.63 18.25 4.3 24.39 11.02-9.01 5.42-13.38 13.1-13.11 23.03.27 8.01 3.29 14.81 9.06 20.41 5.77 5.6 12.68 8.81 20.73 9.63-2.31 6.84-5.21 13.43-8.7 19.77zM119.22 31.08c0-7.3 2.66-14.25 7.98-20.85 5.32-6.6 11.95-10.23 19.89-10.88.11.98.16 1.85.16 2.61 0 7.19-2.73 14.19-8.19 21-5.46 6.81-12.19 10.51-20.19 11.1-0.12-1.09-.17-1.91-.17-2.46z"/>
</svg>
''';

  static const String x = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1227">
  <path fill="currentColor" d="M714.163 519.284L1160.89 0H1055.03L667.137 450.887L357.328 0H0L468.492 681.821L0 1226.37H105.866L515.491 750.218L842.672 1226.37H1200L714.137 519.284H714.163ZM569.165 687.828L521.697 619.934L144.011 79.6944H306.615L581.527 472.636L628.995 540.53L1024.1 1105.61H861.496L569.165 687.854V687.828Z"/>
</svg>
''';
}

/// Helper widgets for social brand icons
class SocialIcons {
  static Widget google({double size = 18}) {
    return SvgPicture.string(
      SocialSvgIcons.google,
      height: size,
      width: size,
    );
  }

  static Widget apple(BuildContext context, {double size = 18}) {
    final theme = Theme.of(context);
    return SvgPicture.string(
      SocialSvgIcons.apple,
      height: size,
      width: size,
      colorFilter: ColorFilter.mode(
        theme.colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }

  static Widget x(BuildContext context, {double size = 16}) {
    final theme = Theme.of(context);
    return SvgPicture.string(
      SocialSvgIcons.x,
      height: size,
      width: size,
      colorFilter: ColorFilter.mode(
        theme.colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }
}