import 'package:dada_loans/screens/dashboard/dashboard.dart';
import 'package:dada_loans/screens/login/login.dart';
import 'package:dada_loans/screens/my%20profile/profile_screen.dart';
import 'package:dada_loans/screens/request%20loan/loan_request.dart';
import 'package:dada_loans/screens/sign%20up/sign_up.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dada Loans',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: LoginScreen(),
    );
  }
}

