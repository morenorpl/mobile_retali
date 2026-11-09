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
      if (!mounted) return;
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(
                              "Gagal memuat data: ${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Coba Lagi"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mainColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final scans = snapshot.data ?? [];

                if (scans.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _type == HistoryType.koper ? Icons.luggage_outlined : Icons.badge_outlined,
                              size: 56,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Belum ada riwayat scan ${_type == HistoryType.koper ? 'koper' : 'paspor'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tarik ke bawah untuk memuat ulang",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: scans.length,
                    itemBuilder: (context, index) {
                      final scan =
                          scans[index] as Map<String, dynamic>;

                      final kode = _type == HistoryType.koper
                          ? (scan['koper_code'] ?? scan['kode_koper'])
                          : (scan['passport_number'] ?? scan['passport']);

                      final nama = scan['owner_name'] ?? scan['nama_pemilik'] ?? '-';
                      final phone = scan['owner_phone'] ?? scan['phone'] ?? scan['nomor_telepon'] ?? '-';
                      final kloter = scan['kloter'] ?? '-';
                      final waktu = scan['scanned_at'] ?? scan['created_at'] ?? '';

                      return _ModernCard(
                        type: _type,
                        kode: kode?.toString() ?? '-',
                        nama: nama.toString(),
                        kloter: kloter.toString(),
                        waktu: waktu.toString(),
                        formatDateTime: _formatDateTime,
                        onDelete: () => _deleteItem(scan),
                        onDetail: () {
                          if (_type == HistoryType.koper) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KoperDetailScreen(
                                  kode: kode?.toString() ?? '',
                                  namaPemilik: nama.toString(),
                                  phone: phone.toString(),
                                  timestamp: waktu.toString(),
                                  kloter: kloter.toString(),
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PasporDetailScreen(
                                  passportNumber: kode?.toString() ?? '',
                                  namaPemilik: nama.toString(),
                                  phone: phone.toString(),
                                  timestamp: waktu.toString(),
                                  kloter: kloter.toString(),
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
