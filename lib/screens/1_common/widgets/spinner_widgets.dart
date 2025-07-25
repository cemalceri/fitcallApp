import 'package:flutter/material.dart';

class LoadingSpinner {
  static void show(BuildContext context, {String message = 'Yükleniyor...'}) {
    if (!Navigator.of(context).mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (!Navigator.of(context).mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class LoadingSpinnerWidget extends StatelessWidget {
  final String message;

  const LoadingSpinnerWidget({super.key, this.message = 'Yükleniyor...'});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          // Scrollable yapısı ekleniyor
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.8, // Ekran genişliğinin %80'i kadar en fazla genişleyebilir
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Flexible(
                  // Text widget'ını Flexible içine alarak taşma önleniyor
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                    softWrap:
                        true, // Uzun metinlerin alt satıra geçmesini sağlar
                    overflow: TextOverflow
                        .fade, // Metin çok uzunsa fade efekti ile bitirir
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
