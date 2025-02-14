import 'package:flutter/material.dart';
import 'package:sivio_mobile/controller/scan_controller.dart';
import 'package:sivio_mobile/controller/speech_to_text.dart';
import 'package:get/get.dart';

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.face),
                  text: "Bahasa Isyarat",
                ),
                Tab(
                  icon: Icon(Icons.mic),
                  text: "Suara ke Teks",
                ),
              ],
            ),
            title: Text('Komunikasi'),
          ),
          body: TabBarView(
            children: [
              SignDetectorView(),
              SpeechToTextPage(),
            ],
          ),
        ),
      ),
    );
  }
}
