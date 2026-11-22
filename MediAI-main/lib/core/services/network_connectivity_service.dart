import 'dart:io';

class NetworkConnectivityService {
  static Future<bool> isNetworkAvailable() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
