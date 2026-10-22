import 'package:flutter/material.dart';

class PersiapanDiniyahScreen extends StatelessWidget {
  PersiapanDiniyahScreen({Key? key}) : super(key: key);

  final List<PersiapanItem> persiapanList = [
    PersiapanItem(
      title: "Jamaah Umrah Tamu Allah",
      image: "assets/diniyah/Jamaah Umrah Tamu Allah.png",
      description: "Orang yang berumrah dianggap sebagai tamu Allah SWT.",
    ),
    PersiapanItem(
      title: "Bersabar selama perjalanan",
      image: "assets/diniyah/Bersabar.png",
      description: "Perjalanan umrah memerlukan kesabaran.",
    ),
    PersiapanItem(
      title: "Ikhlas dalam ibadah",
      image: "assets/diniyah/Ikhlas.png",
      description: "Ibadah harus dilandasi dengan keikhlasan.",
    ),
    PersiapanItem(
      title: "Meneladani Nabi saat Umrah",
      image: "assets/diniyah/Teladan.png",
      description: "Mengikuti tata cara umrah sesuai sunnah Nabi.",
    ),
    PersiapanItem(
      title: "Jangan berdebat dengan sesama",
      image: "assets/diniyah/Jangan Berdebat.png",
      description: "Menghindari perdebatan selama umrah.",
    ),
    PersiapanItem(
      title: "Jangan maksiat agar umrah mabrur",
      image: "assets/diniyah/Hindari Maksiat Agar Mabrur.png",
      description: "Menjaga diri dari maksiat agar umrah diterima.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C1C3B), Color(0xFF7B1F48)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Persiapan Diniyah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Keutamaan Umrah
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C1C3B), Color(0xFF7B1F48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "🌙 Keutamaan Umrah",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Image.asset(
                    "assets/diniyah/Keutamaan Umrah.png",
                    height: 60,
                  ),
                ],
              ),
            ),

            // Grid item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: persiapanList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  return PersiapanCard(persiapan: persiapanList[index]);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PersiapanItem {
  final String title;
  final String image;
  final String description;

  PersiapanItem({
    required this.title,
    required this.image,
    required this.description,
  });
}

class PersiapanCard extends StatelessWidget {
  final PersiapanItem persiapan;

  const PersiapanCard({Key? key, required this.persiapan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF7B1F48).withOpacity(0.3),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(persiapan.title),
              content: Text(persiapan.description),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1F48), Color(0xFF5C1C3B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                persiapan.image,
                height: 55,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  persiapan.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
