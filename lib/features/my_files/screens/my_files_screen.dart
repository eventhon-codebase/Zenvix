import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/my_files/models/my_file_item.dart';
import 'package:zenvix/features/my_files/providers/file_repository.dart';
import 'package:zenvix/features/my_files/screens/pdf_viewer_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';

class MyFilesScreen extends ConsumerStatefulWidget {
  const MyFilesScreen({super.key});

  @override
  ConsumerState<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends ConsumerState<MyFilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileRepositoryProvider.notifier).loadFiles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(MyFileItem file) {
    final baseName = file.name.contains('.') 
      ? file.name.substring(0, file.name.lastIndexOf('.'))
      : file.name;
    
    final controller = TextEditingController(text: baseName);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename File',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'New Name',
            suffixText: file.extension.isNotEmpty ? '.${file.extension}' : '',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.electricPurple),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricPurple,
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != baseName) {
                await ref
                    .read(fileRepositoryProvider.notifier)
                    .renameFile(file.path, newName);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(MyFileItem file) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete File?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${file.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(fileRepositoryProvider.notifier).deleteFile(file.path);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(MyFileItem file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Generated with Zenvix');
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Failed to share: $e');
      }
    }
  }

  void _openFile(MyFileItem file) {
    if (file.extension == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute<PdfViewerScreen>(
          builder: (_) => PdfViewerScreen(filePath: file.path, fileName: file.name),
        ),
      );
    } else {
      // Basic fallback: just share it or show a snackbar if not pdf
      // Ideally we'd have image/text viewers, but for now share it
      _shareFile(file);
    }
  }

  IconData _getIconForExtension(String ext) {
    if (ext == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    }
    if (['png', 'jpg', 'jpeg'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['txt', 'csv', 'json', 'md'].contains(ext)) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getColorForExtension(String ext) {
    if (ext == 'pdf') {
      return AppColors.electricPurple;
    }
    if (['png', 'jpg', 'jpeg'].contains(ext)) {
      return AppColors.success;
    }
    if (['txt', 'csv', 'json', 'md'].contains(ext)) {
      return AppColors.neonBlue;
    }
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileRepositoryProvider);

    ref.listen<FileRepositoryState>(fileRepositoryProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        ref.read(fileRepositoryProvider.notifier).clearError();
      }
    });

    final displayFiles = state.displayFiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.myFiles),
        actions: [
          PopupMenuButton<FileSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (option) =>
                ref.read(fileRepositoryProvider.notifier).setSortOption(option),
            itemBuilder: (context) => [
              _buildSortItem(FileSortOption.newest, 'Newest First', state.sortOption),
              _buildSortItem(FileSortOption.oldest, 'Oldest First', state.sortOption),
              _buildSortItem(FileSortOption.nameAsc, 'Name (A-Z)', state.sortOption),
              _buildSortItem(FileSortOption.nameDesc, 'Name (Z-A)', state.sortOption),
              _buildSortItem(FileSortOption.sizeDesc, 'Largest First', state.sortOption),
              _buildSortItem(FileSortOption.sizeAsc, 'Smallest First', state.sortOption),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD, vertical: AppTheme.spacingSM),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => ref.read(fileRepositoryProvider.notifier).setSearchQuery(val),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', state.filterType),
                      const SizedBox(width: AppTheme.spacingSM),
                      _buildFilterChip('PDFs', 'pdf', state.filterType),
                      const SizedBox(width: AppTheme.spacingSM),
                      _buildFilterChip('Images', 'image', state.filterType),
                      const SizedBox(width: AppTheme.spacingSM),
                      _buildFilterChip('Documents', 'text', state.filterType),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(child: _buildBody(state, displayFiles)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(fileRepositoryProvider.notifier).setFilterType(value),
      backgroundColor: AppColors.cardSurface,
      selectedColor: AppColors.neonBlue.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.neonBlue : AppColors.surfaceBorder,
      ),
    );
  }

  PopupMenuItem<FileSortOption> _buildSortItem(
    FileSortOption option,
    String label,
    FileSortOption current,
  ) => PopupMenuItem(
    value: option,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        if (current == option)
          const Icon(Icons.check, size: 18, color: AppColors.neonBlue),
      ],
    ),
  );

  Widget _buildBody(FileRepositoryState state, List<MyFileItem> displayFiles) {
    if (state.isLoading && state.allFiles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.electricPurple),
      );
    }

    if (state.allFiles.isEmpty || displayFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricPurple.withValues(alpha: 0.2),
                    AppColors.neonBlue.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.electricPurple.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: AppColors.neonBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              state.allFiles.isEmpty ? AppStrings.emptyFilesTitle : 'No matching files',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
              child: Text(
                state.allFiles.isEmpty ? AppStrings.emptyFilesSubtitle : 'Try adjusting your search or filters.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fileRepositoryProvider.notifier).loadFiles(),
      color: AppColors.neonBlue,
      backgroundColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: displayFiles.length,
        itemBuilder: (context, index) {
          final file = displayFiles[index];
          final diff = DateTime.now().difference(file.modified);
          final timeStr = diff.inDays > 0
              ? '${diff.inDays}d ago'
              : (diff.inHours > 0 ? '${diff.inHours}h ago' : 'Just now');

          final iconData = _getIconForExtension(file.extension);
          final iconColor = _getColorForExtension(file.extension);

          return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
            color: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              side: BorderSide(
                color: AppColors.surfaceBorder.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              onTap: () => _openFile(file),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingSM),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${file.formattedSize} · $timeStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (value) {
                        if (value == 'open') {
                          _openFile(file);
                        } else if (value == 'rename') {
                          _showRenameDialog(file);
                        } else if (value == 'share') {
                          _shareFile(file);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(file);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'open', child: Text('Open')),
                        const PopupMenuItem(value: 'share', child: Text('Share')),
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
