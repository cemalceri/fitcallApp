import 'package:flutter/material.dart';

class DynamicField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Type type;
  final bool isrequred;

  const DynamicField(
      {required Key key,
      required this.controller,
      required this.label,
      required this.type,
      required this.isrequred})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (type == DateTime) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              )),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              controller.text = picked.toIso8601String().split('T')[0];
            }
          },
          validator: (value) {
            if (isrequred && value!.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      );
    } else if (type == bool) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SwitchListTile(
          title: Text(label),
          value: controller.text.toLowerCase() == 'true',
          onChanged: (bool value) {
            controller.text = value.toString();
          },
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black),
              )),
          keyboardType: type == double || type == int
              ? TextInputType.number
              : TextInputType.text,
          validator: (value) {
            if (isrequred && value!.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      );
    }
  }
}

class GenericFormBuilder extends StatefulWidget {
  final Map<String, dynamic> model;
  final Map<String, dynamic> metaData;
  final String FormName;

  const GenericFormBuilder(
      {super.key,
      required this.model,
      required this.metaData,
      this.FormName = ''});

  @override
  GenericFormBuilderState createState() => GenericFormBuilderState();
}

class GenericFormBuilderState extends State<GenericFormBuilder> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    widget.metaData.forEach((key, value) {
      controllers[key] =
          TextEditingController(text: widget.model[key]?.toString() ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.metaData.keys.map((key) {
          var fieldData = widget.metaData[key];
          return DynamicField(
              controller: controllers[key]!,
              label: fieldData.label,
              type: fieldData.type,
              isrequred: fieldData.isRequired,
              key: Key("field_$key"));
        }).toList(),
      ),
    );
  }
}

class FieldMetaData {
  final String label;
  final Type type;
  final bool isRequired;

  const FieldMetaData(
      {required this.label, required this.type, this.isRequired = false});
}
