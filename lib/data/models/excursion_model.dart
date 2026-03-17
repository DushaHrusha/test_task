import 'package:flutter/material.dart';
import 'package:test_task/data/models/card_data.dart';

class Excursion extends CardData {
  final int numberReviews;
  final int duration; // в часах
  final DateTime startingTime;
  final List<String> transfer;
  final List<String> sights;
  final List<String> notIncluded;
  final String takeWithYou;
  final City? city;
  final DateTime? cachedAt;

  // Дополнительные поля для разных валют
  final double? priceUsd;
  final double? priceEur;
  final double? priceRub;
  final int? maxParticipants;

  const Excursion({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.price,
    required super.rating,
    required super.iconServices,
    required this.numberReviews,
    required this.duration,
    required this.startingTime,
    required this.transfer,
    required this.sights,
    required this.notIncluded,
    required this.takeWithYou,
    this.city,
    this.cachedAt,
    this.priceUsd,
    this.priceEur,
    this.priceRub,
    this.maxParticipants,
  });

  // ✅ Метод валидации
  bool isValid() {
    return id > 0 &&
        title.isNotEmpty &&
        imageUrl.isNotEmpty &&
        price > 0 &&
        duration > 0;
  }

  // ✅ copyWith с поддержкой cachedAt
  Excursion copyWith({
    int? id,
    String? title,
    String? description,
    List<String>? imageUrl,
    double? price,
    double? rating,
    int? numberReviews,
    int? duration,
    DateTime? startingTime,
    List<String>? transfer,
    List<String>? sights,
    List<String>? notIncluded,
    String? takeWithYou,
    List<String>? iconServices,
    City? city,
    DateTime? cachedAt,
    double? priceUsd,
    double? priceEur,
    double? priceRub,
    int? maxParticipants,
  }) {
    return Excursion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      numberReviews: numberReviews ?? this.numberReviews,
      duration: duration ?? this.duration,
      startingTime: startingTime ?? this.startingTime,
      transfer: transfer ?? this.transfer,
      sights: sights ?? this.sights,
      notIncluded: notIncluded ?? this.notIncluded,
      takeWithYou: takeWithYou ?? this.takeWithYou,
      iconServices: iconServices ?? this.iconServices,
      city: city ?? this.city,
      cachedAt: cachedAt ?? this.cachedAt,
      priceUsd: priceUsd ?? this.priceUsd,
      priceEur: priceEur ?? this.priceEur,
      priceRub: priceRub ?? this.priceRub,
      maxParticipants: maxParticipants ?? this.maxParticipants,
    );
  }

  factory Excursion.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseStartTime(dynamic startTime) {
      if (startTime == null) {
        return DateTime.now();
      }

      // Если это строка времени вида "23:04" или "23:04:00"
      if (startTime is String) {
        // Проверяем формат
        if (startTime.contains('T') || startTime.contains(' ')) {
          // Полная дата-время: "2025-12-05T23:04:00" или "2025-12-05 23:04:00"
          return DateTime.parse(startTime);
        } else if (startTime.contains(':')) {
          // Только время: "23:04" или "23:04:00"
          final parts = startTime.split(':');
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

          // Создаём DateTime с сегодняшней датой и указанным временем
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }

      return DateTime.now();
    }

    return Excursion(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: (json['images'] as List?)?.cast<String>() ?? [],
      price: parseDouble(json['price']),
      rating: parseDouble(json['rating']),
      numberReviews: json['number_reviews'] as int? ?? 0,
      duration: json['duration_hours'] as int? ?? 0,
      startingTime: parseStartTime(json['start_time']),
      transfer: (json['transfer_options'] as List?)?.cast<String>() ?? [],
      sights: (json['sights'] as List?)?.cast<String>() ?? [],
      notIncluded: (json['not_included'] as List?)?.cast<String>() ?? [],
      takeWithYou: json['take_with_you'] as String? ?? '',
      iconServices: (json['included_services'] as List?)?.cast<String>() ?? [],
      city:
          json['city'] != null
              ? City.fromJson(json['city'] as Map<String, dynamic>)
              : null,
      cachedAt:
          json['cached_at'] != null
              ? DateTime.parse(json['cached_at'] as String)
              : null,
      priceUsd: (json['price_usd'] as num?)?.toDouble(),
      priceEur: (json['price_eur'] as num?)?.toDouble(),
      priceRub: (json['price_rub'] as num?)?.toDouble(),
      maxParticipants: json['max_participants'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'rating': rating,
      'number_reviews': numberReviews,
      'duration': duration,
      'starting_time': startingTime.toIso8601String(),
      'transfer': transfer,
      'sights': sights,
      'not_included': notIncluded,
      'take_with_you': takeWithYou,
      'icon_services': iconServices,
      'city': city?.toJson(),
      'cached_at': cachedAt?.toIso8601String(),
      'price_usd': priceUsd,
      'price_eur': priceEur,
      'price_rub': priceRub,
      'max_participants': maxParticipants,
    };
  }

  List<IconData> get iconDataList {
    return iconServices.map((iconName) {
      return _getIconFromName(iconName);
    }).toList();
  }

  IconData _getIconFromName(String name) {
    switch (name.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'food':
        return Icons.wifi;
      case 'internet':
        return Icons.pool;
      case 'water':
        return Icons.spa;
      case 'gym':
        return Icons.fitness_center;
      case 'guide':
        return Icons.local_parking;
      case 'transfer':
        return Icons.beach_access;
      case 'bar':
        return Icons.local_bar;
      default:
        return Icons.help_outline;
    }
  }
}

class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'] as int, name: json['name'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
