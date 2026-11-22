import 'dart:convert';

class PatientProfile {
  final String name;
  final String age;
  final String fitzpatrickType;
  final String city;

  const PatientProfile({
    this.name = 'Clinical Patient',
    this.age = '34',
    this.fitzpatrickType = 'Type III',
    this.city = 'Faisalabad',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'fitzpatrickType': fitzpatrickType,
      'city': city,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      name: map['name'] as String? ?? 'Clinical Patient',
      age: map['age'] as String? ?? '34',
      fitzpatrickType: map['fitzpatrickType'] as String? ?? 'Type III',
      city: map['city'] as String? ?? 'Faisalabad',
    );
  }

  String toJson() => json.encode(toMap());

  factory PatientProfile.fromJson(String source) =>
      PatientProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  PatientProfile copyWith({
    String? name,
    String? age,
    String? fitzpatrickType,
    String? city,
  }) {
    return PatientProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      fitzpatrickType: fitzpatrickType ?? this.fitzpatrickType,
      city: city ?? this.city,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientProfile &&
        other.name == name &&
        other.age == age &&
        other.fitzpatrickType == fitzpatrickType &&
        other.city == city;
  }

  @override
  int get hashCode => Object.hash(name, age, fitzpatrickType, city);
}
