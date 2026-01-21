import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

/// Facility model representing sports venues at UPM
class FacilityModel {
  final String id;
  final String name;
  final String description;
  final FacilityType type;
  final SportType sport;
  final double priceStudent;
  final double pricePublic;
  final int refereeRequired;
  final List<String> subUnits; // For INVENTORY type (e.g., Court 1, Court 2)
  final String? imageUrl;
  final bool isIndoor;
  final bool isActive;
  final Map<String, dynamic>? amenities;
  final GeoPoint? location;

  const FacilityModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.sport,
    required this.priceStudent,
    required this.pricePublic,
    required this.refereeRequired,
    this.subUnits = const [],
    this.imageUrl,
    this.isIndoor = false,
    this.isActive = true,
    this.amenities,
    this.location,
  });

  /// Calculate price based on user type
  double getPrice(bool isStudent) {
    return isStudent ? priceStudent : pricePublic;
  }

  /// Get price label
  String getPriceLabel(bool isStudent) {
    final price = getPrice(isStudent);
    final suffix = type == FacilityType.session ? '/session' : '/hour';
    return 'RM ${price.toStringAsFixed(2)}$suffix';
  }

  /// Check if facility requires weather check (outdoor)
  bool get requiresWeatherCheck => !isIndoor;

  /// Check if facility has multiple bookable units
  bool get hasSubUnits => type == FacilityType.inventory && subUnits.isNotEmpty;

  /// Get total bookable units count
  int get totalUnits => hasSubUnits ? subUnits.length : 1;

  /// Get booking duration in hours based on type
  int get defaultBookingDuration {
    switch (type) {
      case FacilityType.session:
        return 2; // Football: 2-hour sessions
      case FacilityType.inventory:
        return 1; // Futsal/Badminton: hourly
    }
  }

  /// Factory constructor from Firestore
  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: FacilityType.fromCode(data['type'] ?? 'HOURLY'),
      sport: SportType.fromCode(data['sport'] ?? 'FUTSAL'),
      priceStudent: (data['price_student'] ?? 0).toDouble(),
      pricePublic: (data['price_public'] ?? 0).toDouble(),
      refereeRequired: data['referee_required'] ?? 0,
      subUnits: List<String>.from(data['sub_units'] ?? []),
      imageUrl: data['imageUrl'],
      isIndoor: data['isIndoor'] ?? false,
      isActive: data['isActive'] ?? true,
      amenities: data['amenities'],
      location: data['location'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.code,
      'sport': sport.code,
      'price_student': priceStudent,
      'price_public': pricePublic,
      'referee_required': refereeRequired,
      'sub_units': subUnits,
      'imageUrl': imageUrl,
      'isIndoor': isIndoor,
      'isActive': isActive,
      'amenities': amenities,
      'location': location,
    };
  }

  /// Factory for seeding data
  factory FacilityModel.fromSeedJson(Map<String, dynamic> json) {
    GeoPoint? location;
    if (json['location'] != null) {
      final loc = json['location'] as Map<String, dynamic>;
      location = GeoPoint(
        loc['latitude'] as double,
        loc['longitude'] as double,
      );
    }

    return FacilityModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      type: FacilityType.fromCode(json['type']),
      sport: SportType.fromCode(json['sport']),
      priceStudent: (json['price_student'] ?? 0).toDouble(),
      pricePublic: (json['price_public'] ?? 0).toDouble(),
      refereeRequired: json['referee_required'] ?? 0,
      subUnits: List<String>.from(json['sub_units'] ?? []),
      isIndoor: json['isIndoor'] ?? json['name'].toString().contains('Indoor'),
      isActive: true,
      location: location,
    );
  }

  FacilityModel copyWith({
    String? name,
    String? description,
    FacilityType? type,
    SportType? sport,
    double? priceStudent,
    double? pricePublic,
    int? refereeRequired,
    List<String>? subUnits,
    String? imageUrl,
    bool? isIndoor,
    bool? isActive,
    Map<String, dynamic>? amenities,
    GeoPoint? location,
  }) {
    return FacilityModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      sport: sport ?? this.sport,
      priceStudent: priceStudent ?? this.priceStudent,
      pricePublic: pricePublic ?? this.pricePublic,
      refereeRequired: refereeRequired ?? this.refereeRequired,
      subUnits: subUnits ?? this.subUnits,
      imageUrl: imageUrl ?? this.imageUrl,
      isIndoor: isIndoor ?? this.isIndoor,
      isActive: isActive ?? this.isActive,
      amenities: amenities ?? this.amenities,
      location: location ?? this.location,
    );
  }

  @override
  String toString() {
    return 'FacilityModel(id: $id, name: $name, sport: ${sport.displayName})';
  }
}

