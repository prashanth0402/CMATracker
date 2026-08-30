import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/providers.dart';
import '../../shared/widgets/common.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _run(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (successMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backup = ref.read(backupServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Backups are plain JSON files stored on this device. Everything '
            'works fully offline.',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final path = await backup.exportToFile();
                      await Share.shareXFiles([XFile(path)],
                          text: 'CMA Tracker backup');
                    }, successMessage: 'Backup created'),
            icon: const Icon(Icons.upload_file),
            label: const Text('Export backup (JSON)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      if (!mounted) return;
                      final ok = await confirmDialog(
                        context,
                        title: 'Restore from backup?',
                        message:
                            'This replaces ALL current data with the backup '
                            'contents. It cannot be undone.',
                        confirmLabel: 'Choose file',
                        destructive: true,
                      );
                      if (!ok) return;
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      final path = res?.files.single.path;
                      if (path == null) return;
                      final content = await File(path).readAsString();
                      await backup.restoreFromJsonString(content);
                      ref.invalidate(allSessionsProvider);
                      ref.invalidate(subjectsProvider);
                      ref.invalidate(syllabusLookupProvider);
                    }, successMessage: 'Backup restored'),
            icon: const Icon(Icons.download),
            label: const Text('Import backup (JSON)'),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
