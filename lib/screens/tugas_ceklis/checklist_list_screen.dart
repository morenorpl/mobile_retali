import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/tugas_service.dart';
import '../../models/checklist_models.dart';
import 'checklist_detail_screen.dart';
import 'dart:async';

class ChecklistListScreen extends StatefulWidget {
  const ChecklistListScreen({super.key});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen> {
  late Future<List<ChecklistSummary>> _future;
  List<ChecklistSummary> _items = [];
  Timer? _timer;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================
  // 🔄 SILENT AUTO REFRESH (REALTIME)
  // ============================================
  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;

      try {
        final newData = await TugasService.getChecklistList();

        // Hanya update UI jika ada data yang beneran berubah
        if (_hasDataChanged(newData)) {
          print('📝 Data checklist berubah, mengupdate UI...');
          setState(() {
            _items = newData;
            // Penting: Pake Future.value biar FutureBuilder nggak loading lagi
            _future = Future.value(newData);
          });
        }
      } catch (e) {
        debugPrint('⏱️ Auto-refresh error (checklist): $e');
      }
    });
  }

  bool _hasDataChanged(List<ChecklistSummary> newData) {
    if (_items.isEmpty && newData.isEmpty) return false;
    if (_items.length != newData.length) return true;

    for (int i = 0; i < newData.length; i++) {
      final newItem = newData[i];
      // Cari item lama berdasarkan ID
      final oldItem = _items.firstWhere(
        (t) => t.id == newItem.id,
        orElse: () => _items[i],
      );

      if (newItem.status != oldItem.status) return true;
      if (newItem.submitted != oldItem.submitted) return true;

      // Cek perubahan waktu selesai secara presisi
      if (newItem.doneAt?.millisecondsSinceEpoch !=
          oldItem.doneAt?.millisecondsSinceEpoch) {
        return true;
      }
    }
    return false;
  }

  Future<List<ChecklistSummary>> _loadData() async {
    try {
      final data = await TugasService.getChecklistList();
      _items = data;
      _isFirstLoad = false;
      return data;
    } catch (e) {
      _isFirstLoad = false;
      debugPrint('❌ ERR LOAD CHECKLIST: $e');
      return _items;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Checklist',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4F7), Color(0xFFF0E8EF)],
          ),
        ),
        child: RefreshIndicator(
          color: const Color(0xFF842D62),
          onRefresh: _reload,
          child: FutureBuilder<List<ChecklistSummary>>(
            future: _future,
            builder: (context, snapshot) {
              // Spinner cuma muncul pas aplikasi pertama kali dibuka (isFirstLoad)
              // Ganti blok loading di ChecklistListScreen dengan ini:
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _isFirstLoad) {
                return Center(
                  // Hapus 'const' di sini agar TextStyle bisa diproses
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF842D62),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat checklist...',
                        style: TextStyle(
                          color: const Color(
                            0xFF666666,
                          ).withOpacity(0.8), // Mengunci warna abu-abu
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError && _items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Terjadi kesalahan',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _reload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF842D62),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              final displayItems = _items;

              if (displayItems.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist_rtl_rounded,
                            size: 64,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada checklist',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: displayItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _ChecklistCard(
                  data: displayItems[i],
                  onKerjakan: displayItems[i].canWork
                      ? () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChecklistDetailScreen(
                                checklistId: displayItems[i].id,
                                title: displayItems[i].title,
                              ),
                            ),
                          );

                          if (changed == true) {
                            // OPTIMISTIC UI: Langsung ijo-in tanpa nunggu API
                            setState(() {
                              _items[i] = _items[i].copyWith(
                                doneAt: DateTime.now(),
                              );
                              _future = Future.value(_items);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checklist berhasil diselesaikan 🎉',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Trigger refresh data asli dari server
                            _loadData();
                          }
                        }
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ========================= CARD CHECKLIST ==============================
// Tetap pakai UI cantik yang lu kasih, nggak ada yang dipotong

class _ChecklistCard extends StatelessWidget {
  final ChecklistSummary data;
  final VoidCallback? onKerjakan;
  const _ChecklistCard({required this.data, this.onKerjakan});

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    String waktuLabel;
    Color waktuColor;
    IconData waktuIcon;
    if (data.status == 'belum_dibuka') {
      waktuLabel = 'Belum dibuka';
      waktuColor = Colors.orange;
      waktuIcon = Icons.schedule_rounded;
    } else if (data.status == 'ditutup') {
      waktuLabel = 'Sudah ditutup';
      waktuColor = Colors.red;
      waktuIcon = Icons.lock_clock_rounded;
    } else {
      waktuLabel = 'Sedang dibuka';
      waktuColor = Colors.green;
      waktuIcon = Icons.lock_open_rounded;
    }

    String kerjaLabel = data.submitted
        ? 'Sudah dikerjakan'
        : 'Belum dikerjakan';
    Color kerjaColor = data.submitted ? Colors.green : Colors.grey;
    IconData kerjaIcon = data.submitted
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Icons.checklist_rtl_rounded,
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
                title: 'Ditutup',
                time: _formatTime(data.closesAt),
                date: _formatDate(data.closesAt),
              ),
              if (data.doneAt != null) ...[
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
              Row(
                children: [
                  _badge(kerjaLabel, kerjaColor, kerjaIcon),
                  const SizedBox(width: 8),
                  _badge(waktuLabel, waktuColor, waktuIcon),
                ],
              ),
              const SizedBox(height: 16),
              if (onKerjakan != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF842D62).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onKerjakan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF842D62),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kerjakan Checklist',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
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
          color: isCompleted
              ? Colors.green
              : const Color(0xFF842D62).withOpacity(0.7),
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
              Text(
                date,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
