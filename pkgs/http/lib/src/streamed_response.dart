// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'base_response.dart';
import 'byte_stream.dart';
import 'utils.dart';

/// An HTTP response where the response body is received asynchronously after
/// the headers have been received.
class StreamedResponse extends BaseResponse {
  /// The stream from which the response body data can be read.
  ///
  /// This should always be a single-subscription stream.
  final ByteStream stream;

  /// Creates a new streaming response.
  ///
  /// [stream] should be a single-subscription stream.
  StreamedResponse(Stream<List<int>> stream, super.statusCode,
      {super.contentLength,
      super.request,
      super.headers,
      super.isRedirect,
      super.persistentConnection,
      super.reasonPhrase})
      : stream = toByteStream(stream);
}

abstract class ClosableStreamedResponse extends StreamedResponse {
  ClosableStreamedResponse(super.stream, super.statusCode,
      {super.contentLength,
      super.request,
      super.headers,
      super.isRedirect,
      super.persistentConnection,
      super.reasonPhrase});

  /// Closes the response body.
  ///
  /// This should be called when the body is no longer needed in order to free
  /// up underlying resources (e.g. sockets).
  Future<void> close();
}
