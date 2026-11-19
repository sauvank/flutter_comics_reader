import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tokens returned by Google after a desktop sign-in.
class DesktopGoogleTokens {
  const DesktopGoogleTokens({required this.idToken, this.accessToken});
  final String idToken;
  final String? accessToken;
}

/// The user closed the browser tab, refused access or did not finish in time.
class DesktopGoogleSignInCanceled implements Exception {
  const DesktopGoogleSignInCanceled();
}

/// Google sign-in for Windows, where `google_sign_in` has no implementation.
///
/// Uses the OAuth 2.0 flow for installed apps: the system browser opens
/// Google's sign-in page and Google redirects to a short-lived HTTP server
/// on 127.0.0.1 (loopback), protected by PKCE and a random `state`.
/// The OAuth client is a "Desktop app" client of the Firebase project; its
/// id and secret come from `--dart-define-from-file` (see
/// docs/FIREBASE_SETUP.md). Google documents that a desktop client secret
/// cannot be kept confidential, which is why PKCE is used.
class DesktopGoogleSignIn {
  DesktopGoogleSignIn._();

  static const clientId = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
  static const clientSecret =
      String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');

  static bool get isConfigured => clientId.isNotEmpty;

  static const _timeout = Duration(minutes: 5);

  static Future<DesktopGoogleTokens> signIn({
    required String successHtml,
    required String errorHtml,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final redirectUri = 'http://127.0.0.1:${server.port}';
      final verifier = _randomString(64);
      final challenge = base64Url
          .encode(sha256.convert(ascii.encode(verifier)).bytes)
          .replaceAll('=', '');
      final state = _randomString(24);

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
        'prompt': 'select_account',
      });
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw StateError('browser');
      }

      String? code;
      final requests =
          server.timeout(_timeout, onTimeout: (sink) => sink.close());
      await for (final request in requests) {
        final params = request.uri.queryParameters;
        // Ignore stray requests such as /favicon.ico.
        if (!params.containsKey('code') && !params.containsKey('error')) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
        final ok = params['state'] == state && params['code'] != null;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(ok ? successHtml : errorHtml);
        await request.response.close();
        if (params['error'] == 'access_denied') {
          throw const DesktopGoogleSignInCanceled();
        }
        if (!ok) throw StateError(params['error'] ?? 'state');
        code = params['code'];
        break;
      }
      if (code == null) throw const DesktopGoogleSignInCanceled();

      return await _exchange(code, redirectUri, verifier);
    } finally {
      await server.close(force: true);
    }
  }

  static Future<DesktopGoogleTokens> _exchange(
      String code, String redirectUri, String verifier) async {
    final client = HttpClient();
    try {
      final req = await client
          .postUrl(Uri.parse('https://oauth2.googleapis.com/token'));
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      req.write(Uri(queryParameters: {
        'code': code,
        'client_id': clientId,
        if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': verifier,
      }).query);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final idToken = json['id_token'] as String?;
      if (res.statusCode != 200 || idToken == null) {
        throw StateError('token ${res.statusCode}');
      }
      return DesktopGoogleTokens(
        idToken: idToken,
        accessToken: json['access_token'] as String?,
      );
    } finally {
      client.close(force: true);
    }
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)])
        .join();
  }
}
