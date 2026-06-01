import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';

/// Widget that displays connectivity status and cache information
class ConnectivityStatusWidget extends StatelessWidget {
  const ConnectivityStatusWidget({
    super.key,
    this.showCacheInfo = false,
  });

  final bool showCacheInfo;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ConnectivityService.instance,
      child: Consumer<ConnectivityService>(
        builder: (context, connectivity, child) {
          if (connectivity.isConnected && !connectivity.hasBeenOffline) {
            return const SizedBox.shrink();
          }

          return _ConnectivityBanner(
            connectivity: connectivity,
            showCacheInfo: showCacheInfo,
          );
        },
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({
    required this.connectivity,
    required this.showCacheInfo,
  });

  final ConnectivityService connectivity;
  final bool showCacheInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isOffline = !connectivity.isConnected;
    final backgroundColor = isOffline
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final textColor = isOffline
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;
    final iconColor = isOffline
        ? colorScheme.error
        : colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOffline ? colorScheme.error : colorScheme.primary)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.wifi,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getStatusText(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_getSubtitleText() != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitleText()!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showCacheInfo && isOffline) ...[
            const SizedBox(width: 8),
            _CacheInfoButton(textColor: textColor),
          ],
        ],
      ),
    );
  }

  String _getStatusText() {
    if (connectivity.isConnected) {
      return 'Подключение восстановлено';
    } else {
      return 'Нет подключения к интернету';
    }
  }

  String? _getSubtitleText() {
    if (connectivity.isConnected && connectivity.hasBeenOffline) {
      return 'Данные будут синхронизированы автоматически';
    } else if (!connectivity.isConnected) {
      final timeSince = connectivity.timeSinceLastConnection;
      if (timeSince != null) {
        if (timeSince.inMinutes < 1) {
          return 'Показываются сохраненные данные';
        } else if (timeSince.inHours < 1) {
          return 'Офлайн ${timeSince.inMinutes} мин. Показываются сохраненные данные';
        } else {
          return 'Офлайн ${timeSince.inHours} ч. Показываются сохраненные данные';
        }
      }
      return 'Показываются сохраненные данные';
    }
    return null;
  }
}

class _CacheInfoButton extends StatelessWidget {
  const _CacheInfoButton({
    required this.textColor,
  });

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showCacheInfo(context),
      icon: Icon(
        Icons.info_outline,
        color: textColor,
        size: 20,
      ),
      tooltip: 'Информация о кэше',
    );
  }

  void _showCacheInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CacheInfoDialog(),
    );
  }
}

class _CacheInfoDialog extends StatefulWidget {
  const _CacheInfoDialog();

  @override
  State<_CacheInfoDialog> createState() => _CacheInfoDialogState();
}

class _CacheInfoDialogState extends State<_CacheInfoDialog> {
  CacheStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    try {
      final stats = await CacheService.instance.getCacheStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Информация о кэше'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _stats == null
              ? const Text('Не удалось загрузить информацию о кэше')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Всего записей:',
                      value: '${_stats!.totalEntries}',
                    ),
                    _InfoRow(
                      label: 'Свежие данные:',
                      value: '${_stats!.freshEntries}',
                    ),
                    _InfoRow(
                      label: 'Устаревшие данные:',
                      value: '${_stats!.staleEntries}',
                    ),
                    _InfoRow(
                      label: 'Размер кэша:',
                      value: _stats!.totalSizeKB < 1024
                          ? '${_stats!.totalSizeKB.toStringAsFixed(1)} КБ'
                          : '${_stats!.totalSizeMB.toStringAsFixed(1)} МБ',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Свежие данные обновлены менее часа назад. '
                      'Устаревшие данные старше 24 часов.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
      actions: [
        if (!_isLoading && _stats != null && _stats!.totalEntries > 0)
          TextButton(
            onPressed: () => _clearCache(context),
            child: const Text('Очистить кэш'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш?'),
        content: const Text(
          'Это удалит все сохраненные данные. '
          'При следующем подключении к интернету данные будут загружены заново.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CacheService.instance.clearAllCache();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Кэш очищен')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось очистить кэш')),
          );
        }
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mixin for pages that need offline support
mixin OfflineSupportMixin<T extends StatefulWidget> on State<T> {
  bool get isConnected => ConnectivityService.instance.isConnected;
  bool get hasBeenOffline => ConnectivityService.instance.hasBeenOffline;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.instance.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      onConnectivityChanged(ConnectivityService.instance.isConnected);
    }
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(bool isConnected) {
    // Default implementation - override in your widget
    setState(() {});
  }

  /// Show connectivity status widget
  Widget buildConnectivityStatus({bool showCacheInfo = false}) {
    return ConnectivityStatusWidget(showCacheInfo: showCacheInfo);
  }
}