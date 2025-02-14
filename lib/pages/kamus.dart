import 'package:flutter/material.dart';

class KamusPage extends StatelessWidget {
  final List<Map<String, String>> data = [
    {'image': 'assets/dataset-img/0.png', 'text': '0'},
    {'image': 'assets/dataset-img/1.jpg', 'text': '1'},
    {'image': 'assets/dataset-img/2.jpg', 'text': '2'},
    {'image': 'assets/dataset-img/5.jpg', 'text': '5'},
    {'image': 'assets/dataset-img/selamat.jpg', 'text': 'selamat'},
    {'image': 'assets/dataset-img/pagi.jpg', 'text': 'pagi'},
    {'image': 'assets/dataset-img/tidur.jpg', 'text': 'tidur'},
    {'image': 'assets/dataset-img/terima.jpg', 'text': 'terima'},
    {'image': 'assets/dataset-img/kasih.jpg', 'text': 'kasih'},
    {'image': 'assets/dataset-img/maaf.jpg', 'text': 'maaf'},
    {'image': 'assets/dataset-img/tolong.jpg', 'text': 'tolong'},
    {'image': 'assets/dataset-img/ya.jpg', 'text': 'ya'},
    {'image': 'assets/dataset-img/makan.jpg', 'text': 'makan'},
    {'image': 'assets/dataset-img/minum.jpg', 'text': 'minum'},
    {'image': 'assets/dataset-img/jalan.jpg', 'text': 'jalan'},
    {'image': 'assets/dataset-img/rumah.png', 'text': 'rumah'},
    {'image': 'assets/dataset-img/dingin.jpg', 'text': 'dingin'},
    {'image': 'assets/dataset-img/jam.png', 'text': 'jam'},
    {'image': 'assets/dataset-img/teman.jpg', 'text': 'teman'},
    {'image': 'assets/dataset-img/ayah.jpg', 'text': 'ayah'},
    {'image': 'assets/dataset-img/ibu.jpg', 'text': 'ibu'},
    {'image': 'assets/dataset-img/baca.png', 'text': 'baca'},
    {'image': 'assets/dataset-img/sepatu.png', 'text': 'sepatu'},
    {'image': 'assets/dataset-img/handphone.jpg', 'text': 'handphone'},
    {'image': 'assets/dataset-img/hujan.jpg', 'text': 'hujan'},
    {'image': 'assets/dataset-img/foto.jpg', 'text': 'foto'},
    {'image': 'assets/dataset-img/sayur.png', 'text': 'sayur'},
    {'image': 'assets/dataset-img/meja.jpg', 'text': 'meja'},
    {'image': 'assets/dataset-img/saya.jpg', 'text': 'saya'},
    {'image': 'assets/dataset-img/kamu.png', 'text': 'kamu'},
    {'image': 'assets/dataset-img/pergi.jpg', 'text': 'pergi'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.blue,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Kamus',
          style: TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                // Gambar dengan border
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      data[index]['image']!,
                      fit: BoxFit.cover,
                      height: 120,
                      width: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data[index]['text']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
