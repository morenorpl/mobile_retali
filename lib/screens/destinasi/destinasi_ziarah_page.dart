import 'package:flutter/material.dart';
import 'destinasi.dart';
import 'maps_helper.dart';

class DestinasiZiarahPage extends StatefulWidget {
  const DestinasiZiarahPage({super.key});

  @override
  State<DestinasiZiarahPage> createState() => _DestinasiZiarahPageState();
}

class _DestinasiZiarahPageState extends State<DestinasiZiarahPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Destinasi> _filter(List<Destinasi> list) {
    if (_q.isEmpty) return list;
    final q = _q.toLowerCase();
    return list.where((d) => d.nama.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Destinasi Ziarah',
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
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Makkah'),
            Tab(text: 'Madinah'),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              return Column(
                children: [
                  // 🔍 Search box
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari destinasi…',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFF842D62).withOpacity(0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),

                  // Info jumlah destinasi
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: const Color(0xFF842D62).withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Builder(
                          builder: (context) {
                            final currentItems = _tab.index == 0
                                ? _filter(destinasiMakkah)
                                : _filter(destinasiMadinah);
                            return Text(
                              '${currentItems.length} destinasi ditemukan',
                              style: TextStyle(
                                color: const Color(0xFF842D62).withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _GridDestinasiResponsive(
                          items: _filter(destinasiMakkah),
                          city: 'Makkah',
                          screenWidth: screenWidth,
                        ),
                        _GridDestinasiResponsive(
                          items: _filter(destinasiMadinah),
                          city: 'Madinah',
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GridDestinasiResponsive extends StatelessWidget {
  final List<Destinasi> items;
  final String city;
  final double screenWidth;

  const _GridDestinasiResponsive({
    required this.items,
    required this.city,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada destinasi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Tentukan childAspectRatio berdasarkan lebar layar
    double aspectRatio;
    if (screenWidth < 360) {
      aspectRatio = 0.9;
    } else if (screenWidth < 400) {
      aspectRatio = 1.1;
    } else if (screenWidth < 500) {
      aspectRatio = 1.2;
    } else {
      aspectRatio = 1.4;
    }

    // Tentukan jumlah kolom berdasarkan ukuran layar
    int crossAxisCount;
    if (screenWidth < 400) {
      crossAxisCount = 2;
    } else if (screenWidth < 800) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (_, i) {
          final d = items[i];
          return GestureDetector(
            onTap: () => openMapsTo(d.lat, d.lng, label: d.nama),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF842D62).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      color: Color(0xFF842D62),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    d.nama,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF842D62).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      city,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF842D62).withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
