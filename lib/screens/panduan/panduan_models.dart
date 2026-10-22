class GuideEntry {
  final String title;
  final List<String> bullets;
  const GuideEntry({required this.title, required this.bullets});
}

class GuideSection {
  final String id;      // unik per section
  final String title;   // judul tab
  final List<GuideEntry> entries;
  const GuideSection({required this.id, required this.title, required this.entries});
}
