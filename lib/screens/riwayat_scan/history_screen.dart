import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_retali/services/api_service.dart';
import 'koper_detail_screen.dart';
import 'paspor_detail_screen.dart';

enum HistoryType { koper, paspor }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryType _type = HistoryType.koper;
  late Future<List<dynamic>> _futureScans;

  static const Color _mainColor = Color(0xFF842D62);
  static const Color _pageBg = Color(0xFFF8F6F8);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureScans = _type == HistoryType.koper
        ? ApiService.getScans()
        : ApiService.getPassportScans();
    setState(() {});
  }

  String _formatDateTime(String v) {
    try {
      final dt = DateTime.parse(v).toLocal();
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return v;
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> scan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Hapus Data?"),
        content: const Text("Data ini akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final id = scan['id'];
    bool success = false;

    if (_type == HistoryType.koper) {
      success = await ApiService.deleteKoper(id);
    } else {
      success = await ApiService.deletePassport(id);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil dihapus")),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _mainColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'History Scan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// SEGMENTED TOGGLE
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                _segmentButton("Koper", HistoryType.koper),
                _segmentButton("Paspor", HistoryType.paspor),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// LIST
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureScans,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final scans = snapshot.data ?? [];

                if (scans.isEmpty) {
                  return const Center(
                    child: Text(
                      "Belum ada riwayat scan",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan =
                          scans[index] as Map<String, dynamic>;

                      final kode = _type ==
                              HistoryType.koper
                          ? scan['koper_code']
                          : scan['passport_number'];

                      return _ModernCard(
                        type: _type,
                        kode: kode?.toString() ?? '-',
                        nama:
                            scan['owner_name'] ?? '-',
                        kloter:
                            scan['kloter'] ?? '-',
                        waktu:
                            scan['scanned_at'] ?? '',
                        formatDateTime:
                            _formatDateTime,
                        onDelete: () =>
                            _deleteItem(scan),
                        onDetail: () {
                          if (_type ==
                              HistoryType.koper) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    KoperDetailScreen(
                                  kode: kode ?? '',
                                  namaPemilik:
                                      scan['owner_name'] ??
                                          '-',
                                  phone:
                                      scan['owner_phone'] ??
                                          '-',
                                  timestamp:
                                      scan['scanned_at'] ??
                                          '',
                                  kloter:
                                      scan['kloter'] ??
                                          '-',
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PasporDetailScreen(
                                  passportNumber:
                                      kode ?? '',
                                  namaPemilik:
                                      scan['owner_name'] ??
                                          '-',
                                  phone:
                                      scan['owner_phone'] ??
                                          '-',
                                  timestamp:
                                      scan['scanned_at'] ??
                                          '',
                                  kloter:
                                      scan['kloter'] ??
                                          '-',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(String text, HistoryType type) {
    final bool selected = _type == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _type = type);
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(
              vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _mainColor
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final HistoryType type;
  final String kode;
  final String nama;
  final String kloter;
  final String waktu;
  final VoidCallback onDetail;
  final VoidCallback onDelete;
  final String Function(String) formatDateTime;

  const _ModernCard({
    required this.type,
    required this.kode,
    required this.nama,
    required this.kloter,
    required this.waktu,
    required this.onDetail,
    required this.onDelete,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final isKoper = type == HistoryType.koper;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isKoper
              ? [
                  const Color(0xFF842D62),
                  const Color(0xFF5C1C3B)
                ]
              : [
                  const Color(0xFF1F4E79),
                  const Color(0xFF163E61)
                ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                kode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                ),
                onPressed: onDelete,
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            nama,
            style: const TextStyle(
                color: Colors.white70),
          ),
          Text(
            "Kloter: $kloter",
            style: const TextStyle(
                color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            formatDateTime(waktu),
            style: const TextStyle(
                color: Colors.white60),
          ),
          const SizedBox(height: 14),
          Align(
            alignment:
                Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white,
                foregroundColor:
                    Colors.black,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
              ),
              onPressed: onDetail,
              child:
                  const Text("Detail"),
            ),
          )
        ],
      ),
    );
  }
}
