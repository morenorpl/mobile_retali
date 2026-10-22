class ItineraryItem {
  final int id;
  final int sequence;
  final String? time;   // format "HH:mm"
  final String? title;
  final String? content;

  ItineraryItem({
    required this.id,
    required this.sequence,
    this.time,
    this.title,
    this.content,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> j) => ItineraryItem(
        id: j['id'] as int,
        sequence: (j['sequence'] ?? 1) as int,
        time: (j['time'] as String?)?.substring(0, 5), // "08:30:00" -> "08:30"
        title: j['title'] as String?,
        content: j['content'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequence': sequence,
        'time': time,
        'title': title,
        'content': content,
      };

  ItineraryItem copyWith({
    int? id,
    int? sequence,
    String? time,
    String? title,
    String? content,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      sequence: sequence ?? this.sequence,
      time: time ?? this.time,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}


class ItineraryDay {
  final int id;
  final int dayNumber;
  final String? city;
  final String? date; // "YYYY-MM-DD"
  final List<ItineraryItem> items;

  ItineraryDay({
    required this.id,
    required this.dayNumber,
    this.city,
    this.date,
    this.items = const [],
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> j) => ItineraryDay(
        id: j['id'] as int,
        dayNumber: j['day_number'] as int,
        city: j['city'] as String?,
        date: j['date'] as String?,
        items: (j['items'] as List? ?? const [])
            .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_number': dayNumber,
        'city': city,
        'date': date,
        'items': items.map((e) => e.toJson()).toList(),
      };

  ItineraryDay copyWith({
    int? id,
    int? dayNumber,
    String? city,
    String? date,
    List<ItineraryItem>? items,
  }) {
    return ItineraryDay(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      city: city ?? this.city,
      date: date ?? this.date,
      items: items ?? this.items,
    );
  }
}


class Itinerary {
  final int id;
  final String title;
  final String? startDate; // "YYYY-MM-DD"
  final String? endDate;   // "YYYY-MM-DD"
  final String tourLeader;
  final List<ItineraryDay> days;
  final int? daysCount;    // <--- penting untuk durasi

  Itinerary({
    required this.id,
    required this.title,
    required this.tourLeader,
    this.startDate,
    this.endDate,
    this.days = const [],
    this.daysCount,
  });

  factory Itinerary.fromJson(Map<String, dynamic> j) => Itinerary(
        id: j['id'] as int,
        title: j['title'] as String,
        startDate: j['start_date'] as String?,
        endDate: j['end_date'] as String?,

        // Laravel kirim "tour_leader_name"
        tourLeader: (j['tour_leader_name'] ?? j['tour_leader'] ?? '') as String,

        days: (j['days'] as List? ?? const [])
            .map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
            .toList(),

        // sinkron dari Laravel
        daysCount: j['days_count'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_date': startDate,
        'end_date': endDate,
        'tour_leader_name': tourLeader,
        'days': days.map((e) => e.toJson()).toList(),
        'days_count': daysCount,
      };

  Itinerary copyWith({
    int? id,
    String? title,
    String? startDate,
    String? endDate,
    String? tourLeader,
    List<ItineraryDay>? days,
    int? daysCount,
  }) {
    return Itinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tourLeader: tourLeader ?? this.tourLeader,
      days: days ?? this.days,
      daysCount: daysCount ?? this.daysCount,
    );
  }
}
