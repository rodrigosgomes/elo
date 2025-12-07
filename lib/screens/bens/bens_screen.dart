import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/asset_model.dart';
import '../../services/assets_event_bus.dart';
import '../../theme/app_theme.dart';
import 'asset_detail_sheet.dart';
import 'asset_form_sheet.dart';
import 'asset_security.dart';
import 'assets_controller.dart';
import '../common/step_up_prompt.dart';
import '../common/vault_navigation_bar.dart';

class BensScreen extends StatefulWidget {
  const BensScreen({super.key});

  @override
  State<BensScreen> createState() => _BensScreenState();
}

class _BensScreenState extends State<BensScreen> {
  late final AssetsController _controller;

  @override
  void initState() {
    super.initState();
    final eventBus = Provider.of<AssetsEventBus>(context, listen: false);
    _controller = AssetsController(eventBus: eventBus);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;
      if (session == null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        return;
      }
      await _controller.bootstrap();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssetsController>.value(
      value: _controller,
      child: const _BensView(),
    );
  }
}

class _BensView extends StatelessWidget {
  const _BensView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: const VaultNavigationBar(currentTab: VaultTab.bens),
      appBar: AppBar(
        title: Text(
          'Patrimônio Pessoal',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtros avançados',
            onPressed: () {
              final controller = context.read<AssetsController>();
              _showAdvancedFiltersSheet(context, controller);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar dados',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Em breve: exportação em PDF/CSV.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-bens',
        tooltip: 'Adicionar bem',
        onPressed: () {
          final controller = context.read<AssetsController>();
          Navigator.of(context).pushNamed(
            '/bens/novo',
            arguments: AssetFormEntryArgs(controller: controller),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Consumer<AssetsController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.assets.isEmpty) {
              return const _BensSkeleton();
            }

            if (controller.errorMessage != null) {
              return _BensError(
                message: controller.errorMessage!,
                onRetry: controller.refresh,
              );
            }

            return RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: controller.refresh,
              child: SlidableAutoCloseBehavior(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: _FiltersBar(controller: controller),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: _NetWorthCard(
                          summary: controller.netWorth,
                          assetCount: controller.assets.length,
                          onViewDetails: () => _showNetWorthBreakdownSheet(
                              context, controller.netWorth),
                        ),
                      ),
                    ),
                    if (controller.assets.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final asset = controller.assets[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _AssetCard(asset: asset),
                              );
                            },
                            childCount: controller.assets.length,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: controller.hasMore
                          ? _LoadMoreButton(
                              isLoading: controller.isLoadingMore,
                              onLoadMore: () => controller.loadMore(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showNetWorthBreakdownSheet(
  BuildContext context,
  NetWorthSummary summary,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return _NetWorthBreakdownSheet(summary: summary);
    },
  );
}

void _showAdvancedFiltersSheet(
  BuildContext context,
  AssetsController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AdvancedFiltersSheet(controller: controller),
  );
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.summary,
    required this.assetCount,
    required this.onViewDetails,
  });

  final NetWorthSummary summary;
  final int assetCount;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return Card(
      color: const Color(0xFF161A1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patrimônio Líquido',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              summary.hasSnapshot ? formatter.format(summary.netWorth) : '--',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            _VariationRow(summary: summary, formatter: formatter),
            const SizedBox(height: 8),
            Text(
              assetCount == 1
                  ? '1 bem cadastrado'
                  : '$assetCount bens cadastrados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
              ),
            ),
            if (summary.pendingValuations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${summary.pendingValuations.length} bens aguardando estimativa',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: summary.hasSnapshot ||
                        summary.pendingValuations.isNotEmpty ||
                        summary.fxPending.isNotEmpty
                    ? onViewDetails
                    : null,
                icon: const Icon(Icons.pie_chart_outline),
                label: const Text('Ver detalhamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariationRow extends StatelessWidget {
  const _VariationRow({required this.summary, required this.formatter});

  final NetWorthSummary summary;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = summary.historyDelta;
    if (delta != null) {
      final isPositive = delta >= 0;
      final color = isPositive ? theme.success : theme.colorScheme.error;
      final icon = isPositive ? Icons.trending_up : Icons.trending_down;
      return Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '+' : '-'}${formatter.format(delta.abs())} nas últimas 4 semanas',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      );
    }

    if (summary.hasInsufficientHistory) {
      return const SizedBox.shrink();
    }

    return Text(
      'Sem histórico acumulado ainda',
      style: theme.textTheme.bodySmall?.copyWith(color: theme.textSecondary),
    );
  }
}

class _NetWorthBreakdownSheet extends StatelessWidget {
  const _NetWorthBreakdownSheet({required this.summary});

  final NetWorthSummary summary;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalhamento do patrimônio',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.hasSnapshot ? formatter.format(summary.netWorth) : '--',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              _VariationRow(summary: summary, formatter: formatter),
              if (summary.historyReference != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Último registro: ${DateFormat('dd/MM/yyyy').format(summary.historyReference!.recordedAt)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.textSecondary),
                  ),
                ),
              const SizedBox(height: 24),
              _BreakdownSection(
                title: 'Por categoria',
                children: summary.breakdownByCategory.entries
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key.label),
                        trailing: Text(formatter.format(entry.value)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _BreakdownSection(
                title: 'Valores a estimar',
                emptyLabel: 'Nenhum bem aguardando estimativa',
                children: summary.pendingValuations
                    .map(
                      (asset) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(asset.title),
                        subtitle: Text(asset.category.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _BreakdownSection(
                title: 'Conversões pendentes',
                emptyLabel: 'Nenhuma moeda aguardando FX',
                children: summary.fxPending.entries
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: Text(formatter.format(entry.value)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.children,
    this.emptyLabel,
  });

  final String title;
  final List<Widget> children;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            emptyLabel ?? 'Sem dados',
            style:
                theme.textTheme.bodySmall?.copyWith(color: theme.textSecondary),
          )
        else
          ...children,
      ],
    );
  }
}

class _AdvancedFiltersSheet extends StatefulWidget {
  const _AdvancedFiltersSheet({required this.controller});

