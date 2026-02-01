import 'dart:async';
import 'package:flutter/services.dart';

class DeepLinkService {
  static const platform = MethodChannel('app.channel.shared.data');

  // Stream controller dla deep linków
  final StreamController<Uri> _deepLinkController =
      StreamController<Uri>.broadcast();

  Stream<Uri> get deepLinkStream => _deepLinkController.stream;

  // Inicjalizacja deep link handlera
  void initialize() {
    _handleInitialLink();
    _handleIncomingLinks();
  }

  // Obsługa początkowego linku (gdy aplikacja jest zamknięta)
  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await platform.invokeMethod('getInitialLink');
      if (initialLink != null) {
        final uri = Uri.parse(initialLink);
        _deepLinkController.add(uri);
      }
    } on PlatformException catch (e) {
      print('Error getting initial link: ${e.message}');
    }
  }

  // Obsługa przychodzących linków (gdy aplikacja jest w tle)
  void _handleIncomingLinks() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntent') {
        final link = call.arguments as String?;
        if (link != null) {
          final uri = Uri.parse(link);
          _deepLinkController.add(uri);
        }
      }
    });
  }

  // Parsowanie parametrów z deep linku
  Map<String, String>? parseDeepLink(Uri uri) {
    if (uri.scheme == 'myapp' && uri.host == 'dexcom') {
      return uri.queryParameters;
    }
    return null;
  }

  void dispose() {
    _deepLinkController.close();
  }
}
