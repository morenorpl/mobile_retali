import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/checklist_models.dart';
import '../../services/tugas_service.dart';
import '../../services/supabase_service.dart';

class ChecklistFormScreen extends StatefulWidget {
  final dynamic checklistId;
  final ChecklistDetail detail;
  final bool readOnly;

  const ChecklistFormScreen({
    super.key,
    required this.checklistId,
    required this.detail,
    this.readOnly = false,
  });

  @override
  State<ChecklistFormScreen> createState() => _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends State<ChecklistFormScreen> {
  late List<CkAns?> _answers;
  late List<TextEditingController> _notes;
  bool _loading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _answers = List<CkAns?>.filled(widget.detail.questions.length, null);
    _notes = List.generate(
      widget.detail.questions.length,
      (_) => TextEditingController(),
    );

    _initAnswers();
  }

  Future<void> _initAnswers() async {
    if (widget.readOnly || widget.detail.submitted) {
      await _loadSubmittedAnswers();
    } else {
      await _loadProgress();
      for (final n in _notes) {
        n.addListener(_saveProgress);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final n in _notes) {
      n.dispose();
    }
    super.dispose();
  }

  // ================= LOAD PROGRESS / ANSWERS =================
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('checklist_progress_${widget.checklistId}');
    if (saved == null) return;

    try {
      final data = jsonDecode(saved);
      final answers = (data['answers'] as List?) ?? [];
      final notes = (data['notes'] as List?) ?? [];

      for (int i = 0; i < widget.detail.questions.length; i++) {
        if (i < answers.length && answers[i] != null) {
          _answers[i] = stringToCkAns(answers[i]);
        }
        if (i < notes.length) {
          _notes[i].text = notes[i]?.toString() ?? '';
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSubmittedAnswers() async {
    final client = SupabaseService.client;
    if (client == null) {
      await _loadProgress();
      return;
    }

    try {
      final assignmentId = widget.detail.assignmentId ?? widget.detail.id.toString();
      final rows = await client
          .from('checklist_answers')
          .select('*')
          .eq('assignment_id', assignmentId);

      final rowMap = <String, dynamic>{};
      for (final r in rows) {
        final qId = r['question_id']?.toString();
        if (qId != null) rowMap[qId] = r;
      }

      for (int i = 0; i < widget.detail.questions.length; i++) {
        final q = widget.detail.questions[i];
        final ansRow = rowMap[q.id.toString()];
        if (ansRow != null) {
          final rawAns = (ansRow['answer'] ?? '').toString();
          if (rawAns.startsWith('sudah')) {
            _answers[i] = CkAns.sudah;
          } else if (rawAns.startsWith('tidak')) {
            _answers[i] = CkAns.tidak;
            final match = RegExp(r'Catatan:\s*(.*)\)?').firstMatch(rawAns);
            if (match != null) {
              _notes[i].text = match.group(1)?.replaceAll(')', '').trim() ?? '';
            }
          } else if (rawAns.startsWith('rekan')) {
            _answers[i] = CkAns.rekan;
            final match = RegExp(r'Catatan:\s*(.*)\)?').firstMatch(rawAns);
            if (match != null) {
              _notes[i].text = match.group(1)?.replaceAll(')', '').trim() ?? '';
            }
          }
        }
      }
    } catch (_) {
      await _loadProgress();
    }
  }

  Future<void> _saveProgress() async {
    if (widget.readOnly || widget.detail.submitted || _isSaving) return;

    _isSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'answers': _answers.map((a) => a != null ? ckAnsToString(a) : null).toList(),
        'notes': _notes.map((n) => n.text).toList(),
      };
      await prefs.setString(
        'checklist_progress_${widget.checklistId}',
        jsonEncode(data),
      );
    } catch (_) {}
    _isSaving = false;
  }

  // ================= VALIDASI =================
  bool get _canSubmit {
    if (widget.readOnly || widget.detail.submitted) return false;
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
  Future<void> _submit() async {
    if (!_canSubmit || _loading) return;

    setState(() => _loading = true);

    final payload = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.detail.questions.length; i++) {
      payload.add({
        'checklist_question_id': widget.detail.questions[i].id,
        'value': ckAnsToString(_answers[i]!),
        if (_notes[i].text.trim().isNotEmpty) 'note': _notes[i].text.trim(),
      });
    }

    try {
      // Ambil nama petugas dari session/SharedPreferences secara otomatis
      final prefs = await SharedPreferences.getInstance();
      final namaPetugas = prefs.getString('name') ??
          prefs.getString('username') ??
          prefs.getString('nama') ??
          'Petugas';

      await TugasService.submitChecklist(
        checklistId: widget.detail.id,
        namaPetugas: namaPetugas,
        answers: payload,
      );

      // Hapus local draft
      await prefs.remove('checklist_progress_${widget.checklistId}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checklist berhasil diselesaikan 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim checklist: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.detail.questions;
    final totalQuestions = questions.length;
    final answeredCount = _answers.where((a) => a != null).length;
    final locked = widget.readOnly || widget.detail.submitted;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.readOnly ? 'Jawaban Checklist' : 'Kerjakan Checklist',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: !locked
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_loading ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF842D62),
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 2,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Selesaikan Checklist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        color: const Color(0xFFF9FAFB),
        child: Column(
          children: [
            // Progress Bar
            if (totalQuestions > 0 && !locked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress Checklist',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '$answeredCount/$totalQuestions Terjawab',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF842D62),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalQuestions > 0
                                  ? (answeredCount / totalQuestions)
                                  : 0,
                              backgroundColor: const Color(0xFFF3E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF842D62),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Question List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (locked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Checklist ini sudah selesai dan hanya dapat dilihat (read-only).',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ...List.generate(totalQuestions, (i) {
                    return _QuestionCard(
                      index: i + 1,
                      text: questions[i].text,
                      value: _answers[i],
                      noteCtl: _notes[i],
                      enabled: !locked,
                      onChanged: (v) {
                        setState(() => _answers[i] = v);
                        _saveProgress();
                      },
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _option('Sudah', CkAns.sudah),
              if (!enabled && value == CkAns.tidak)
                _option('Tidak terpenuhi', CkAns.tidak),
              if (!enabled && value == CkAns.rekan)
                _option('Dikerjakan oleh rekan', CkAns.rekan),
            ],
          ),

          if (showNote) ...[
            const SizedBox(height: 14),
            Text(
              'Catatan ${value == CkAns.tidak ? "(alasan tidak terpenuhi)" : "(nama rekan)"}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtl,
              enabled: enabled,
              maxLines: 2,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: value == CkAns.tidak
                    ? 'Ketikkan alasan mengapa tidak terpenuhi...'
                    : 'Ketikkan nama rekan yang mengerjakan...',
                filled: true,
                fillColor: enabled ? Colors.white : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF842D62),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            if (enabled)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Catatan wajib diisi untuk pilihan ini',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFD97706),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _option(String label, CkAns v) {
    final selected = value == v;
    final color = _getStatusColor(v);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: enabled ? () => onChanged(selected ? null : v) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CkAns ans) {
    switch (ans) {
      case CkAns.sudah:
        return const Color(0xFF16A34A);
      case CkAns.tidak:
        return const Color(0xFFEA580C);
      case CkAns.rekan:
        return const Color(0xFF2563EB);
    }
  }
}
