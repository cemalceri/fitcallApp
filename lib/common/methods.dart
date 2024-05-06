import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getToken(context) async {
  SharedPreferences sp = await SharedPreferences.getInstance();
  String? token = sp.getString('token');
  if (token != null) {
    return token;
  } else {
    return null;
  }
}
