import 'package:uuid/uuid.dart';

enum CardType {
  mifareClassic,
  mifareUltralight,
  ntag,
  desfire,
  felica,
  iso15693,
  iso14443A,
  iso14443B,
  unknown,
}

enum CardStatus {
  active,
  archived,
  favorite,
  corrupted,
}

class NFCCard {
  final String id;
  final String name;
  final String? description;
  final CardType type;
  final CardStatus status;
  final Map<String, dynamic> rawData;
  final List<int> uid;
  final String standard;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final int readCount;
  final bool isCloned;
  final String? sourceCardId;
  final Map<String, dynamic> metadata;

  NFCCard({
    String? id,
    required this.name,
    this.description,
    required this.type,
    this.status = CardStatus.active,
    required this.rawData,
    required this.uid,
    required this.standard,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
    this.readCount = 0,
    this.isCloned = false,
    this.sourceCardId,
    this.metadata = const {},
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor for creating from NFC tag data
  factory NFCCard.fromNFCTag({
    required Map<String, dynamic> tagData,
    String? name,
    String? description,
    List<String> tags = const [],
  }) {
    final uid = tagData['nfca']?['identifier'] ?? 
                 tagData['nfcb']?['identifier'] ?? 
                 tagData['nfcf']?['identifier'] ?? 
                 tagData['nfcv']?['identifier'] ?? 
                 <int>[];

    final CardType cardType = _detectCardType(tagData);
    final String standard = _detectStandard(tagData);

    return NFCCard(
      name: name ?? 'Card ${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      type: cardType,
      rawData: Map<String, dynamic>.from(tagData),
      uid: List<int>.from(uid),
      standard: standard,
      tags: tags,
      metadata: {
        'detected_at': DateTime.now().toIso8601String(),
        'platform': 'flutter',
        'raw_size': tagData.toString().length,
      },
    );
  }

  // Factory constructor for creating from database map
  factory NFCCard.fromMap(Map<String, dynamic> map) {
    return NFCCard(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: CardType.values[map['type']],
      status: CardStatus.values[map['status']],
      rawData: Map<String, dynamic>.from(map['raw_data']),
      uid: List<int>.from(map['uid']),
      standard: map['standard'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      tags: List<String>.from(map['tags'] ?? []),
      readCount: map['read_count'] ?? 0,
      isCloned: map['is_cloned'] == 1,
      sourceCardId: map['source_card_id'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'status': status.index,
      'raw_data': rawData,
      'uid': uid,
      'standard': standard,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'read_count': readCount,
      'is_cloned': isCloned ? 1 : 0,
      'source_card_id': sourceCardId,
      'metadata': metadata,
    };
  }

  // Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'rawData': rawData,
      'uid': uid,
      'standard': standard,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'readCount': readCount,
      'isCloned': isCloned,
      'sourceCardId': sourceCardId,
      'metadata': metadata,
    };
  }

  // Create a copy with updated fields
  NFCCard copyWith({
    String? name,
    String? description,
    CardType? type,
    CardStatus? status,
    Map<String, dynamic>? rawData,
    List<int>? uid,
    String? standard,
    DateTime? updatedAt,
    List<String>? tags,
    int? readCount,
    bool? isCloned,
    String? sourceCardId,
    Map<String, dynamic>? metadata,
  }) {
    return NFCCard(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      rawData: rawData ?? this.rawData,
      uid: uid ?? this.uid,
      standard: standard ?? this.standard,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
      readCount: readCount ?? this.readCount,
      isCloned: isCloned ?? this.isCloned,
      sourceCardId: sourceCardId ?? this.sourceCardId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get formatted UID
  String get formattedUID {
    return uid.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
  }

  // Get card size in bytes
  int get sizeInBytes {
    return rawData.toString().length;
  }

  // Check if card has NDEF data
  bool get hasNDEFData {
    return rawData.containsKey('ndef');
  }

  // Get NDEF records count
  int get ndefRecordsCount {
    if (!hasNDEFData) return 0;
    final ndefData = rawData['ndef'];
    if (ndefData is Map && ndefData.containsKey('records')) {
      return (ndefData['records'] as List).length;
    }
    return 0;
  }

  // Get memory usage
  Map<String, int> get memoryInfo {
    final Map<String, int> info = {};
    
    if (type == CardType.mifareClassic) {
      info['total_sectors'] = rawData['mifare_classic']?['sectors']?.length ?? 0;
      info['total_blocks'] = (info['total_sectors']! * 4);
      info['used_blocks'] = _countUsedBlocks();
    } else if (type == CardType.mifareUltralight) {
      info['total_pages'] = rawData['mifare_ultralight']?['pages']?.length ?? 0;
      info['used_pages'] = _countUsedPages();
    }
    
    return info;
  }

  // Private helper methods
  static CardType _detectCardType(Map<String, dynamic> tagData) {
    if (tagData.containsKey('mifare_classic')) {
      return CardType.mifareClassic;
    } else if (tagData.containsKey('mifare_ultralight')) {
      return CardType.mifareUltralight;
    } else if (tagData.containsKey('nfca')) {
      final atqa = tagData['nfca']['atqa'];
      final sak = tagData['nfca']['sak'];
      
      if (atqa != null && sak != null) {
        if (sak == 0x00 || sak == 0x44) {
          return CardType.mifareUltralight;
        } else if (sak == 0x08 || sak == 0x18) {
          return CardType.mifareClassic;
        } else if (sak == 0x20) {
          return CardType.desfire;
        }
      }
      return CardType.iso14443A;
    } else if (tagData.containsKey('nfcb')) {
      return CardType.iso14443B;
    } else if (tagData.containsKey('nfcf')) {
      return CardType.felica;
    } else if (tagData.containsKey('nfcv')) {
      return CardType.iso15693;
    }
    
    return CardType.unknown;
  }

  static String _detectStandard(Map<String, dynamic> tagData) {
    if (tagData.containsKey('nfca')) {
      return 'ISO 14443 Type A';
    } else if (tagData.containsKey('nfcb')) {
      return 'ISO 14443 Type B';
    } else if (tagData.containsKey('nfcf')) {
      return 'FeliCa';
    } else if (tagData.containsKey('nfcv')) {
      return 'ISO 15693';
    }
    return 'Unknown';
  }

  int _countUsedBlocks() {
    // Implementation for counting used blocks in MIFARE Classic
    // This is a simplified version - in reality you'd analyze the actual data
    return 0;
  }

  int _countUsedPages() {
    // Implementation for counting used pages in MIFARE Ultralight
    // This is a simplified version - in reality you'd analyze the actual data
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NFCCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NFCCard{id: $id, name: $name, type: $type, uid: $formattedUID}';
  }
}