  final AssetsController controller;

  @override
  State<_AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<_AdvancedFiltersSheet> {
  static const double _valueSliderMax = 2000000;
  static const String _allCurrency = 'ALL';

  late AssetFilters _workingFilters;
  late Set<AssetStatus> _selectedStatuses;
  late RangeValues _valueRange;
  late RangeValues _ownershipRange;
  late String _currency;
  late AssetSortOrder _sortOrder;

  @override
  void initState() {
    super.initState();
    _workingFilters = widget.controller.filters;
    _selectedStatuses = Set<AssetStatus>.from(_workingFilters.statuses);
    _valueRange = RangeValues(
      (_workingFilters.minValue ?? 0).clamp(0, _valueSliderMax).toDouble(),
      (_workingFilters.maxValue ?? _valueSliderMax)
          .clamp(0, _valueSliderMax)
          .toDouble(),
    );
    _ownershipRange = RangeValues(
      (_workingFilters.minOwnership ?? 0).clamp(0, 100).toDouble(),
      (_workingFilters.maxOwnership ?? 100).clamp(0, 100).toDouble(),
    );
    _currency = _workingFilters.currency ?? _allCurrency;
    _sortOrder = _workingFilters.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros avançados',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Status', style: theme.textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: AssetStatus.values
                    .map(
                      (status) => FilterChip(
                        label: Text(status.label),
                        selected: _selectedStatuses.contains(status),
                        onSelected: (_) {
                          setState(() {
                            if (_selectedStatuses.contains(status)) {
                              _selectedStatuses.remove(status);
                            } else {
                              _selectedStatuses.add(status);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Faixa de valor', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                '${formatter.format(_valueRange.start)} - ${formatter.format(_valueRange.end)}',
                style: theme.textTheme.bodySmall,
              ),
              RangeSlider(
                values: _valueRange,
                min: 0,
                max: _valueSliderMax,
                divisions: 40,
                labels: RangeLabels(
                  formatter.format(_valueRange.start),
                  formatter.format(_valueRange.end),
                ),
                onChanged: (values) => setState(() => _valueRange = values),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Moeda'),
                items: const [
                  DropdownMenuItem(
                      value: _allCurrency, child: Text('Todas as moedas')),
                  DropdownMenuItem(value: 'BRL', child: Text('BRL')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _currency = value);
                },
              ),
              const SizedBox(height: 16),
              Text('Percentual de posse', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                '${_ownershipRange.start.toStringAsFixed(0)}% - ${_ownershipRange.end.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
              RangeSlider(
                values: _ownershipRange,
                min: 0,
                max: 100,
                divisions: 20,
                labels: RangeLabels(
                  '${_ownershipRange.start.toStringAsFixed(0)}%',
                  '${_ownershipRange.end.toStringAsFixed(0)}%',
                ),
                onChanged: (values) => setState(() => _ownershipRange = values),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AssetSortOrder>(
                initialValue: _sortOrder,
                decoration: const InputDecoration(labelText: 'Ordenação'),
                items: AssetSortOrder.values
                    .map(
                      (order) => DropdownMenuItem(
                        value: order,
                        child: Text(_sortLabel(order)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sortOrder = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleClear,
                    child: const Text('Limpar'),
                  ),
                  FilledButton(
                    onPressed: _handleApply,
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleClear() {
    setState(() {
      _selectedStatuses.clear();
      _valueRange = const RangeValues(0, _valueSliderMax);
      _ownershipRange = const RangeValues(0, 100);
      _currency = _allCurrency;
      _sortOrder = AssetSortOrder.updatedDesc;
    });
  }

  void _handleApply() {
    final double? minValue = _valueRange.start <= 0 ? null : _valueRange.start;
    final double? maxValue =
        _valueRange.end >= _valueSliderMax ? null : _valueRange.end;
    final double? minOwnership =
        _ownershipRange.start <= 0 ? null : _ownershipRange.start;
    final double? maxOwnership =
        _ownershipRange.end >= 100 ? null : _ownershipRange.end;
    final currencyValue = _currency == _allCurrency ? null : _currency;

    final filters = widget.controller.filters.copyWith(
      statuses: _selectedStatuses,
      minValue: minValue,
      maxValue: maxValue,
      currency: currencyValue,
      minOwnership: minOwnership,
      maxOwnership: maxOwnership,
      sortOrder: _sortOrder,
    );

    widget.controller.applyAdvancedFilters(filters);
    Navigator.of(context).pop();
  }

  String _sortLabel(AssetSortOrder order) {
    switch (order) {
      case AssetSortOrder.valueDesc:
        return 'Valor: maior primeiro';
      case AssetSortOrder.valueAsc:
        return 'Valor: menor primeiro';
      case AssetSortOrder.nameAz:
        return 'Nome A-Z';
      case AssetSortOrder.category:
        return 'Categoria';
      case AssetSortOrder.updatedDesc:
        return 'Atualizados recentemente';
    }
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.controller});

  final AssetsController controller;

  IconData _getCategoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.imoveis:
        return Icons.domain_outlined;
      case AssetCategory.veiculos:
        return Icons.directions_car_filled_outlined;
      case AssetCategory.financeiro:
        return Icons.savings_outlined;
      case AssetCategory.cripto:
        return Icons.currency_bitcoin;
      case AssetCategory.dividas:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              tooltip: 'Todos',
              label: const Icon(Icons.all_inclusive, size: 18),
              selected: controller.filters.categories.isEmpty,
              onSelected: (_) => controller.applyAdvancedFilters(
                controller.filters.copyWith(categories: <AssetCategory>{}),
              ),
            ),
            ...AssetCategory.values.map(
              (category) => FilterChip(
                tooltip: category.label,
                label: Icon(_getCategoryIcon(category), size: 18),
                selected: controller.filters.categories.contains(category),
                onSelected: (_) => controller.toggleCategory(category),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssetCard extends StatefulWidget {
  const _AssetCard({required this.asset});

  final AssetModel asset;

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  bool _actionInProgress = false;

  AssetModel get _asset => widget.asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final valueText = _asset.valueUnknown
        ? 'Valor desconhecido'
        : _asset.valueCurrency == 'BRL'
            ? formatter.format(_asset.valueEstimated ?? 0)
            : '${_asset.valueCurrency} ${(_asset.valueEstimated ?? 0).toStringAsFixed(2)}';

    final card = Card(
      color: const Color(0xFF161A1E),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(_categoryIcon(_asset.category),
              color: theme.colorScheme.primary),
        ),
        title: Text(_asset.title, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_asset.description != null && _asset.description!.isNotEmpty)
              Text(
                _asset.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            const SizedBox(height: 4),
            Text(valueText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              'Posse ${_asset.ownershipPercentage.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atualizado em ${DateFormat('dd/MM', 'pt_BR').format(_asset.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusPill(status: _asset.status),
            Icon(
              _asset.hasProof
                  ? Icons.verified_outlined
                  : Icons.warning_amber_rounded,
              color: _asset.hasProof ? theme.success : theme.warning,
            ),
          ],
        ),
        onTap: () {
          final controller = context.read<AssetsController>();
          Navigator.of(context).pushNamed(
            '/bens/${_asset.id}',
            arguments:
                AssetDetailEntryArgs(controller: controller, asset: _asset),
          );
        },
      ),
    );

    return Slidable(
      key: ValueKey('asset-${_asset.id}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.6,
        children: [
          SlidableAction(
            onPressed:
                _actionInProgress ? null : (_) async => _handleDuplicate(),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            icon: Icons.copy_all_outlined,
            label: 'Duplicar',
          ),
          SlidableAction(
            onPressed: _actionInProgress ? null : (_) async => _handleArchive(),
            backgroundColor: theme.colorScheme.error.withValues(alpha: 0.16),
            foregroundColor: theme.colorScheme.error,
            icon: Icons.archive_outlined,
            label: 'Arquivar',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.35,
        children: [
          SlidableAction(
            onPressed: _actionInProgress
                ? null
                : (_) async => _handleUploadProof(context),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            foregroundColor: theme.colorScheme.primary,
            icon: Icons.lock_outline,
            label: 'Comprovante',
          ),
        ],
      ),
      child: card,
    );
  }

  Future<void> _handleUploadProof(BuildContext context) async {
    setState(() => _actionInProgress = true);
    final controller = context.read<AssetsController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final document = await controller.uploadProof(_asset.id);
      if (!mounted) return;
      if (document != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Comprovante anexado com sucesso.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao anexar comprovante: $error')),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _handleDuplicate() async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    final controller = context.read<AssetsController>();
    try {
      await showAssetFormSheet(
        context,
        controller: controller,
        duplicateFrom: _asset,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível preparar a cópia: $error')),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _handleArchive() async {
    if (_actionInProgress) return;
    String? factor;
    if (requiresHighSecurityForAsset(_asset)) {
      factor = await showStepUpPrompt(
        context: context,
        actionLabel: 'arquivar este bem',
      );
      if (!mounted || factor == null) {
        return;
      }
    }
    setState(() => _actionInProgress = true);
    final controller = context.read<AssetsController>();
    final messenger = ScaffoldMessenger.of(context);
    final previousStatus = _asset.status;
    try {
      await controller.archiveAsset(
        _asset.id,
        factorUsed: factor,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Bem arquivado.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              controller.restoreAssetStatus(
                assetId: _asset.id,
                previousStatus: previousStatus,
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Status restaurado.')),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível arquivar: $error')),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  IconData _categoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.imoveis:
        return Icons.domain_outlined;
      case AssetCategory.veiculos:
        return Icons.directions_car_filled_outlined;
      case AssetCategory.financeiro:
        return Icons.savings_outlined;
      case AssetCategory.cripto:
        return Icons.currency_bitcoin;
      case AssetCategory.dividas:
        return Icons.receipt_long_outlined;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final AssetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late Color background;
    late Color foreground;
    switch (status) {
      case AssetStatus.active:
        background = theme.success.withValues(alpha: 0.16);
        foreground = theme.success;
        break;
      case AssetStatus.pendingReview:
        background = theme.warning.withValues(alpha: 0.16);
        foreground = theme.warning;
        break;
      case AssetStatus.archived:
        background = theme.lineSoft;
        foreground = theme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style:
            Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.isLoading, required this.onLoadMore});

  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: OutlinedButton(
        onPressed: onLoadMore,
        child: const Text('Carregar mais'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 48, color: theme.textSecondary),
        const SizedBox(height: 12),
        Text(
          'Ainda não existem bens cadastrados',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre seu primeiro ativo para liberar métricas e checklist.',
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BensSkeleton extends StatelessWidget {
  const _BensSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2127),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

class _BensError extends StatelessWidget {
  const _BensError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
