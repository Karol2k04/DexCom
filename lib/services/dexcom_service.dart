// lib/services/dexcom_service.dart
import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/glucose_reading.dart';

class DexcomService {
  // TODO: replace with your real values from Dexcom developer portal
  static const String _clientId = 'KvPXioCdkN2T1e78QLCftUIv3pMlrvWq';
  static const String _redirectUri = 'com.dextest.mobile://oauthredirect';

  // Sandbox endpoints – for production change base URL to https://api.dexcom.com
  static const String _authEndpoint =
      'https://sandbox-api.dexcom.com/v2/oauth2/login';
  static const String _tokenEndpoint =
      'https://sandbox-api.dexcom.com/v2/oauth2/token';
  static const String _egvEndpointBase =
      'https://sandbox-api.dexcom.com/v2/users/self/egvs';

  static const FlutterAppAuth _appAuth = FlutterAppAuth();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _keyAccessToken = 'dex_access_token';
  static const String _keyRefreshToken = 'dex_refresh_token';
  static const String _keyAccessTokenExpiry = 'dex_access_token_expiry';

  Future<bool> isConnected() async {
    final token = await _secureStorage.read(key: _keyAccessToken);
    return token != null;
  }

  Future<void> disconnect() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyAccessTokenExpiry);
  }

  /// Starts Dexcom login (OAuth Authorization Code with PKCE)
  Future<bool> connect() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          scopes: const ['offline_access'],
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: _authEndpoint,
            tokenEndpoint: _tokenEndpoint,
          ),
        ),
      );

      if (result == null) {
        return false;
      }

      await _secureStorage.write(
        key: _keyAccessToken,
        value: result.accessToken,
      );
      await _secureStorage.write(
        key: _keyRefreshToken,
        value: result.refreshToken,
      );
      if (result.accessTokenExpirationDateTime != null) {
        await _secureStorage.write(
          key: _keyAccessTokenExpiry,
          value: result.accessTokenExpirationDateTime!
              .toUtc()
              .millisecondsSinceEpoch
              .toString(),
        );
      }

      return true;
    } catch (e) {
      // For debugging you can print(e)
      return false;
    }
  }

  Future<String?> _getValidAccessToken() async {
    final accessToken = await _secureStorage.read(key: _keyAccessToken);
    final expiryString = await _secureStorage.read(key: _keyAccessTokenExpiry);
    final refreshToken = await _secureStorage.read(key: _keyRefreshToken);

    if (accessToken == null) return null;

    if (expiryString != null) {
      final expiryMs = int.tryParse(expiryString);
      if (expiryMs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs, isUtc: true);
        // Refresh 1 minute before expiration
        if (DateTime.now().toUtc().isAfter(expiry.subtract(const Duration(minutes: 1))) &&
            refreshToken != null) {
          return await _refreshToken(refreshToken);
        }
      }
    }

    return accessToken;
  }

  Future<String?> _refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
        },
      );

      if (response.statusCode != 200) {
        await disconnect();
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken != null) {
        await _secureStorage.write(
          key: _keyAccessToken,
          value: newAccessToken,
        );
      }
      if (newRefreshToken != null) {
        await _secureStorage.write(
          key: _keyRefreshToken,
          value: newRefreshToken,
        );
      }

      // Dexcom returns expires_in (seconds)
      if (data['expires_in'] != null) {
        final expiresIn = data['expires_in'] as int;
        final expiry =
            DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        await _secureStorage.write(
          key: _keyAccessTokenExpiry,
          value: expiry.millisecondsSinceEpoch.toString(),
        );
      }

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  /// Fetches EGVs for the last 3 hours and maps them to GlucoseReading
  Future<List<GlucoseReading>> fetchRecentGlucose() async {
    final token = await _getValidAccessToken();
    if (token == null) {
      throw Exception('Not connected to Dexcom');
    }

    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(hours: 3));

    String fmt(DateTime dt) =>
        dt.toIso8601String().split('.').first; // drop milliseconds

    final uri = Uri.parse(
      '$_egvEndpointBase?startDate=${fmt(start)}&endDate=${fmt(now)}',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Dexcom API error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final egvs = (decoded['egvs'] as List<dynamic>? ?? []);

    // Map to your GlucoseReading model
    final readings = egvs.map((e) {
      final map = e as Map<String, dynamic>;
      final value = (map['value'] as num).toDouble();
      final displayTime = map['displayTime'] as String? ?? map['systemTime'];

      // displayTime is ISO string, we can format to HH:mm for chart
      final dt = DateTime.tryParse(displayTime ?? '');
      final timeLabel =
          dt != null ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : '';

      return GlucoseReading(
        time: timeLabel,
        value: value,
        meal: null,
      );
    }).toList();

    return readings;
  }
}
