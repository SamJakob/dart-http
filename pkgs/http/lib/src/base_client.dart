// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'base_request.dart';
import 'byte_stream.dart';
import 'client.dart';
import 'exception.dart';
import 'request.dart';
import 'request_controller.dart';
import 'response.dart';
import 'streamed_response.dart';

/// The abstract base class for an HTTP client.
///
/// This is a mixin-style class; subclasses only need to implement [send] and
/// maybe [close], and then they get various convenience methods for free.
abstract mixin class BaseClient implements Client {
  @override
  bool get supportsController => false;

  @override
  Future<Response> head(Uri url,
          {Map<String, String>? headers, RequestController? controller}) =>
      _sendUnstreamed('HEAD', url, headers, controller: controller);

  @override
  Future<Response> get(Uri url,
          {Map<String, String>? headers, RequestController? controller}) =>
      _sendUnstreamed('GET', url, headers, controller: controller);

  @override
  Future<Response> post(Uri url,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          RequestController? controller}) =>
      _sendUnstreamed('POST', url, headers,
          body: body, encoding: encoding, controller: controller);

  @override
  Future<Response> put(Uri url,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          RequestController? controller}) =>
      _sendUnstreamed('PUT', url, headers,
          body: body, encoding: encoding, controller: controller);

  @override
  Future<Response> patch(Uri url,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          RequestController? controller}) =>
      _sendUnstreamed('PATCH', url, headers,
          body: body, encoding: encoding, controller: controller);

  @override
  Future<Response> delete(Uri url,
          {Map<String, String>? headers,
          Object? body,
          Encoding? encoding,
          RequestController? controller}) =>
      _sendUnstreamed('DELETE', url, headers,
          body: body, encoding: encoding, controller: controller);

  @override
  Future<String> read(Uri url,
      {Map<String, String>? headers, RequestController? controller}) async {
    final response = await get(url, headers: headers, controller: controller);
    _checkResponseSuccess(url, response);
    return response.body;
  }

  @override
  Future<Uint8List> readBytes(Uri url,
      {Map<String, String>? headers, RequestController? controller}) async {
    final response = await get(url, headers: headers, controller: controller);
    _checkResponseSuccess(url, response);
    return response.bodyBytes;
  }

  /// Sends an HTTP request and asynchronously returns the response.
  ///
  /// Implementers should call [BaseRequest.finalize] to get the body of the
  /// request as a [ByteStream]. They shouldn't make any assumptions about the
  /// state of the stream; it could have data written to it asynchronously at a
  /// later point, or it could already be closed when it's returned. Any
  /// internal HTTP errors should be wrapped as [ClientException]s.
  @override
  Future<StreamedResponse> send(BaseRequest request);

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<Response> _sendUnstreamed(
      String method, Uri url, Map<String, String>? headers,
      {Object? body, Encoding? encoding, RequestController? controller}) async {
    var request = Request(method, url, controller: controller);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return Response.fromStream(await send(request));
  }

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(Uri url, Response response) {
    if (response.statusCode < 400) return;
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    throw ClientException('$message.', url);
  }

  @override
  void close({bool force = true}) {}
}
