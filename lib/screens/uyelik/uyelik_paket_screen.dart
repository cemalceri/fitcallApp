import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/models/uyelik_paket_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UyelikPaketPage extends StatefulWidget {
  const UyelikPaketPage({super.key});

  @override
  State<UyelikPaketPage> createState() => _UyelikPaketPageState();
}

class _UyelikPaketPageState extends State<UyelikPaketPage> {
  List<PaketModel?> paketListesi = [];

  @override
  void initState() {
    super.initState();
    _uyelikPaketBilgileriniCek();
  }

  Future<void> _uyelikPaketBilgileriniCek() async {
    var token = await getToken(context);
    if (token != null) {
      try {
        var response = await http.post(
          Uri.parse(getPaketBilgileri),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          List<PaketModel?> paketModelList = PaketModel.fromJson(response);
          setState(() {
            paketListesi = paketModelList;
          });
        } else {
          // Hata durumunda
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        // Hata durumunda kullanıcıya bildirim gösterebilirsiniz
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme bilgileri alınırken bir hata oluştu: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Üyelik ve Paketlerim'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue[200],
            child: const Text(
              'Üyeliklerim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.blue[100],
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MembershipCard(
                    title: 'Standart Üyelik',
                    subTitle: 'Aylık 19.99 TL',
                    icon: Icons.star,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 10),
                  MembershipCard(
                    title: 'Premium Üyelik',
                    subTitle: 'Aylık 29.99 TL',
                    icon: Icons.star_border,
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue[200],
            child: const Text(
              'Paketlerim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.blue[100],
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PackageCard(
                    title: 'Temel Paket',
                    description: '3 Ekran, HD Çözünürlük',
                    icon: Icons.tv,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  PackageCard(
                    title: 'Standart Paket',
                    description: '5 Ekran, Ultra HD Çözünürlük',
                    icon: Icons.tv,
                    color: Colors.amber,
                  ),
                  SizedBox(height: 10),
                  PackageCard(
                    title: 'Premium Paket',
                    description: 'Sınırsız Ekran, Ultra HD Çözünürlük',
                    icon: Icons.tv,
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MembershipCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final IconData icon;
  final Color color;

  const MembershipCard({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: color,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subTitle,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward,
          color: Colors.white,
        ),
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PackageCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      color: color,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward,
          color: Colors.white,
        ),
      ),
    );
  }
}
