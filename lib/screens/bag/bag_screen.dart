import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_main_bottom_bar.dart';

/// Mirrors ui/screens/bag/BagScreen.kt's document library core — add
/// documents by title/category/subject/link, open external links, delete.
/// File upload, in-app PDF/Word viewers, and the external Koutoubi WebView
/// browser from the original screen are not yet wired to the new backend.
class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final _repo = AppRepository.instance;
  bool _loading = true;
  String? _error;
  List<BagDocument> _documents = [];
  String _categoryFilter = 'الكل';

  static const _categories = ['ملفات PDF', 'ملفات Word', 'صور', 'مستندات تعليمية', 'أوراق عمل', 'كتب مدرسية'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _repo.getBagDocuments();
      setState(() => _documents = docs);
    } catch (_) {
      setState(() => _error = 'تعذر تحميل الحقيبة. تحقق من اتصال الخادم.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BagDocument> get _filtered =>
      _categoryFilter == 'الكل' ? _documents : _documents.where((d) => d.category == _categoryFilter).toList();

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final subjectController = TextEditingController();
    String category = _categories.first;
    String fileType = 'PDF';

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إضافة مستند جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان المستند')),
                const SizedBox(height: 10),
                const Text('التصنيف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 10),
                TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'المادة (اختياري)')),
                const SizedBox(height: 10),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'رابط المصدر (اختياري)'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                const Text('نوع الملف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  initialValue: fileType,
                  items: ['PDF', 'DOCX', 'IMG'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setDialogState(() => fileType = v ?? fileType),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة')),
          ],
        ),
      ),
    );

    if (saved == true && titleController.text.trim().isNotEmpty) {
      try {
        await _repo.createBagDocument(BagDocument(
          id: 0,
          title: titleController.text.trim(),
          category: category,
          subject: subjectController.text.trim(),
          fileType: fileType,
          sourceUrl: urlController.text.trim().isNotEmpty ? urlController.text.trim() : null,
        ));
        _load();
      } catch (_) {
        _showError('تعذر إضافة المستند');
      }
    }
  }

  Future<void> _openDocument(BagDocument doc) async {
    if (doc.sourceUrl == null || doc.sourceUrl!.isEmpty) {
      _showError('لا يوجد رابط مرتبط بهذا المستند');
      return;
    }
    final uri = Uri.tryParse(doc.sourceUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('تعذر فتح الرابط');
    }
  }

  Future<void> _confirmDelete(BagDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف «${doc.title}»؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _repo.deleteBagDocument(doc.id);
        _load();
      } catch (_) {
        _showError('تعذر حذف المستند');
      }
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  IconData _iconFor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'DOCX':
        return Icons.description;
      case 'IMG':
        return Icons.image;
      default:
        return Icons.picture_as_pdf;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      appBar: AppBar(title: const Text('الحقيبة والمكتبة التعليمية')),
      bottomNavigationBar: const AppMainBottomBar(current: BottomTab.bag),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مستند'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          children: ['الكل', ..._categories]
                              .map((c) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: ChoiceChip(
                                      label: Text(c, style: const TextStyle(fontSize: 12)),
                                      selected: _categoryFilter == c,
                                      onSelected: (_) => setState(() => _categoryFilter = c),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? const Center(child: Text('لا توجد مستندات في هذا التصنيف'))
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.95,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final doc = _filtered[i];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _openDocument(doc),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Icon(_iconFor(doc.fileType), color: AppColors.primaryBlue, size: 26),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF5350)),
                                                  onPressed: () => _confirmDelete(doc),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(doc.title,
                                                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const Spacer(),
                                            Text(doc.category,
                                                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