/// Seed data for facilities collection
/// Location coordinates are based on UPM campus (Serdang, Selangor)
/// 
/// Pricing Model:
/// - Students: Small booking fees (RM 3-10) - facility access free per UPM policy
/// - Public: Full rental rates (RM 20-600)
/// 
/// Booking Types:
/// - SESSION: 2-hour fixed duration (Football, Futsal)
/// - INVENTORY: Hourly with multiple units (Badminton, Tennis)
const List<Map<String, dynamic>> facilitiesSeedData = [
  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTBALL FACILITIES (SESSION - 2 hours)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'id': 'fac_football_stadium',
    'name': 'Stadium UPM',
    'description':
        'Main stadium at UPM Sports Complex. Used for official varsity matches and tournaments. Full-size grass pitch with spectator seating and floodlights.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,  // Booking fee
    'price_public': 600,  // Premium rate
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 2.986372108422893, 'longitude': 101.72579628891536},
  },
  {
    'id': 'fac_football_padang_a',
    'name': 'Padang A (Near KMR)',
    'description':
        'Full-sized football field near Kolej Mohamad Rashid. Natural grass surface with floodlights. Suitable for 11-a-side matches and training.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,  // Booking fee
    'price_public': 250,
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 2.997660204655413, 'longitude': 101.70600927089941},
  },
  {
    'id': 'fac_football_padang_b',
    'name': 'Padang B (Near KMR)',
    'description':
        'Football field near Kolej Mohamad Rashid area. Natural grass surface with floodlights for evening games.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,
    'price_public': 250,
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 2.9960699996249094, 'longitude': 101.7069976276016},
  },
  {
    'id': 'fac_football_padang_c',
    'name': 'Padang C (Near KMR)',
    'description':
        'Football field near Kolej Mohamad Rashid area. Natural grass surface with floodlights for evening games.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,
    'price_public': 250,
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 2.995181678690454, 'longitude': 101.70770111887524},
  },
  {
    'id': 'fac_football_padang_d',
    'name': 'Padang D (Kolej Serumpun)',
    'description':
        'Football field at Kolej Serumpun residential area. Natural grass surface suitable for training and matches.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,
    'price_public': 250,
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 2.9918733483331974, 'longitude': 101.71658472158012},
  },
  {
    'id': 'fac_football_padang_e',
    'name': 'Padang E (Kolej 10)',
    'description':
        'Football field at Kolej 10 area. Natural grass surface with floodlights for evening games.',
    'type': 'SESSION',
    'sport': 'FOOTBALL',
    'price_student': 10,
    'price_public': 250,
    'referee_required': 3,
    'isIndoor': false,
    'location': {'latitude': 3.0078650418969475, 'longitude': 101.71792061303512},
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // FUTSAL FACILITIES (SESSION - 2 hours)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'id': 'fac_futsal_complex_a',
    'name': 'Gelanggang Futsal A',
    'description':
        'Indoor futsal court at UPM Sports Complex. Synthetic flooring with proper lighting.',
    'type': 'SESSION',
    'sport': 'FUTSAL',
    'price_student': 5,  // Booking fee
    'price_public': 100,
    'referee_required': 1,
    'isIndoor': true,
    'location': {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808},
  },
  {
    'id': 'fac_futsal_complex_b',
    'name': 'Gelanggang Futsal B',
    'description':
        'Indoor futsal court at UPM Sports Complex. Synthetic flooring with proper lighting.',
    'type': 'SESSION',
    'sport': 'FUTSAL',
    'price_student': 5,
    'price_public': 100,
    'referee_required': 1,
    'isIndoor': true,
    'location': {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808},
  },
  {
    'id': 'fac_futsal_complex_c',
    'name': 'Gelanggang Futsal C',
    'description':
        'Indoor futsal court at UPM Sports Complex. Synthetic flooring with proper lighting.',
    'type': 'SESSION',
    'sport': 'FUTSAL',
    'price_student': 5,
    'price_public': 100,
    'referee_required': 1,
    'isIndoor': true,
    'location': {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808},
  },
  {
    'id': 'fac_futsal_complex_d',
    'name': 'Gelanggang Futsal D',
    'description':
        'Indoor futsal court at UPM Sports Complex. Synthetic flooring with proper lighting.',
    'type': 'SESSION',
    'sport': 'FUTSAL',
    'price_student': 5,
    'price_public': 100,
    'referee_required': 1,
    'isIndoor': true,
    'location': {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808},
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // BADMINTON FACILITY (INVENTORY - Hourly, multiple courts)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'id': 'fac_badminton_main',
    'name': 'Dewan Serbaguna',
    'description':
        'Multi-purpose hall with 8 badminton courts. Wooden flooring with standard lighting.',
    'type': 'INVENTORY',
    'sport': 'BADMINTON',
    'sub_units': [
      'Court 1', 'Court 2', 'Court 3', 'Court 4',
      'Court 5', 'Court 6', 'Court 7', 'Court 8'
    ],
    'price_student': 3,  // Booking fee per hour
    'price_public': 20,
    'referee_required': 0,
    'isIndoor': true,
    'location': {'latitude': 2.9868095178480107, 'longitude': 101.7245986302808},
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // TENNIS FACILITY (INVENTORY - Hourly, multiple courts)
  // Official UPM Rate: RM20/hour (max 2 hours)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    'id': 'fac_tennis_main',
    'name': 'Gelanggang Tenis UPM',
    'description':
        '14 outdoor hard courts at UPM Tennis Complex. Suitable for training and matches. Maximum 2 hours per booking.',
    'type': 'INVENTORY',
    'sport': 'TENNIS',
    'sub_units': [
      'Court 1', 'Court 2', 'Court 3', 'Court 4', 'Court 5', 'Court 6', 'Court 7',
      'Court 8', 'Court 9', 'Court 10', 'Court 11', 'Court 12', 'Court 13', 'Court 14'
    ],
    'price_student': 5,  // Booking fee per hour
    'price_public': 20,  // Official UPM rate: RM20/hour
    'referee_required': 0,
    'isIndoor': false,
    'location': {'latitude': 2.9974331685643287, 'longitude': 101.7043194912751},
  },
];

