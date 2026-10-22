class PraktisEntry {
  final String title;            // judul sub-topik
  final List<String> bullets;    // poin praktis
  final List<String> notes;      // catatan/FAQ singkat (opsional)
  const PraktisEntry({
    required this.title,
    required this.bullets,
    this.notes = const [],
  });
}

class PraktisSection {
  final String id;               // unik per section
  final String title;            // judul tab
  final List<PraktisEntry> entries;
  const PraktisSection({
    required this.id,
    required this.title,
    required this.entries,
  });
}
