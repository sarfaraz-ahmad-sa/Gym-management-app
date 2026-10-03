import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadText(String name, String text, String mime) =>
    downloadBytes(name, Uint8List.fromList(utf8.encode(text)), mime);

Future<void> downloadBytes(String name, Uint8List bytes, String mime) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  Future.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
}
