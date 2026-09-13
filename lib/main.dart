import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide ProxyProvider;
import 'providers/proxy_provider.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _seed = Color(0xFF3D7BFF);

  ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1116) : const Color(0xFFF5F7FB),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProxyProvider()),
      ],
      child: MaterialApp(
        title: 'Proxy App',
        debugShowCheckedModeBanner: false,
        theme: _build(Brightness.light),
        darkTheme: _build(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const MainScreen(),
      ),
    );
  }
}