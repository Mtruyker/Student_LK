import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../services/secure_session_storage.dart';
import 'error_handler.dart';
import 'exceptions.dart';

/// Base API client with shared HTTP logic for all app roles.
///
/// Subclasses provide role-specific endpoints and data parsing.
/// This class handles: token storage, URI building, JSON decoding,
/// error message extraction, and authorized headers.
abstract class BaseApiClient {
  BaseApiClient({
    required String baseUrl,
    required String tokenStorageKey,
    http.Client? client,
    SessionStorage? sessionStorage,
  })  : _baseUrl = baseUrl,
        _tokenStorageKey = tokenStorageKey,
        _client = client ?? http.Client(),
        _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final String _baseUrl;
  final String _tokenStorageKey;
  final http.Client _client;
  final SessionStorage _sessionStorage;

  String? _accessToken;

  String get baseUrl => _baseUrl;
  http.Client get client => _client;
  @protected
  SessionStorage get sessionStorage => _sessionStorage;

  // ── Token management ──────────────────────────────────────────────

  Future<bool> restoreSession() async {
    final token = (await _sessionStorage.read(_tokenStorageKey))?.trim() ?? '';
    if (token.isEmpty) {
      _accessToken = null;
      return false;
    }

    _accessToken = token;
    return true;
  }

  Future<void> signOut() async {
    await setAccessToken(null);
  }

  Future<void> setAccessToken(String? token) async {
    final normalized = token?.trim() ?? '';
    if (normalized.isEmpty) {
      _accessToken = null;
      await _sessionStorage.delete(_tokenStorageKey);
      return;
    }

    _accessToken = normalized;
    await _sessionStorage.write(_tokenStorageKey, normalized);
  }

  String? get accessToken => _accessToken;

  // ── Network-safe request wrapper ────────────────────────────────

  /// Default timeout for all HTTP requests.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Executes [request] with enhanced error handling, retry logic, and logging.
  ///
  /// Uses the centralized ErrorHandler for consistent retry behavior and
  /// user-friendly error messages across all API calls.
  Future<http.Response> guardedRequest(
    Future<http.Response> Function() request, {
    String? operationName,
  }) async {
    return ErrorHandler.instance.executeHttpRequest(
      request,
      operationName: operationName ?? 'API request',
      timeout: requestTimeout,
    );
  }

  // ── HTTP helpers ──────────────────────────────────────────────────

  Uri buildUri(String path) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Map<String, String> get jsonHeaders => const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> authorizedHeaders() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw const AppAuthException('Сессия истекла. Войдите снова.');
    }

    return <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> authorizedJsonHeaders() {
    return <String, String>{
      ...authorizedHeaders(),
      'Content-Type': 'application/json',
    };
  }

  // ── JSON helpers ──────────────────────────────────────────────────

  Map<String, dynamic> decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }

    return <String, dynamic>{};
  }

  String extractMessage(
    Map<String, dynamic> json, {
    required String fallback,
  }) {
    const keys = <String>['message', 'error', 'detail', 'description'];
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return fallback;
  }

  String extractToken(Map<String, dynamic> json) {
    const keys = <String>['token', 'accessToken', 'access_token', 'jwt'];
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
