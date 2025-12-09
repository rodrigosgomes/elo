import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../models/document_model.dart';
import 'documents_controller.dart';

/// Sheet modal para upload de documentos.
class UploadDocumentSheet extends StatefulWidget {
  const UploadDocumentSheet({super.key});

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<PlatformFile> _selectedFiles = [];
  final Set<String> _selectedTags = {};
  DateTime? _expiresAt;
  bool _wifiOnly = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _totalSize => _selectedFiles.fold(0, (sum, f) => sum + (f.size));

  bool get _hasOversizedFile =>
      _selectedFiles.any((f) => f.size > 10 * 1024 * 1024);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      color: Color(0xFF5590A8),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Upload Criptografado',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Seus arquivos serão criptografados antes de sair do dispositivo.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Seletor de arquivos
                _buildFilePicker(),
                const SizedBox(height: 20),

                // Campo de título
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Nome amigável'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe um nome' : null,
                ),
                const SizedBox(height: 16),

                // Descrição
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Descrição (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Tags
                Text(
                  'Tags',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DocumentTags.recommended.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF5590A8).withOpacity(0.3),
                      checkmarkColor: const Color(0xFF5590A8),
                      labelStyle: TextStyle(
                        color:
                            selected ? const Color(0xFF5590A8) : Colors.white70,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                if (_selectedTags.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selecione pelo menos uma tag',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Data de validade
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calendar_today,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  title: Text(
                    _expiresAt == null
                        ? 'Validade (opcional)'
                        : 'Expira em: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _expiresAt != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () => setState(() => _expiresAt = null),
                        )
                      : null,
                  onTap: _pickExpiryDate,
                ),
                const SizedBox(height: 12),

                // Toggle Wi-Fi only
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _wifiOnly,
                  onChanged: (val) => setState(() => _wifiOnly = val),
                  title: const Text(
                    'Enviar apenas via Wi-Fi',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Aguarda conexão Wi-Fi para economizar dados',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  activeColor: const Color(0xFF5590A8),
                ),
                const SizedBox(height: 24),

                // Erro
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botão de upload
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5590A8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Criptografar e Enviar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hasOversizedFile
                ? Colors.red.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFiles.isEmpty ? Icons.cloud_upload : Icons.check_circle,
              size: 48,
              color: _selectedFiles.isEmpty
                  ? Colors.white.withOpacity(0.5)
                  : const Color(0xFF5590A8),
            ),
            const SizedBox(height: 12),
            if (_selectedFiles.isEmpty) ...[
              Text(
                'Toque para selecionar arquivos',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF, JPG, PNG, DOCX • Até 10MB cada',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Text(
                '${_selectedFiles.length} arquivo(s) selecionado(s)',
                style: const TextStyle(
                  color: Color(0xFF5590A8),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${_formatSize(_totalSize)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              if (_hasOversizedFile) ...[
                const SizedBox(height: 8),
                Text(
                  'Alguns arquivos excedem 10MB',
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5590A8)),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedFiles.isNotEmpty &&
      !_hasOversizedFile &&
      _selectedTags.isNotEmpty &&
      !_isLoading;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
        // Preencher título com nome do primeiro arquivo se vazio
        if (_titleController.text.isEmpty && _selectedFiles.isNotEmpty) {
          final name = _selectedFiles.first.name;
          _titleController.text = name.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5590A8),
              surface: Color(0xFF1A1F24),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final controller = context.read<DocumentsController>();

      final inputs = _selectedFiles.map((file) {
        return DocumentUploadInput(
          documentInput: DocumentInput(
            title: _selectedFiles.length > 1
                ? file.name.replaceAll(RegExp(r'\.[^.]+$'), '')
                : _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            tags: _selectedTags.toList(),
            expiresAt: _expiresAt,
            networkPolicy:
                _wifiOnly ? NetworkPolicy.wifiOnly : NetworkPolicy.any,
          ),
          fileName: file.name,
          fileBytes: file.bytes?.toList() ?? [],
        );
      }).toList();

      await controller.startUpload(inputs: inputs);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${inputs.length} documento(s) adicionado(s) à fila de upload',
            ),
            backgroundColor: const Color(0xFF5590A8),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao iniciar upload: $e';
        _isLoading = false;
      });
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
