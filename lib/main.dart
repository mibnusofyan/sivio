import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sivio_mobile/controller/scan_controller.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'SIVIO',
        theme: ThemeData(
          primaryColor: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          home: SignDetectorView(),
        ));
  }
}
