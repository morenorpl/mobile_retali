import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/tugas_service.dart';
import '../../models/task_models.dart';
import 'task_detail_screen.dart';

class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen> {
  late Future<List<TaskSummary>> _future;
  List<TaskSummary>? _tasks;
  Timer? _timer;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // 🔄 AUTO REFRESH (SETIAP 5 DETIK - REALTIME)
  // ============================================
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        try {
          final newData = await TugasService.getTasks();
          
          // Cek apakah ada perubahan data
          if (_hasDataChanged(newData)) {
            print('📝 Data tugas berubah secara realtime, refresh UI...');
            setState(() {
              _tasks = newData;
              // Menggunakan Future.value agar FutureBuilder tidak kembali ke state loading
              _future = Future.value(newData);
            });
          }
        } catch (e) {
          debugPrint('❌ Silent refresh error (tugas): $e');
        }
      }
    });
  }

  bool _hasDataChanged(List<TaskSummary> newData) {
    if (_tasks == null) return true;
    if (_tasks!.length != newData.length) return true;
    
    for (int i = 0; i < newData.length; i++) {
      final newItem = newData[i];
      // Cari item lama berdasarkan ID untuk memastikan perbandingan yang akurat
      final oldItem = _tasks!.firstWhere(
        (t) => t.id == newItem.id, 
        orElse: () => _tasks![i]
      );
      
      if (newItem.status != oldItem.status) return true;
      
      // Cek perubahan status pengerjaan (doneAt) secara presisi
      final newDoneAt = newItem.doneAt;
      final oldDoneAt = oldItem.doneAt;
      
      if ((newDoneAt == null && oldDoneAt != null) ||
          (newDoneAt != null && oldDoneAt == null) ||
          (newDoneAt != null && oldDoneAt != null && 
           newDoneAt.millisecondsSinceEpoch != oldDoneAt.millisecondsSinceEpoch)) {
        return true;
      }
      
      if (newItem.title != oldItem.title) return true;
    }
    
    return false;
  }

  Future<List<TaskSummary>> _load() async {
    try {
      final data = await TugasService.getTasks();
      setState(() {
        _tasks = data;
        _isFirstLoad = false;
      });
      return data;
    } catch (e) {
      debugPrint('❌ ERR LOAD TUGAS: $e');
      setState(() => _isFirstLoad = false);
      return _tasks ?? [];
    }
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Tugas Tour Leader',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF842D62),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
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
        child: RefreshIndicator(
          color: const Color(0xFF842D62),
          onRefresh: _reload,
          child: FutureBuilder<List<TaskSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && _isFirstLoad) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF842D62)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat tugas...',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tasks = _tasks ?? snapshot.data ?? [];
              if (tasks.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Text(
                        'Tidak ada tugas yang tersedia',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final task = tasks[i];

                  final status = task.status.toLowerCase();
                  final bool sedangDibuka = [
                    'sedang_dibuka',
                    'sedang dibuka',
                    'dibuka',
                    'open'
                  ].contains(status);

                  final bool belumDikerjakan = task.doneAt == null;
                  final bool canWork = sedangDibuka && belumDikerjakan;

                  return _TaskCard(
                    data: task,
                    onKerjakan: canWork
                        ? () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  taskId: task.id,
                                  initialTitle: task.title,
                                ),
                              ),
                            );

                            if (result == true) {
                              // Optimistic UI update agar perubahan terasa realtime di HP user
                              setState(() {
                                if (_tasks != null) {
                                  _tasks![i] = _tasks![i].copyWith(doneAt: DateTime.now());
                                  _future = Future.value(_tasks);
                                }
                              });
                              // Validasi data akhir dari server
                              Future.delayed(const Duration(milliseconds: 500), _reload);
                            }
                          }
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ========================= CARD TUGAS ==============================

class _TaskCard extends StatelessWidget {
  final TaskSummary data;
  final VoidCallback? onKerjakan;

  const _TaskCard({required this.data, this.onKerjakan});

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final status = data.status.toLowerCase();

    String waktuLabel;
    Color waktuColor;
    IconData waktuIcon;

    if (status.contains('belum')) {
      waktuLabel = 'Belum dibuka';
      waktuColor = Colors.orange;
      waktuIcon = Icons.schedule_rounded;
    } else if (status.contains('tutup')) {
      waktuLabel = 'Sudah ditutup';
      waktuColor = Colors.red;
      waktuIcon = Icons.lock_clock_rounded;
    } else {
      waktuLabel = 'Sedang dibuka';
      waktuColor = Colors.green;
      waktuIcon = Icons.lock_open_rounded;
    }

    final bool sudahDikerjakan = data.doneAt != null;
    final kerjaLabel = sudahDikerjakan ? 'Sudah dikerjakan' : 'Belum dikerjakan';
    final kerjaColor = sudahDikerjakan ? Colors.green : Colors.red;
    final kerjaIcon = sudahDikerjakan
        ? Icons.check_circle_rounded
        : Icons.pending_actions_rounded;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF842D62).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Color(0xFF842D62),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF333333),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTimelineItem(
                icon: Icons.play_circle_outline_rounded,
                title: 'Dibuka',
                time: _formatTime(data.opensAt),
                date: _formatDate(data.opensAt),
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                icon: Icons.stop_circle_outlined,
                title: 'Berakhir',
                time: _formatTime(data.closesAt),
                date: _formatDate(data.closesAt),
              ),
              if (sudahDikerjakan) ...[
                const SizedBox(height: 12),
                _buildTimelineItem(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Selesai',
                  time: _formatTime(data.doneAt!),
                  date: _formatDate(data.doneAt!),
                  isCompleted: true,
                ),
              ],

              const SizedBox(height: 16),

              // Status badges
              Row(
                children: [
                  _statusBadge(kerjaLabel, kerjaColor, kerjaIcon),
                  const SizedBox(width: 8),
                  _statusBadge(waktuLabel, waktuColor, waktuIcon),
                ],
              ),
              const SizedBox(height: 16),

              if (onKerjakan != null)
                ElevatedButton.icon(
                  onPressed: onKerjakan,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Kerjakan Tugas',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF842D62),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String time,
    required String date,
    bool isCompleted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isCompleted ? Colors.green : const Color(0xFF842D62).withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF842D62),
            ),
          ),
        ),
      ],
    );
  }
}