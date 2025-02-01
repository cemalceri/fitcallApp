// antrenor_home_page.dart

import 'package:fitcall/common/methods.dart';
import 'package:flutter/material.dart';

class AntrenorHomePage extends StatelessWidget {
  const AntrenorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Antrenör Ana Sayfa"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          )
        ],
      ),
      body: Center(
        child: Text(
          "Antrenör olarak giriş yaptınız.",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
