// data/models/apartment.dart
import 'package:test_task/data/models/card_data.dart';

class Apartment extends CardData {
  final int numberReviews;
  final String address;
  final DateTime? cachedAt;

  const Apartment({
    required super.id,
    required super.title,
    required super.imageUrl,
    required super.description,
    required super.price,
    required super.iconServices,
    required super.rating,
    required this.numberReviews,
    required this.address,
    this.cachedAt,
  });

  factory Apartment.fromJson(Map<String, dynamic> json) {
    try {
      // Безопасный парсинг image_url (проверяем оба варианта: 'images' и 'image_url')
      List<String> parseImageUrl(dynamic value) {
        if (value == null) return [];
        if (value is List) {
          return value
              .where((e) => e != null && e.toString().isNotEmpty)
              .map((e) => e.toString())
              .toList();
        }
        if (value is String && value.isNotEmpty) {
          return [value];
        }
        return [];
      }

      // Безопасный парсинг icon_services
      List<String> parseIconServices(dynamic value) {
        if (value == null) return [];
        if (value is List) {
          return value
              .where((e) => e != null && e.toString().isNotEmpty)
              .map((e) => e.toString())
              .toList();
        }
        return [];
      }

      // Безопасный парсинг числовых значений
      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      // ✅ Проверяем оба варианта: 'images' и 'image_url'
      final images = parseImageUrl(json['images'] ?? json['image_url']);

      return Apartment(
        id: parseInt(json['id']),
        title: json['title']?.toString() ?? '',
        imageUrl: images,
        description: json['description']?.toString() ?? '',
        price: parseDouble(json['price']),
        iconServices: parseIconServices(json['icon_services']),
        rating: parseDouble(json['rating']),
        numberReviews: parseInt(json['number_reviews']),
        address: json['address']?.toString() ?? '',
        cachedAt:
            json['cached_at'] != null
                ? DateTime.tryParse(json['cached_at'].toString())
                : null,
      );
    } catch (e) {
      print('❌ Error parsing Apartment from JSON: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl, // ✅ Сохраняем как image_url
      'description': description,
      'price': price,
      'icon_services': iconServices,
      'rating': rating,
      'number_reviews': numberReviews,
      'address': address,
      'cached_at': cachedAt?.toIso8601String(),
    };
  }

  // ✅ Добавляем метод валидации
  bool isValid() {
    return id > 0 &&
        title.isNotEmpty &&
        imageUrl.isNotEmpty &&
        imageUrl.every((url) => url.isNotEmpty);
  }

  Apartment copyWith({
    int? id,
    String? title,
    List<String>? imageUrl,
    String? description,
    double? price,
    List<String>? iconServices,
    double? rating,
    int? numberReviews,
    String? address,
    DateTime? cachedAt,
  }) {
    return Apartment(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      iconServices: iconServices ?? this.iconServices,
      rating: rating ?? this.rating,
      numberReviews: numberReviews ?? this.numberReviews,
      address: address ?? this.address,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [...super.props, numberReviews, address, cachedAt];
}
