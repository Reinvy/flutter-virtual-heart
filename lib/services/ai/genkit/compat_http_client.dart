// HTTP client decorator — kompatibilitas OpenAI-compat, header tambahan, & pembatalan kooperatif.
import 'dart:convert';

import 'package:genkit/genkit.dart';
import 'package:http/http.dart' as http;

/// Decorator [http.BaseClient] untuk transport Genkit cloud.
///
/// Fitur:
/// 1. [stripStreamOptions]: menghapus field `stream_options` pada body
///    `POST */chat/completions` untuk server OpenAI-compatible lama (mis. Ollama/
///    LM Studio/proxy tertentu) yang menolak parameter tersebut.
/// 2. [extraHeaders]: menyisipkan header tambahan tanpa menimpa header yang
///    sudah eksplisit dikirim request.
/// 3. [cancelToken]: mengecek pembatalan sebelum mengirim request dan melomba
///    `send()` terhadap [CancellationToken.whenCancelled].
class CompatHttpClient extends http.BaseClient {
  CompatHttpClient(
    this._inner, {
    this.stripStreamOptions = false,
    this.extraHeaders = const {},
    this.cancelToken,
    this.closeInnerOnClose = true,
  });

  final http.Client _inner;
  final bool stripStreamOptions;
  final Map<String, String> extraHeaders;
  final CancellationToken? cancelToken;
  final bool closeInnerOnClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    cancelToken?.throwIfCancelled();

    var outgoing = request;

    if (stripStreamOptions &&
        request is http.Request &&
        request.method.toUpperCase() == 'POST' &&
        request.url.path.endsWith('/chat/completions')) {
      outgoing = _withoutStreamOptions(request);
    }

    if (extraHeaders.isNotEmpty) {
      for (final entry in extraHeaders.entries) {
        final alreadyPresent = outgoing.headers.keys.any(
          (k) => k.toLowerCase() == entry.key.toLowerCase(),
        );
        if (!alreadyPresent) {
          outgoing.headers[entry.key] = entry.value;
        }
      }
    }

    final token = cancelToken;
    if (token == null) {
      return _inner.send(outgoing);
    }

    final responseFuture = _inner.send(outgoing);
    final response = await Future.any<http.StreamedResponse?>([
      responseFuture,
      token.whenCancelled.then((_) => null),
    ]);

    if (response == null || token.isCancelled) {
      // Pastikan future asli tidak menyisakan uncaught async error jika gagal
      // belakangan, dan drain stream bila sudah telanjur datang.
      responseFuture.then(
        (res) => res.stream.drain<void>().catchError((_) {}),
        onError: (_) {},
      );
      token.throwIfCancelled();
      throw CancelledException(token: token);
    }

    return response;
  }

  static http.Request _withoutStreamOptions(http.Request request) {
    final Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(request.body);
      if (parsed is! Map) return request;
      decoded = Map<String, dynamic>.from(parsed);
    } on FormatException {
      return request;
    }

    if (!decoded.containsKey('stream_options')) return request;
    decoded.remove('stream_options');

    final replacement = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll({
        for (final entry in request.headers.entries)
          if (entry.key.toLowerCase() != 'content-length')
            entry.key: entry.value,
      })
      ..encoding = request.encoding
      ..body = jsonEncode(decoded);
    return replacement;
  }

  @override
  void close() {
    if (closeInnerOnClose) {
      _inner.close();
    }
  }
}
