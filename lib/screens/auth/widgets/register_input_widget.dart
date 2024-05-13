import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterInputWidget extends StatefulWidget {
  final Function(Map<String, String>? formData) formVerileriGetir;
  const RegisterInputWidget({super.key, required this.formVerileriGetir});
  @override
  State<RegisterInputWidget> createState() => _RegisterInputWidgetState();
}

class _RegisterInputWidgetState extends State<RegisterInputWidget> {
  final TextEditingController _adiController = TextEditingController();

  final TextEditingController _soyadiController = TextEditingController();

  final TextEditingController _kimlikNoController = TextEditingController();

  final TextEditingController _cinsiyetController = TextEditingController();

  final TextEditingController _telefonController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _adresController = TextEditingController();

  final TextEditingController _seviyeRengiController = TextEditingController();

  final TextEditingController _uyeTipiController = TextEditingController();

  final TextEditingController _dogumTarihiController = TextEditingController();

  final TextEditingController _tenisGecmisiVarMiController =
      TextEditingController();

  final TextEditingController _dogumYeriController = TextEditingController();

  final TextEditingController _meslekController = TextEditingController();

  final TextEditingController _anneAdiSoyadiController =
      TextEditingController();

  final TextEditingController _anneTelefonController = TextEditingController();

  final TextEditingController _anneMailController = TextEditingController();

  final TextEditingController _anneMeslekController = TextEditingController();

  final TextEditingController _babaAdiSoyadiController =
      TextEditingController();

  final TextEditingController _babaTelefonController = TextEditingController();
  final TextEditingController _babaMailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _adiController,
            decoration: InputDecoration(
              hintText: "Adı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen adınızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _soyadiController,
            decoration: InputDecoration(
              hintText: "Soyadı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen soyadınızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
              controller: _kimlikNoController,
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: InputDecoration(
                hintText: "Kimlik No",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                filled: true,
                prefixIcon: const Icon(Icons.confirmation_number),
              )),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _cinsiyetController.text.isEmpty
                ? null
                : _cinsiyetController.text,
            decoration: InputDecoration(
              labelText: 'Cinsiyet',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.wc),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _cinsiyetController.text = newValue ?? '';
              });
            },
            items: <String>['Erkek', 'Kadın']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen cinsiyetinizi seçiniz.';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _telefonController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Telefon",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.phone),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen telefon numaranızı giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen email adresinizi giriniz.";
              } else if (!value.contains('@')) {
                return "Lütfen geçerli bir email adresi giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _adresController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: "Adres",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Lütfen adresinizi giriniz.";
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _seviyeRengiController,
            decoration: InputDecoration(
              hintText: "Seviye Rengi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.color_lens),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _uyeTipiController.text.isEmpty
                ? null
                : _uyeTipiController.text,
            decoration: InputDecoration(
              hintText: "Üye Tipi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.format_list_numbered),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _uyeTipiController.text = newValue ?? '';
              });
            },
            items: <String>['Yetişkin', 'Genç Sporcu']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen üye tipinizi seçiniz';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dogumTarihiController,
            decoration: InputDecoration(
              hintText: "Doğum Tarihi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly:
                true, // Kullanıcı doğrudan tarihi giremesin, tarih seçici kullanmalı.
            onTap: () {
              _selectDate(context);
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _tenisGecmisiVarMiController,
            decoration: InputDecoration(
              hintText: "Tenis Geçmişi Var Mı?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.sports_tennis),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _dogumYeriController,
            decoration: InputDecoration(
              hintText: "Doğum Yeri",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.place),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _meslekController,
            decoration: InputDecoration(
              hintText: "Meslek",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.work),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _anneAdiSoyadiController,
            decoration: InputDecoration(
              hintText: "Anne Adı Soyadı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _anneTelefonController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Anne Telefon",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _anneMailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Anne Email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) => value != null && !value.contains('@')
                ? "Lütfen geçerli bir email adresi giriniz."
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _anneMeslekController,
            decoration: InputDecoration(
              hintText: "Anne Meslek",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.work),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _babaAdiSoyadiController,
            decoration: InputDecoration(
              hintText: "Baba Adı Soyadı",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _babaTelefonController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Baba Telefon",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _babaMailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Baba Email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) => value != null && !value.contains('@')
                ? "Lütfen geçerli bir email adresi giriniz."
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  Theme.of(context).primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dogumTarihiController.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  void formVerileriGetir() {
    if (_formKey.currentState!.validate()) {
      // Form geçerliyse, verileri topla.
      Map<String, String> formData = {
        'Adı': _adiController.text,
        'Soyadı': _soyadiController.text,
        'Kimlik No': _kimlikNoController.text,
        'Cinsiyet': _cinsiyetController.text,
        'Telefon': _telefonController.text,
        'Email': _emailController.text,
        'Adres': _adresController.text,
        'Seviye Rengi': _seviyeRengiController.text,
        'Üye Tipi': _uyeTipiController.text,
        'Doğum Tarihi': _dogumTarihiController.text,
        'Tenis Geçmişi Var Mı': _tenisGecmisiVarMiController.text,
        'Doğum Yeri': _dogumYeriController.text,
        'Meslek': _meslekController.text,
        'Anne Adı Soyadı': _anneAdiSoyadiController.text,
        'Anne Telefon': _anneTelefonController.text,
        'Anne Email': _anneMailController.text,
        'Anne Meslek': _anneMeslekController.text,
        'Baba Adı Soyadı': _babaAdiSoyadiController.text,
        'Baba Telefon': _babaTelefonController.text,
        'Baba Email': _babaMailController.text,
      };
      widget.formVerileriGetir(formData);
    } else {
      widget.formVerileriGetir(null);
    }
  }
}
