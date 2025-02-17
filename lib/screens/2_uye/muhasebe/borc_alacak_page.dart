import 'package:fitcall/common/api_urls.dart';
import 'package:fitcall/common/methods.dart';
import 'package:fitcall/common/widgets.dart';
import 'package:fitcall/models/2_uye/muhasebe_model.dart'; // Güncellenmiş model burada tanımlı.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class BorcAlacakPage extends StatefulWidget {
  const BorcAlacakPage({super.key});

  @override
  State<BorcAlacakPage> createState() => _BorcAlacakPageState();
}

class _BorcAlacakPageState extends State<BorcAlacakPage> {
  List<OdemeBorcModel?> odemeBorcListesi = [];
  double kalanBakiye = 0;
  bool _apiIstegiTamamlandiMi = false;
  // Filtreleme: Borç mu, Ödeme mi? null ise hepsi.
  String? seciliHareketTuru;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _odemeBilgileriniCek();
    });
  }

  Future<void> _odemeBilgileriniCek() async {
    var token = await getToken(context);
    if (token != null) {
      try {
        var response = await http.post(
          Uri.parse(getOdemeBilgileri),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          // API yanıtını güncellenmiş modele göre ayrıştırıyoruz.
          List<OdemeBorcModel?> odemeBorcModel =
              OdemeBorcModel.fromJsonList(response.body);
          setState(() {
            odemeBorcListesi = odemeBorcModel;
            kalanBakiye = _kalanBakiyeHesapla(odemeBorcModel);
          });
        } else {
          throw Exception('API isteği başarısız oldu: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme bilgileri alınırken bir hata oluştu: $e'),
          ),
        );
      } finally {
        setState(() {
          _apiIstegiTamamlandiMi = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtre uygulanacaksa: Örneğin "Borc", "Odeme" veya hepsi.
    List<OdemeBorcModel?> filteredList = seciliHareketTuru == null
        ? odemeBorcListesi
        : odemeBorcListesi
            .where((element) => element!.hareketTuru == seciliHareketTuru)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme ve Borç Bilgilerim'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == "Hepsi") {
                  seciliHareketTuru = null;
                } else {
                  seciliHareketTuru = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "Hepsi",
                child: Text("Hepsi"),
              ),
              const PopupMenuItem(
                value: "Borc",
                child: Text("Borçlar"),
              ),
              const PopupMenuItem(
                value: "Odeme",
                child: Text("Ödemeler"),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      body: _apiIstegiTamamlandiMi
          ? Column(
              children: [
                Expanded(
                  child: GroupedOdemeBorcListesiWidget(
                    odemeBorcModelList: filteredList,
                  ),
                ),
                KalanBakiyeWidget(kalanBakiye: kalanBakiye),
              ],
            )
          : const LoadingSpinnerWidget(
              message: "Ödeme ve borç bilgileriniz yükleniyor...",
            ),
    );
  }
}

double _kalanBakiyeHesapla(List<OdemeBorcModel?> odemeBorcModel) {
  double toplamBorcTutari = odemeBorcModel
      .where((element) => element!.hareketTuru == 'Borc')
      .map((e) => double.parse(e!.tutar))
      .fold(0, (previousValue, element) => previousValue + element);
  double toplamOdemeTutari = odemeBorcModel
      .where((element) => element!.hareketTuru == 'Odeme')
      .map((e) => double.parse(e!.tutar))
      .fold(0, (previousValue, element) => previousValue + element);
  return toplamBorcTutari - toplamOdemeTutari;
}

/// ------------------------------------------------------------------------
/// Gruplanmış Liste Widget'ı: Yıl ve Aya Göre
/// ------------------------------------------------------------------------

class GroupedOdemeBorcListesiWidget extends StatelessWidget {
  final List<OdemeBorcModel?> odemeBorcModelList;

  const GroupedOdemeBorcListesiWidget({
    super.key,
    required this.odemeBorcModelList,
  });

  @override
  Widget build(BuildContext context) {
    // Listeyi tarihe göre ters sırala (son tarih en üstte)
    odemeBorcModelList.sort((a, b) => b!.tarih.compareTo(a!.tarih));

    // Tarihe göre grupla (ör. "2025-02" gibi anahtar)
    Map<String, List<OdemeBorcModel?>> groupedMap = {};

    for (var item in odemeBorcModelList) {
      String key = DateFormat('yyyy-MM').format(item!.tarih);
      if (groupedMap.containsKey(key)) {
        groupedMap[key]!.add(item);
      } else {
        groupedMap[key] = [item];
      }
    }

    // Gruplama sıralaması: En yeni grup en üstte
    List<String> sortedKeys = groupedMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String groupKey = sortedKeys[index];
        List<OdemeBorcModel?> groupItems = groupedMap[groupKey]!;

        // Grup başlığı: Yıl ve ayı güzelce gösterelim (örn. "Şubat 2025")
        DateTime parsedGroupDate = DateFormat('yyyy-MM').parse(groupKey);
        String groupTitle = DateFormat.yMMMM('tr').format(parsedGroupDate);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text(
                groupTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: groupItems
                  .map(
                    (item) => OdemeBorcSatiriWidget(
                      label: item!.hareketTuru, // API'deki alan adıyla uyumlu
                      date: item.tarih,
                      value: '${item.tutar} TL',
                      ucretTuru: item.ucretTuru, // Ödeme/Borç bilgisi için
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------------------
/// Ödeme ve Borç Satırı Widget'ı
/// ------------------------------------------------------------------------

class OdemeBorcSatiriWidget extends StatelessWidget {
  final String label;
  final String value;
  final DateTime date;
  final String ucretTuru;

  const OdemeBorcSatiriWidget({
    super.key,
    required this.label,
    required this.value,
    required this.date,
    required this.ucretTuru,
  });

  @override
  Widget build(BuildContext context) {
    // ucretTuru alanı "Odeme" ise Ödeme, "Borc" ise Borç yazısı gösterecek.
    final String displayText = ucretTuru == "Odeme" ? "Ödeme" : "Borç";
    final IconData icon =
        ucretTuru == "Odeme" ? Icons.arrow_upward : Icons.arrow_downward;
    final Color iconColor = ucretTuru == "Odeme" ? Colors.green : Colors.red;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        displayText,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

/// ------------------------------------------------------------------------
/// Kalan Bakiye Widget'ı
/// ------------------------------------------------------------------------

class KalanBakiyeWidget extends StatelessWidget {
  final double kalanBakiye;

  const KalanBakiyeWidget({
    super.key,
    required this.kalanBakiye,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        kalanBakiye < 0
            ? 'Fazla Ödeme: ${kalanBakiye.toStringAsFixed(2)} TL'
            : 'Kalan Borç: ${kalanBakiye.toStringAsFixed(2)} TL',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.end,
      ),
    );
  }
}
