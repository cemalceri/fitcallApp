import 'package:flutter/material.dart';

class AntrenorOgrencilerPage extends StatelessWidget {
  AntrenorOgrencilerPage({super.key});

  // Örnek öğrenci listesi
  final List<Map<String, String>> students = [
    {'name': 'Ahmet Yılmaz', 'image': ''},
    {'name': 'Ayşe Demir', 'image': ''},
    {'name': 'Mehmet Öz', 'image': ''},
    {'name': 'Zeynep Kaya', 'image': ''},
    {'name': 'Emre Can', 'image': ''},
    {'name': 'Fatma Aksoy', 'image': ''},
    {'name': 'Hüseyin Toprak', 'image': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrencilerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: students.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 sütun olacak şekilde ayarlandı
            crossAxisSpacing: 12, // Öğrenciler arası yatay boşluk
            mainAxisSpacing: 12, // Öğrenciler arası dikey boşluk
            childAspectRatio: 1, // Kutu oranı kareye yakın olacak
          ),
          itemBuilder: (context, index) {
            final student = students[index];

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                // Öğrenci detay sayfasına yönlendirme (ilerleyen aşamalarda eklenebilir)
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person, // Öğrenci resmi yerine ikon kullanıldı
                    size: 50,
                    color: Color.fromARGB(255, 47, 42, 42),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    student['name']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 14, 46, 190),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
