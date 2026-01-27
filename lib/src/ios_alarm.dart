// 📦 Package imports:
import 'package:logging/logging.dart';

// 🌎 Project imports:
import 'package:alarm/src/base_alarm.dart';

/// Uses method channel to interact with the native platform for iOS.
class IOSAlarm extends BaseAlarm {
  /// Creates an [IOSAlarm] instance.
  IOSAlarm() : super(Logger('IOSAlarm'));

  // insert other IOS platform specific code..
}
