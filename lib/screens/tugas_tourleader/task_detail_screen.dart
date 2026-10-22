import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/tugas_service.dart' as svc;
import '../../models/task_models.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  final String? initialTitle;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    this.initialTitle,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Future<TaskDetail> _future;
  late List<bool> _checked;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TaskDetail> _load() async {
    final detail = await svc.TugasService.getTaskDetail(widget.taskId);

    final answeredIds =
        await svc.TugasService.getTaskAnswers(widget.taskId);

    _checked = detail.questions
        .map((q) => answeredIds.contains(q.id))
        .toList();

    return detail;
  }

  bool _allChecked() =>
      _checked.isNotEmpty && _checked.every((e) => e);

  Future<void> _toggleAnswer({
    required int index,
    required int questionId,
    required bool value,
    required bool actionable,
  }) async {
    if (!actionable) return;

    setState(() => _checked[index] = value);

    try {
      if (value) {
        await svc.TugasService.markQuestionDone(
          widget.taskId,
          questionId,
        );
      } else {
        await svc.TugasService.markQuestionUndone(
          widget.taskId,
          questionId,
        );
      }
    } catch (e) {
      // rollback UI
      setState(() => _checked[index] = !value);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final doneAt =
          await svc.TugasService.markTaskDone(widget.taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Selesai • ${DateFormat('dd/MM/y HH:mm').format(doneAt)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _statusChip(TaskDetail d) {
    if (d.doneAt != null) {
      return _chip(
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        title: 'Sudah Dikerjakan',
        subtitle: DateFormat('dd/MM/y HH:mm')
            .format(d.doneAt!.toLocal()),
      );
    }

    if (d.status == 'ditutup') {
      return _chip(
        icon: Icons.lock_clock_rounded,
        color: Colors.red,
        title: 'Sudah Ditutup',
      );
    }

    return _chip(
      icon: Icons.access_time_rounded,
      color: Colors.orange,
      title: 'Belum Dikerjakan',
    );
  }

  Widget _chip({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskDetail>(
      future: _future,
      builder: (context, snapshot) {
        final title =
            snapshot.data?.title ?? widget.initialTitle ?? 'Detail Tugas';

        final actionable = snapshot.hasData &&
            snapshot.data!.status == 'dibuka' &&
            snapshot.data!.doneAt == null;

        final canSubmit = actionable && _allChecked();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(child: Text('${snapshot.error}')),
          );
        }

        final d = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: const Color(0xFF842D62),
            foregroundColor: Colors.white,
          ),
          floatingActionButton: canSubmit && !_submitting
            ? FloatingActionButton.extended(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Selesaikan Tugas'),
                backgroundColor: const Color(0xFF842D62),
                foregroundColor: Colors.white, // ⬅️ INI KUNCINYA
            )
              : null,

          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8F4F7),
                  Color(0xFFF0E8EF),
                ],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _statusChip(d),
                ),

                if (actionable) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.checklist_rtl_rounded,
                          color: Color(0xFF842D62),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Progress: ${_checked.where((c) => c).length}/${_checked.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF842D62),
                            ),
                          ),
                        ),
                        if (_allChecked())
                          Icon(Icons.verified_rounded,
                              color: Colors.green[700]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(
                      value: _checked.isNotEmpty
                          ? _checked.where((c) => c).length /
                              _checked.length
                          : 0,
                      backgroundColor: Colors.grey[300],
                      color: const Color(0xFF842D62),
                      minHeight: 6,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: d.questions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final q = d.questions[i];
                      final sudah = _checked[i];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${q.orderNo}. ${q.text}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _actionButton(
                                      label: 'Sudah',
                                      selected: sudah,
                                      onTap: actionable
                                          ? () => _toggleAnswer(
                                                index: i,
                                                questionId: q.id,
                                                value: true,
                                                actionable: actionable,
                                              )
                                          : null,
                                      primary: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _actionButton(
                                      label: 'Belum',
                                      selected: !sudah,
                                      onTap: actionable
                                          ? () => _toggleAnswer(
                                                index: i,
                                                questionId: q.id,
                                                value: false,
                                                actionable: actionable,
                                              )
                                          : null,
                                      primary: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      },
    );
  }

  Widget _actionButton({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    required bool primary,
  }) {
    return Material(
      color: selected
          ? const Color(0xFF842D62)
          : primary
              ? const Color(0xFF842D62).withOpacity(0.1)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : primary
                      ? const Color(0xFF842D62)
                      : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
