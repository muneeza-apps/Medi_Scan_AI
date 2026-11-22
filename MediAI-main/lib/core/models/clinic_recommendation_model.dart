import 'dart:convert';

class ClinicRecommendation {
  final String id;
  final String name;
  final String specialty;
  final String address;
  final String city;
  final double rating;
  final String contactNumber;
  final double latitude;
  final double longitude;
  final String mapsUrl;
  final double? distanceKm;

  const ClinicRecommendation({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    this.city = '',
    required this.rating,
    String? contactNumber,
    String? phone,
    required this.latitude,
    required this.longitude,
    required this.mapsUrl,
    this.distanceKm,
  }) : contactNumber = contactNumber ?? phone ?? '';

  String get phone => contactNumber;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'address': address,
      'city': city,
      'rating': rating,
      'contactNumber': contactNumber,
      'phone': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'mapsUrl': mapsUrl,
      if (distanceKm != null) 'distanceKm': distanceKm,
    };
  }

  factory ClinicRecommendation.fromMap(Map<String, dynamic> map) {
    return ClinicRecommendation(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Dermatology Clinic',
      specialty: map['specialty'] as String? ?? 'Dermatology & Skin Laser Clinic',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      contactNumber: map['contactNumber'] as String? ?? map['phone'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      mapsUrl: map['mapsUrl'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ClinicRecommendation.fromJson(String source) =>
      ClinicRecommendation.fromMap(json.decode(source) as Map<String, dynamic>);

  ClinicRecommendation copyWith({
    String? id,
    String? name,
    String? specialty,
    String? address,
    String? city,
    double? rating,
    String? contactNumber,
    String? phone,
    double? latitude,
    double? longitude,
    String? mapsUrl,
    double? distanceKm,
  }) {
    return ClinicRecommendation(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      address: address ?? this.address,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      contactNumber: contactNumber ?? phone ?? this.contactNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicRecommendation &&
        other.id == id &&
        other.name == name &&
        other.specialty == specialty &&
        other.address == address &&
        other.city == city &&
        other.rating == rating &&
        other.contactNumber == contactNumber &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.mapsUrl == mapsUrl &&
        other.distanceKm == distanceKm;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        specialty,
        address,
        city,
        rating,
        contactNumber,
        latitude,
        longitude,
        mapsUrl,
        distanceKm,
      );
}
