import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/asset_model.dart';
import 'assets_controller.dart';

Future<void> showAssetFormSheet(
  BuildContext context, {
  AssetModel? asset,
  AssetModel? duplicateFrom,
  AssetsController? controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF161A1E),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final resolvedController =
          controller ?? Provider.of<AssetsController>(ctx, listen: false);
      return AssetFormSheet(
        controller: resolvedController,
        asset: asset,
        duplicateFrom: duplicateFrom,
      );
    },
  );
}

class AssetFormSheet extends StatefulWidget {
  const AssetFormSheet({
    super.key,
    required this.controller,
    this.asset,
    this.duplicateFrom,
  });

  final AssetsController controller;
  final AssetModel? asset;
  final AssetModel? duplicateFrom;

  @override
  State<AssetFormSheet> createState() => _AssetFormSheetState();
}

class _AssetFormSheetState extends State<AssetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _valueController;
  late final TextEditingController _descriptionController;
  late final bool _isEditing;
  late final bool _isDuplicating;
  String? _duplicateOriginalTitle;

  AssetCategory _category = AssetCategory.financeiro;
  AssetStatus _status = AssetStatus.pendingReview;
  double _ownership = 100;
  bool _hasProof = false;
  bool _valueUnknown = false;
  String _currency = 'BRL';
  bool _submitting = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  static const List<String> _currencies = ['BRL', 'USD', 'EUR'];

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    final duplicateSource = widget.duplicateFrom;
    final source = asset ?? duplicateSource;

    _isEditing = asset != null;
    _isDuplicating = !_isEditing && duplicateSource != null;
    _duplicateOriginalTitle = duplicateSource?.title.trim();

    _ownership = _normalizeOwnership(source?.ownershipPercentage ?? 100);
    _titleController = TextEditingController(text: source?.title ?? '');
    final initialValue = source?.valueEstimated;
    _valueController = TextEditingController(
      text: initialValue == null
          ? ''
          : _currencyFormat.format(initialValue).trim(),
    );
    _descriptionController =
        TextEditingController(text: source?.description ?? '');
    if (source != null) {
      _category = source.category;
      _currency = source.valueCurrency;
      _valueUnknown = source.valueUnknown;
      _hasProof = source.hasProof;
      _status = source.status;
    }
    if (_isDuplicating) {
      _hasProof = false;
      _status = AssetStatus.pendingReview;
    } else if (!_isEditing) {
      _status = _hasProof ? AssetStatus.active : AssetStatus.pendingReview;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Editar bem' : 'Novo bem',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<AssetCategory>(
                    // ignore: deprecated_member_use
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: AssetCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(_categoryIcon(category), size: 18),
                                const SizedBox(width: 8),
                                Text(category.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _category = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration:
                        const InputDecoration(labelText: 'Título do bem'),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Informe pelo menos 3 caracteres';
                      }
                      if (_isDuplicating &&
                          _duplicateOriginalTitle != null &&
                          value.trim() == _duplicateOriginalTitle) {
                        return 'Altere o título para diferenciar a cópia.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _currency,
                          items: _currencies
                              .map(
                                (code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(labelText: 'Moeda'),
                          onChanged: _valueUnknown || _submitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _currency = value);
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _valueController,
                          enabled: !_valueUnknown,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _CurrencyInputFormatter(locale: 'pt_BR'),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Valor estimado',
                            prefixText: '≈ ${_currency.toUpperCase()} ',
                            helperText:
                                'Usamos máscara automática no formato 0,00.',
                          ),
                          validator: (value) {
                            if (_valueUnknown) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o valor';
                            }
                            final parsed = _parseCurrency(value);
                            if (parsed == null || parsed <= 0) {
                              return 'Digite um valor válido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: _valueUnknown,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Valor desconhecido'),
                    subtitle: const Text(
                        'Tudo bem, você pode preencher depois com calma.'),
                    onChanged: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              _valueUnknown = value;
                              if (value) {
                                _valueController.clear();
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Proporção de posse'),
                          Text('${_ownership.toStringAsFixed(0)}%'),
                        ],
                      ),
                      Slider(
                        value: _ownership,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _ownership = value),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_ownership.round()}%',
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: _hasProof,
                    onChanged: _submitting
                        ? null
                        : (value) => _handleHasProofChanged(value ?? false),
                    title: const Text('Já possui comprovante?'),
                    subtitle: const Text(
                        'Assim que salvar, recomendamos subir o arquivo.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.white12,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      title: const Text('Campos avançados'),
                      subtitle: const Text(
                        'Status inicial e notas internas',
                      ),
                      children: [
                        DropdownButtonFormField<AssetStatus>(
                          // ignore: deprecated_member_use
                          value: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: AssetStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _status = value);
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Notas internas',
                            helperText:
                                'Compartilhe instruções ou detalhes relevantes',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _handleSubmit,
                      icon: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(isEditing
                              ? Icons.save_rounded
                              : Icons.check_circle),
                      label: Text(
                          isEditing ? 'Salvar alterações' : 'Cadastrar bem'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _normalizeOwnership(double value) {
    final clamped = value.clamp(0, 100);
    final steps = (clamped / 5).round();
    return (steps * 5).toDouble();
  }

  double? _parseCurrency(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final sanitized = input.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  void _handleHasProofChanged(bool next) {
    setState(() => _hasProof = next);
    if (!_isEditing && !_isDuplicating) {
      setState(() {
        _status = next ? AssetStatus.active : AssetStatus.pendingReview;
      });
    }
  }

  IconData _categoryIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.imoveis:
        return Icons.home_work_outlined;
      case AssetCategory.veiculos:
        return Icons.directions_car_filled_outlined;
      case AssetCategory.financeiro:
        return Icons.account_balance_wallet_outlined;
      case AssetCategory.cripto:
        return Icons.currency_bitcoin;
      case AssetCategory.dividas:
        return Icons.warning_amber_outlined;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final value = _parseCurrency(_valueController.text);

    final input = AssetInput(
      category: _category,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      valueEstimated: _valueUnknown ? null : value,
      valueCurrency: _currency,
      valueUnknown: _valueUnknown,
      ownershipPercentage: _ownership,
      hasProof: _hasProof,
      status: _status,
    );

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEditing) {
        await widget.controller.updateAsset(widget.asset!.id, input);
        messenger.showSnackBar(
          const SnackBar(content: Text('Bem atualizado com sucesso.')),
        );
      } else {
        await widget.controller.createAsset(input);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isDuplicating
                  ? 'Cópia criada. Revise o novo registro.'
                  : 'Bem cadastrado com sucesso.',
            ),
          ),
        );
      }
      if (mounted) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(true);
        }
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class AssetFormEntryScreen extends StatefulWidget {
  const AssetFormEntryScreen({super.key});

  @override
  State<AssetFormEntryScreen> createState() => _AssetFormEntryScreenState();
}

