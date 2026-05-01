import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/features/my_files/models/my_file_item.dart';

/// Handles file system scanning and operations for "My Files" history.
class FileScannerService {
  final StorageService _storageService = StorageService();

  /// Scans both the Zenvix default folder and the app's internal documents directory.
  Future<List<MyFileItem>> scanAllFiles() async {
    final items = <MyFileItem>[];
    final processedPaths = <String>{};

    // 1. Scan primary Zenvix directory
    try {
      final zenvixDir = await _storageService.getDefaultZenvixDirectory();
      if (zenvixDir.existsSync()) {
        await _scanDirectory(zenvixDir, items, processedPaths);
      }
    }on Exception {
      // Ignore errors finding/creating default dir
    }

    // 2. Scan fallback internal documents directory
    try {
      final internalDir = await getApplicationDocumentsDirectory();
      if (internalDir.existsSync()) {
        await _scanDirectory(internalDir, items, processedPaths);
      }
    }on Exception {
      // Ignore
    }

    return items;
  }

  Future<void> _scanDirectory(Directory dir, List<MyFileItem> items, Set<String> processedPaths) async {
    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final path = entity.path;
        if (processedPaths.contains(path)) {
          continue;
        }
        
        final name = path.split('/').last.split(r'\').last;
        // Skip hidden files and temp files from other services
        if (name.startsWith('.')) {
          continue;
        }

        items.add(MyFileItem.fromFile(entity));
        processedPaths.add(path);
      }
    }
  }

  /// Deletes a file from the file system.
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Renames a file, preserving its extension.
  Future<MyFileItem> renameFile(String path, String newName) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('File does not exist');
    }

    final ext = file.path.contains('.') ? '.${file.path.split('.').last.toLowerCase()}' : '';
    
    // Ensure new name has the correct extension
    final finalNewName = newName.toLowerCase().endsWith(ext)
        ? newName
        : '$newName$ext';

    final dirPath = file.parent.path;
    final newPath = '$dirPath/$finalNewName';

    final newFile = await file.rename(newPath);
    return MyFileItem.fromFile(newFile);
  }
}
