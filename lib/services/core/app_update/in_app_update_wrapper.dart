// Android'de gerçek implementasyon, diğer platformlarda stub yüklenir
import 'in_app_update_interface.dart';
import 'in_app_update_stub.dart'
  if (dart.library.io) 'in_app_update_android.dart';

// Tipi dışarı export edelim
export 'in_app_update_interface.dart' show IInAppUpdate;

final IInAppUpdate inAppUpdate = createInAppUpdate();
