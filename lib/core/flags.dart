import 'flags_stub.dart' if (dart.library.io) 'flags_io.dart' as platform;

/// Le navigateur ne charge jamais dart:io. Les tests widgets coupent réseau
/// et caméra ; aucune variable système n'est consultée sur le web.
bool get isRunningUnderFlutterTest => platform.isFlutterTest;
