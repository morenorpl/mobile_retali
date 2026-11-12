class ItineraryItem {
  final dynamic id;
  final int sequence;
  final String? time; // format "HH:mm"
  final String? title;
  final String? content;
  final String? location;

  ItineraryItem({
    required this.id,
    required this.sequence,
    this.time,
    this.title,
    this.content,
    this.location,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> j) {
    final rawTime = (j['activity_time'] ?? j['time'])?.toString();
    String? timeFormatted;
    if (rawTime != null && rawTime.isNotEmpty) {
      timeFormatted = rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime;
    }

    return ItineraryItem(
      id: j['id'] ?? '',
      sequence: (j['sort_order'] ?? j['sequence'] ?? 1) as int,
      time: timeFormatted,
      title: j['title'] as String?,
      content: (j['description'] ?? j['content']) as String?,
      location: j['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sequence': sequence,
        'sort_order': sequence,
        'time': time,
        'activity_time': time,
        'title': title,
        'content': content,
        'description': content,
        'location': location,
      };

  ItineraryItem copyWith({
    dynamic id,
    int? sequence,
    String? time,
    String? title,
    String? content,
    String? location,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      sequence: sequence ?? this.sequence,
      time: time ?? this.time,
      title: title ?? this.title,
      content: content ?? this.content,
      location: location ?? this.location,
    );
  }
}

class ItineraryDay {
  final dynamic id;
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

  factory ItineraryDay.fromJson(Map<String, dynamic> j) {
    final rawItems = j['itinerary_activities'] ?? j['items'] ?? j['activities'];
    final itemsList = (rawItems as List? ?? const [])
        .map((e) => ItineraryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Urutkan item berdasarkan sequence/sort_order atau time
    itemsList.sort((a, b) {
      if (a.sequence != b.sequence) {
        return a.sequence.compareTo(b.sequence);
      }
      return (a.time ?? '').compareTo(b.time ?? '');
    });

    String? city = (j['city'] ?? j['title'])?.toString();
    if ((city == null || city.isEmpty) && itemsList.isNotEmpty) {
      city = itemsList.first.location;
    }

    return ItineraryDay(
      id: j['id'] ?? '',
      dayNumber: (j['day_number'] ?? j['dayNumber'] ?? 1) as int,
      city: city,
      date: (j['activity_date'] ?? j['date'])?.toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_number': dayNumber,
        'city': city,
        'date': date,
        'activity_date': date,
        'items': items.map((e) => e.toJson()).toList(),
        'itinerary_activities': items.map((e) => e.toJson()).toList(),
      };

  ItineraryDay copyWith({
    dynamic id,
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
  final dynamic id;
  final String title;
  final String? startDate; // "YYYY-MM-DD"
  final String? endDate; // "YYYY-MM-DD"
  final String tourLeader;
  final List<ItineraryDay> days;
  final int? daysCount;

  Itinerary({
    required this.id,
    required this.title,
    required this.tourLeader,
    this.startDate,
    this.endDate,
    this.days = const [],
    this.daysCount,
  });

  factory Itinerary.fromJson(Map<String, dynamic> j) {
    final rawDays = j['itinerary_days'] ?? j['days'];
    final daysList = (rawDays as List? ?? const [])
        .map((e) => ItineraryDay.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Urutkan days berdasarkan day_number
    daysList.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    // Ekstrak nama Tour Leader dari relasi profiles atau field langsung
    String tlName = '';
    final profiles = j['profiles'];
    if (profiles is Map) {
      tlName = (profiles['username'] ?? profiles['name'] ?? '').toString();
    }
    if (tlName.isEmpty) {
      tlName = (j['tour_leader_name'] ?? j['tour_leader'] ?? '') as String;
    }

    final rawDaysCount = j['days_count'] ?? (daysList.isNotEmpty ? daysList.length : null);
    final daysCount = rawDaysCount != null ? (rawDaysCount as num).toInt() : null;

    return Itinerary(
      id: j['id'] ?? '',
      title: (j['title'] ?? 'Itinerary Perjalanan') as String,
      startDate: (j['start_date'] ?? j['startDate'])?.toString(),
      endDate: (j['end_date'] ?? j['endDate'])?.toString(),
      tourLeader: tlName.isNotEmpty ? tlName : 'Tour Leader',
      days: daysList,
      daysCount: daysCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start_date': startDate,
        'end_date': endDate,
        'tour_leader_name': tourLeader,
        'days': days.map((e) => e.toJson()).toList(),
        'itinerary_days': days.map((e) => e.toJson()).toList(),
        'days_count': daysCount,
      };

  Itinerary copyWith({
    dynamic id,
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
