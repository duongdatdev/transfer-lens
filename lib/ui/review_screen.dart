import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/transaction.dart';
import '../domain/transfer_parser.dart';
import '../services/image_storage.dart';
import '../services/ocr_service.dart';
import '../state/expense_store.dart';
import 'app_theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    this.existing,
    this.parsed,
    this.ocr,
    this.sourcePath,
  });
  final TransferTransaction? existing;
  final ParsedTransfer? parsed;
  final OcrResult? ocr;
  final String? sourcePath;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final form = GlobalKey<FormState>();
  final categoryField = GlobalKey<FormFieldState<ExpenseCategory>>();
  late final TextEditingController amount;
  late final TextEditingController sender;
  late final TextEditingController recipient;
  late final TextEditingController description;
  late final TextEditingController reference;
  DateTime? date;
  ExpenseCategory? category;
  TransactionDirection direction = TransactionDirection.expense;
  bool confirmed = false;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final parsed = widget.parsed;
    amount = TextEditingController(
      text: (existing?.amount ?? parsed?.amount)?.toString() ?? '',
    );
    sender = TextEditingController(
      text: existing?.sender ?? parsed?.sender ?? '',
    );
    recipient = TextEditingController(
      text: existing?.recipient ?? parsed?.recipient ?? '',
    );
    description = TextEditingController(
      text: existing?.description ?? parsed?.description ?? '',
    );
    reference = TextEditingController(
      text: existing?.reference ?? parsed?.reference ?? '',
    );
    date = existing?.date ?? parsed?.date;
    category = existing?.category ?? parsed?.category;
    direction = existing?.direction ?? TransactionDirection.expense;
    confirmed = existing != null;
  }

  @override
  void dispose() {
    for (final controller in [
      amount,
      sender,
      recipient,
      description,
      reference,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.sourcePath ?? widget.existing?.imagePath;
    final parsed = widget.parsed;
    final rawText = widget.ocr?.text ?? widget.existing?.rawText ?? '';
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null
                ? 'Kiểm tra giao dịch'
                : 'Chi tiết giao dịch',
          ),
          actions: [
            if (widget.existing != null)
              IconButton(
                tooltip: 'Xóa giao dịch',
                onPressed: saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: ContentWidth(
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (image != null) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showImage(image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 168,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(image),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, _, _) => const Center(
                                child: Text('Ảnh không còn khả dụng'),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in, size: 18),
                                    SizedBox(width: 4),
                                    Text('Xem ảnh'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.ocr != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Chip(
                        avatar: Icon(Icons.lock_outline, size: 18),
                        label: Text('OCR trên thiết bị'),
                      ),
                      Chip(label: Text('${widget.ocr!.milliseconds} ms')),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (parsed != null && parsed.warnings.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      parsed.warnings.join('\n\n'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Thông tin giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SegmentedButton<TransactionDirection>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionDirection.expense,
                      label: Text('Khoản chi'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionDirection.income,
                      label: Text('Khoản thu'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {direction},
                  onSelectionChanged: saving
                      ? null
                      : (value) => setState(() => direction = value.single),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('amount'),
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền (VND)',
                    suffixText: '₫',
                    helperText: 'Ví dụ: 150000 hoặc 150.000',
                  ),
                  validator: (value) =>
                      TransferParser.parseVnd(value ?? '') == null
                      ? 'Nhập số tiền VND hợp lệ lớn hơn 0.'
                      : null,
                ),
                const SizedBox(height: 16),
                FormField<DateTime>(
                  validator: (_) =>
                      date == null ? 'Chọn ngày giao dịch.' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100, 12, 31),
                                  helpText: 'Ngày giao dịch',
                                );
                                if (picked != null && mounted) {
                                  setState(() => date = picked);
                                  field.didChange(picked);
                                }
                              },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          date == null
                              ? 'Chọn ngày giao dịch'
                              : formatDate(date!),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('sender'),
                  controller: sender,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Người gửi (nếu có)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('recipient'),
                  controller: recipient,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Người nhận (nếu có)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('description'),
                  controller: description,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung chuyển khoản',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExpenseCategory>(
                  key: categoryField,
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: ExpenseCategory.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => category = value),
                  validator: (value) =>
                      value == null ? 'Chọn danh mục trước khi lưu.' : null,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final suggestion = TransferParser().suggestCategory(
                      description.text,
                    );
                    if (suggestion.$1 == null) {
                      return const Text(
                        'Nội dung chưa đủ rõ để phân loại. Bạn hãy tự chọn danh mục.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.$2!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: saving
                              ? null
                              : () {
                                  setState(() => category = suggestion.$1);
                                  categoryField.currentState?.didChange(
                                    suggestion.$1,
                                  );
                                },
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: Text('Gợi ý: ${suggestion.$1!.label}'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reference,
                  decoration: const InputDecoration(
                    labelText: 'Mã giao dịch (nếu có)',
                  ),
                ),
                const SizedBox(height: 16),
                if (rawText.isNotEmpty)
                  Card(
                    child: ExpansionTile(
                      title: const Text('Văn bản OCR gốc'),
                      subtitle: const Text('Đối chiếu thông tin trước khi lưu'),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [SelectableText(rawText)],
                    ),
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: confirmed,
                  onChanged: saving
                      ? null
                      : (value) => setState(() => confirmed = value ?? false),
                  title: const Text(
                    'Tôi đã kiểm tra số tiền và xác nhận giao dịch hoàn tất.',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('save'),
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Đang lưu…' : 'Lưu giao dịch'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showImage(String path) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: const Text('Ảnh giao dịch')),
        body: InteractiveViewer(
          minScale: .5,
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(path),
              errorBuilder: (_, _, _) => const Text('Ảnh không còn khả dụng'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!form.currentState!.validate()) return;
    if (!confirmed) {
      setState(() => error = 'Vui lòng xác nhận đã kiểm tra giao dịch.');
      return;
    }
    final store = context.read<ExpenseStore>();
    final reviewedAmount = TransferParser.parseVnd(amount.text)!;
    final reviewedDate = date!;
    final reviewedDirection = direction;
    final reviewedCategory = category!;
    final reviewedSender = sender.text.trim();
    final reviewedRecipient = recipient.text.trim();
    final reviewedDescription = description.text.trim();
    final reviewedReference = reference.text.trim();
    TransferTransaction buildValue({StoredImage? image}) => TransferTransaction(
      id: widget.existing?.id,
      amount: reviewedAmount,
      date: reviewedDate,
      direction: reviewedDirection,
      category: reviewedCategory,
      sender: reviewedSender,
      recipient: reviewedRecipient,
      description: reviewedDescription,
      reference: reviewedReference,
      rawText: widget.ocr?.text ?? widget.existing?.rawText ?? '',
      imagePath: image?.path ?? widget.existing?.imagePath,
      thumbnailPath: image?.thumbnailPath ?? widget.existing?.thumbnailPath,
      ocrMilliseconds:
          widget.ocr?.milliseconds ?? widget.existing?.ocrMilliseconds,
    );
    if (store.duplicateOf(buildValue()) != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Có thể bị trùng'),
          content: const Text(
            'Đã có giao dịch cùng mã hoặc thông tin tương tự. Bạn có muốn lưu thêm?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vẫn lưu'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    StoredImage? cached;
    try {
      if (widget.sourcePath != null) {
        cached = await store.images.cache(widget.sourcePath!);
      }
      await store.save(buildValue(image: cached));
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (cached != null) {
        try {
          await store.images.remove(cached.path);
          await store.images.remove(cached.thumbnailPath);
        } catch (_) {
          // Preserve the save error even if private cache cleanup also fails.
        }
      }
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Không thể lưu. Kiểm tra dung lượng thiết bị và thử lại.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final store = context.read<ExpenseStore>();
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text('Giao dịch và ảnh đã lưu sẽ bị xóa khỏi thiết bị.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (delete != true || !mounted) return;
    setState(() => saving = true);
    try {
      await store.delete(widget.existing!);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Không thể xóa giao dịch. Vui lòng thử lại.';
        });
      }
    }
  }
}
