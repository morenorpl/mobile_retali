class ProcEntry {
  final String title;
  final List<String> bullets;
  const ProcEntry({required this.title, required this.bullets});
}

class ProcSection {
  final String id;       // unik per section
  final String title;    // judul tab
  final List<ProcEntry> entries;
  const ProcSection({required this.id, required this.title, required this.entries});
}
