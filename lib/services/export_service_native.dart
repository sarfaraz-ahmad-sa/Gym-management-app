import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadText(String name, String text, String mime) =>
    downloadBytes(name, Uint8List.fromList(utf8.encode(text)), mime);

Future<void> downloadBytes(String name, Uint8List bytes, String mime) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final file = File('${(await getTemporaryDirectory()).path}/$name');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      ),
    );
    return;
  }
  final target = await getSaveLocation(suggestedName: name);
  if (target == null) return;
  await XFile.fromData(bytes, mimeType: mime, name: name).saveTo(target.path);
}
