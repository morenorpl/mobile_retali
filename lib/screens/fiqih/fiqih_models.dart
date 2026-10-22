class FiqhEntry {
  final String title;              // Judul sub-topik
  final List<String> bullets;      // Poin ringkas (praktis)
  final List<String> dalil;        // Dalil (ayat/hadits/atsar)
  final List<String> notes;        // Catatan & khilaf
  const FiqhEntry({
    required this.title,
    required this.bullets,
    this.dalil = const [],
    this.notes = const [],
  });
}

class FiqhSection {
  final String id;                 // unik per section
  final String title;              // Judul tab
  final List<FiqhEntry> entries;   // Daftar materi
  const FiqhSection({
    required this.id,
    required this.title,
    required this.entries,
  });
}
