import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/features/my_files/models/my_file_item.dart';
import 'package:zenvix/features/my_files/services/file_scanner_service.dart';

enum FileSortOption { newest, oldest, nameAsc, nameDesc, sizeDesc, sizeAsc }

class FileRepositoryState {
  const FileRepositoryState({
    this.allFiles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.sortOption = FileSortOption.newest,
    this.searchQuery = '',
    this.filterType = 'all', // 'all', 'pdf', 'image', 'text'
  });

  final List<MyFileItem> allFiles;
  final bool isLoading;
  final String? errorMessage;
  final FileSortOption sortOption;
  final String searchQuery;
  final String filterType;

  List<MyFileItem> get displayFiles {
    final filtered = allFiles.where((file) {
      // Search filter
      if (searchQuery.isNotEmpty && !file.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      
      // Type filter
      if (filterType != 'all') {
        if (filterType == 'pdf' && file.extension != 'pdf') {
          return false;
        }
        if (filterType == 'image' && !['png', 'jpg', 'jpeg'].contains(file.extension)) {
          return false;
        }
        if (filterType == 'text' && !['txt', 'csv', 'json', 'md'].contains(file.extension)) {
          return false;
        }
      }
      return true;
    }).toList();

    return _sortFiles(filtered, sortOption);
  }

  List<MyFileItem> _sortFiles(List<MyFileItem> files, FileSortOption option) {
    final sorted = List<MyFileItem>.from(files);
    switch (option) {
      case FileSortOption.newest:
        sorted.sort((a, b) => b.modified.compareTo(a.modified));
        break;
      case FileSortOption.oldest:
        sorted.sort((a, b) => a.modified.compareTo(b.modified));
        break;
      case FileSortOption.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FileSortOption.nameDesc:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case FileSortOption.sizeDesc:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case FileSortOption.sizeAsc:
        sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
    }
    return sorted;
  }

  FileRepositoryState copyWith({
    List<MyFileItem>? allFiles,
    bool? isLoading,
    String? errorMessage,
    FileSortOption? sortOption,
    String? searchQuery,
    String? filterType,
    bool clearError = false,
  }) => FileRepositoryState(
    allFiles: allFiles ?? this.allFiles,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    sortOption: sortOption ?? this.sortOption,
    searchQuery: searchQuery ?? this.searchQuery,
    filterType: filterType ?? this.filterType,
  );
}

class FileRepositoryNotifier extends StateNotifier<FileRepositoryState> {
  FileRepositoryNotifier() : super(const FileRepositoryState()) {
    loadFiles();
  }
  
  final FileScannerService _service = FileScannerService();

  Future<void> loadFiles() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final files = await _service.scanAllFiles();
      state = state.copyWith(
        isLoading: false,
        allFiles: files,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load files: $e',
      );
    }
  }

  void setSortOption(FileSortOption option) {
    if (state.sortOption != option) {
      state = state.copyWith(sortOption: option);
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query);
    }
  }

  void setFilterType(String type) {
    if (state.filterType != type) {
      state = state.copyWith(filterType: type);
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _service.deleteFile(path);
      final updated = state.allFiles.where((f) => f.path != path).toList();
      state = state.copyWith(allFiles: updated);
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete file: $e');
    }
  }

  Future<void> renameFile(String oldPath, String newName) async {
    try {
      final updatedItem = await _service.renameFile(oldPath, newName);
      final updatedFiles = state.allFiles
          .map((f) => f.path == oldPath ? updatedItem : f)
          .toList();
      state = state.copyWith(allFiles: updatedFiles);
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename file: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final fileRepositoryProvider = StateNotifierProvider<FileRepositoryNotifier, FileRepositoryState>(
  (ref) => FileRepositoryNotifier(),
);
