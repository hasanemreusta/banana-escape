import 'package:banana_escape/app/banana_escape_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A three-lane runner only reads correctly in portrait. Without this the
  // game happily rotates into landscape and the lanes stretch apart.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Android 16 (API 36) enforces edge-to-edge and removed the opt-out, so the
  // app has to draw behind the system bars either way. Declaring it here means
  // the bars stay transparent instead of falling back to a scrim.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BananaEscapeApp());
}
