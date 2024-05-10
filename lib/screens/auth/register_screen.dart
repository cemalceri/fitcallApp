import 'package:fitcall/common/generic_form_builder.dart';
import 'package:fitcall/models/auth/register_model.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kayıt Ol'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GenericFormBuilder(
                  model: TemelBilgilerModel().toJson(),
                  metaData: TemelBilgilerModel.metaData),
              GenericFormBuilder(
                  model: ProfilBilgilerModel().toJson(),
                  metaData: ProfilBilgilerModel.metaData),
            ],
          ),
        ),
      ),
    );
  }
}
