import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme.dart';
import '../state/app_state.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (file == null) return;
    // Copy into app documents so it persists.
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'progress_photos'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    final name = 'photo_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(file.path)}';
    final saved = await File(file.path).copy(p.join(photoDir.path, name));
    if (context.mounted) {
      await context.read<AppState>().addPhoto(saved.path);
    }
  }

  void _sheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.accent),
              title: const Text('Camera se photo lo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppTheme.accent),
              title: const Text('Gallery se choose karo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final photos = state.photos;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Photos')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        onPressed: () => _sheet(context),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add'),
      ),
      body: photos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '📸 Abhi koi photo nahi.\n\nHar 1-2 hafte mein ek photo lo '
                  '(same light, same pose). Transformation yahin dikhega!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDim, height: 1.5),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: photos.length,
              itemBuilder: (ctx, i) {
                final ph = photos[i];
                final exists = File(ph.path).existsSync();
                return GestureDetector(
                  onTap: () => _viewPhoto(context, ph.path),
                  onLongPress: () => _confirmDelete(context, i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: exists
                              ? Image.file(File(ph.path), fit: BoxFit.cover)
                              : const Center(
                                  child: Icon(Icons.broken_image,
                                      color: AppTheme.textDim)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  DateFormat('d MMM yyyy').format(ph.date),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              if (ph.weightAtTime != null)
                                Text(
                                    '${ph.weightAtTime!.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.accent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewPhoto(BuildContext context, String path) {
    if (!File(path).existsSync()) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Photo delete karein?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<AppState>().removePhoto(index);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
