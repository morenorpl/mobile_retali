import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/tugas_service.dart';
import '../../services/api_service.dart';
import '../../models/checklist_models.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final int checklistId;
  final String? title;

  const ChecklistDetailScreen({
    super.key,
    required this.checklistId,
    this.title,
  });

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  late Future<ChecklistDetail> _future;

  final _namaCtl = TextEditingController();
  final _kloterCtl = TextEditingController();

  late List<CkAns?> _answers;
  late List<TextEditingController> _notes;

  bool _submitted = false;
  bool _loading = false;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _future = TugasService.getChecklistDetail(widget.checklistId).then((
      detail,
    ) async {
      _answers = List<CkAns?>.filled(detail.questions.length, null);
      _notes = List.generate(
        detail.questions.length,
        (_) => TextEditingController(),
      );
      _submitted = detail.submitted;

      await _prefillKloter();
      await _loadProgress(widget.checklistId, detail);

      for (final n in _notes) {
        n.addListener(() => _saveProgress(widget.checklistId));
      }

      return detail;
    });
  }

  Future<void> _prefillKloter() async {
    try {
      final info = await ApiService.getUserInfo();
      final kloterObj = info['kloter'];

      if (kloterObj is Map<String, dynamic>) {
        _kloterCtl.text = kloterObj['name'] ?? kloterObj['nama'] ?? '';
      } else {
        _kloterCtl.text = kloterObj?.toString() ?? '';
      }
    } catch (_) {}
  }

  // ================= LOCAL DRAFT =================
  Future<void> _saveProgress(int checklistId) async {
    if (_submitted) return;

    final prefs = await SharedPreferences.getInstance();
    final data = {
      'namaPetugas': _namaCtl.text,
      'answers': _answers
          .map((a) => a != null ? ckAnsToString(a) : null)
          .toList(),
      'notes': _notes.map((n) => n.text).toList(),
    };

    prefs.setString('checklist_progress_$checklistId', jsonEncode(data));
  }

  Future<void> _loadProgress(int checklistId, ChecklistDetail detail) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('checklist_progress_$checklistId');
    if (saved == null) return;

    final data = jsonDecode(saved);
    _namaCtl.text = data['namaPetugas'] ?? '';

    final answers = (data['answers'] as List?) ?? [];
    final notes = (data['notes'] as List?) ?? [];

    for (int i = 0; i < detail.questions.length; i++) {
      if (i < answers.length && answers[i] != null) {
        _answers[i] = stringToCkAns(answers[i]);
      }
      if (i < notes.length) {
        _notes[i].text = notes[i];
      }
    }
  }

  @override
  void dispose() {
    _namaCtl.dispose();
    _kloterCtl.dispose();
    for (final n in _notes) {
      n.dispose();
    }
    super.dispose();
  }

  // ================= VALIDASI =================
  bool _canSubmit(ChecklistDetail d) {
    if (d.status != 'dibuka' || d.submitted || _submitted) return false;
    if (_namaCtl.text.trim().isEmpty) return false;
    if (_answers.any((a) => a == null)) return false;

    for (int i = 0; i < _answers.length; i++) {
      final a = _answers[i];
      if (a == CkAns.tidak || a == CkAns.rekan) {
        if (_notes[i].text.trim().isEmpty) return false;
      }
    }
    return true;
  }

  // ================= SUBMIT =================
  Future<void> _submit(ChecklistDetail d) async {
    setState(() => _loading = true);

    final payload = <Map<String, dynamic>>[];
    for (int i = 0; i < d.questions.length; i++) {
      payload.add({
        'checklist_question_id': d.questions[i].id,
        'value': ckAnsToString(_answers[i]!),
        if (_notes[i].text.trim().isNotEmpty) 'note': _notes[i].text.trim(),
      });
    }

    try {
      await TugasService.submitChecklist(
        checklistId: d.id,
        namaPetugas: _namaCtl.text.trim(),
        answers: payload,
      );

      final prefs = await SharedPreferences.getInstance();
      prefs.remove('checklist_progress_${d.id}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _submitted = true;
        _loading = false;
      });

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChecklistDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title ?? 'Checklist',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF842D62),
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              elevation: 2,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF842D62)),
                  const SizedBox(height: 16),
                  Text(
                    'Mengambil data...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? 'Checklist'),
              backgroundColor: const Color(0xFF842D62),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Terjadi Kesalahan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = TugasService.getChecklistDetail(
                            widget.checklistId,
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF842D62),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? 'Checklist'),
              backgroundColor: const Color(0xFF842D62),
            ),
            body: const Center(child: Text('Data tidak ditemukan')),
          );
        }

        final d = snapshot.data!;
        final locked = d.submitted || _submitted || d.status != 'dibuka';
        final canSubmit = _canSubmit(d);
        final questions = d.questions;
        final totalQuestions = questions.length;
        final answeredCount = _answers.where((a) => a != null).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title ?? d.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white, // ✅ INI
              ),
            ),
            backgroundColor: const Color(0xFF842D62),
            elevation: 2,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
          ),

          floatingActionButton: canSubmit && !_loading
              ? FloatingActionButton.extended(
                  onPressed: () => _submit(d),
                  backgroundColor: const Color(0xFF9C3A6B),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'Selesaikan Checklist',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          body: Column(
            children: [
              if (totalQuestions > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Progress Checklist',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: answeredCount / totalQuestions,
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFF842D62),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$answeredCount/$totalQuestions',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF842D62),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(locked),
                    const SizedBox(height: 24),
                    Text(
                      'Pertanyaan Checklist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(totalQuestions, (i) {
                      return _QuestionCard(
                        index: i + 1,
                        text: questions[i].text,
                        value: _answers[i],
                        noteCtl: _notes[i],
                        enabled: !locked,
                        onChanged: (v) {
                          setState(() => _answers[i] = v);
                          _saveProgress(widget.checklistId);
                        },
                      );
                    }),
                    if (_submitted || d.submitted)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Checklist Telah Diselesaikan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Checklist ini sudah dikirim dan tidak dapat diubah lagi',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(bool locked) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Petugas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _namaCtl,
              label: 'Nama Petugas',
              enabled: !locked,
              icon: Icons.person_outline,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _kloterCtl,
              label: 'Kloter',
              enabled: false,
              icon: Icons.group_outlined,
            ),
            if (!locked && _namaCtl.text.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Harap isi nama petugas sebelum mengisi checklist',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    IconData? icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 18, color: Colors.grey[600]),
            if (icon != null) const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? Colors.grey[800] : Colors.grey[600],
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF842D62),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: enabled
                ? (_) {
                    setState(() {});
                    _saveProgress(widget.checklistId);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

// ================= QUESTION CARD =================
class _QuestionCard extends StatelessWidget {
  final int index;
  final String text;
  final CkAns? value;
  final TextEditingController noteCtl;
  final bool enabled;
  final ValueChanged<CkAns?> onChanged;

  const _QuestionCard({
    required this.index,
    required this.text,
    required this.value,
    required this.noteCtl,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showNote = value == CkAns.tidak || value == CkAns.rekan;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF842D62),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status indicator untuk jawaban
            if (value != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(value!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(value!).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(value!),
                      size: 14,
                      color: _getStatusColor(value!),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(value!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(value!),
                      ),
                    ),
                  ],
                ),
              ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _option('Sudah', CkAns.sudah),
                _option('Tidak terpenuhi', CkAns.tidak),
                _option('Dikerjakan oleh rekan', CkAns.rekan),
              ],
            ),

            if (showNote) ...[
              const SizedBox(height: 16),
              Text(
                'Catatan ${value == CkAns.tidak ? "(alasan tidak terpenuhi)" : "(nama rekan)"}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtl,
                enabled: enabled,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: value == CkAns.tidak
                      ? 'Ketikkan alasan mengapa tidak terpenuhi...'
                      : 'Ketikkan nama rekan yang mengerjakan...',
                  filled: true,
                  fillColor: enabled ? Colors.white : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF842D62),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: enabled
                      ? Icon(Icons.edit_note, color: Colors.grey[500], size: 20)
                      : null,
                ),
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Catatan wajib diisi untuk pilihan ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(String label, CkAns v) {
    final selected = value == v;
    final color = _getStatusColor(v);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
            fontSize: 13,
          ),
        ),
        selected: selected,
        onSelected: enabled ? (_) => onChanged(v) : null,
        backgroundColor: Colors.grey[100],
        selectedColor: color,
        side: BorderSide(color: selected ? color : Colors.grey[300]!, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Color _getStatusColor(CkAns ans) {
    switch (ans) {
      case CkAns.sudah:
        return Colors.green;
      case CkAns.tidak:
        return Colors.orange;
      case CkAns.rekan:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(CkAns ans) {
    switch (ans) {
      case CkAns.sudah:
        return Icons.check_circle;
      case CkAns.tidak:
        return Icons.warning;
      case CkAns.rekan:
        return Icons.people;
    }
  }

  String _getStatusText(CkAns ans) {
    switch (ans) {
      case CkAns.sudah:
        return 'Sudah dikerjakan';
      case CkAns.tidak:
        return 'Tidak terpenuhi';
      case CkAns.rekan:
        return 'Dikerjakan rekan';
    }
  }
}