class _AssetFormEntryScreenState extends State<AssetFormEntryScreen> {
  bool _hasOpenedSheet = false;
  AssetFormEntryArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasOpenedSheet) return;
    _hasOpenedSheet = true;
    final incoming = ModalRoute.of(context)?.settings.arguments;
    if (incoming is AssetFormEntryArgs) {
      _args = incoming;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final resolvedArgs = _args;
      if (resolvedArgs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fluxo inválido. Reabra a tela a partir de Bens.'),
          ),
        );
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      await showAssetFormSheet(
        context,
        asset: resolvedArgs.asset,
        duplicateFrom: resolvedArgs.duplicateFrom,
        controller: resolvedArgs.controller,
      );
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
    );
  }
}

class AssetFormEntryArgs {
  const AssetFormEntryArgs({
    required this.controller,
    this.asset,
    this.duplicateFrom,
  });

  final AssetsController controller;
  final AssetModel? asset;
  final AssetModel? duplicateFrom;
}

class _CurrencyInputFormatter extends TextInputFormatter {
  _CurrencyInputFormatter({this.locale = 'pt_BR'})
      : _numberFormat = NumberFormat.currency(
          locale: locale,
          symbol: '',
          decimalDigits: 2,
        );

  final String locale;
  final NumberFormat _numberFormat;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final value = double.parse(digits) / 100;
    final formatted = _numberFormat.format(value).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
