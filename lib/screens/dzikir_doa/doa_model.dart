class Doa {
  final int id;
  final String judul;
  final String arab;
  final String latin;
  final String arti;
  final String kategori; // contoh: 'Safar', 'Makkah', 'Masjid', 'Thawaf', 'Sa\'i', 'Umum'

  const Doa({
    required this.id,
    required this.judul,
    required this.arab,
    required this.latin,
    required this.arti,
    required this.kategori,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'judul': judul,
        'arab': arab,
        'latin': latin,
        'arti': arti,
        'kategori': kategori,
      };
}
