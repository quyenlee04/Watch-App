import 'package:flutter/material.dart';
import 'routes.dart';
import 'presentation/themes/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watch Store App',
      theme: AppTheme.theme,
      initialRoute: '/',
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
