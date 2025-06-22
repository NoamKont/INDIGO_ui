import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const Color primaryColor = Color(0xFF225FFF);


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen',
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryColor,
          secondary: Color(0xFFEDEFFF),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      //home: LoginScreen(),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
