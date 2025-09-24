import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

enum BalanceType {
  transit,
  payment,
  giftCard,
  loyalty,
  prepaid,
  unknown,
}

enum BalanceStatus {
  active,
  expired,
  blocked,
  lowBalance,
  unknown,
}

enum Currency {
  usd,
  eur,
  gbp,
  jpy,
  cad,
  aud,
  chf,
  cny,
  hkd,
  sgd,
}

class CardBalance {
  final String id;
  final String cardId;
  final Decimal amount;
  final Currency currency;
  final BalanceType type;
  final BalanceStatus status;
  final DateTime lastUpdated;
  final DateTime? expiryDate;
  final bool isEncrypted;
  final Map<String, dynamic> metadata;
  final String? issuerName;
  final String? cardNumber;
  final List<BalanceComponent> components;

  CardBalance({
    String? id,
    required this.cardId,
    required this.amount,
    this.currency = Currency.usd,
    required this.type,
    this.status = BalanceStatus.active,
    DateTime? lastUpdated,
    this.expiryDate,
    this.isEncrypted = false,
    this.metadata = const {},
    this.issuerName,
    this.cardNumber,
    this.components = const [],
  })  : id = id ?? const Uuid().v4(),
        lastUpdated = lastUpdated ?? DateTime.now();

  factory CardBalance.fromMap(Map<String, dynamic> map) {
    return CardBalance(
      id: map['id'],
      cardId: map['card_id'],
      amount: Decimal.parse(map['amount'].toString()),
      currency: Currency.values[map['currency'] ?? 0],
      type: BalanceType.values[map['balance_type']],
      status: BalanceStatus.values[map['status'] ?? 0],
      lastUpdated: DateTime.parse(map['last_updated']),
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      isEncrypted: (map['is_encrypted'] ?? 0) == 1,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      issuerName: map['issuer_name'],
      cardNumber: map['card_number'],
      components: (map['components'] as List<dynamic>?)
          ?.map((c) => BalanceComponent.fromMap(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'amount': amount.toString(),
      'currency': currency.index,
      'balance_type': type.index,
      'status': status.index,
      'last_updated': lastUpdated.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_encrypted': isEncrypted ? 1 : 0,
      'metadata': metadata,
      'issuer_name': issuerName,
      'card_number': cardNumber,
      'components': components.map((c) => c.toMap()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'amount': amount.toString(),
      'currency': currency.name,
      'type': type.name,
      'status': status.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isEncrypted': isEncrypted,
      'metadata': metadata,
      'issuerName': issuerName,
      'cardNumber': cardNumber,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }

  // Helper methods
  String get formattedAmount {
    return '${getCurrencySymbol(currency)}${amount.toStringAsFixed(2)}';
  }

  String get displayAmount {
    final symbol = getCurrencySymbol(currency);
    if (amount >= Decimal.fromInt(1000000)) {
      return '$symbol${(amount / Decimal.fromInt(1000000)).toStringAsFixed(1)}M';
    } else if (amount >= Decimal.fromInt(1000)) {
      return '$symbol${(amount / Decimal.fromInt(1000)).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  bool get isExpired {
    return expiryDate != null && DateTime.now().isAfter(expiryDate!);
  }

  bool get isLowBalance {
    return status == BalanceStatus.lowBalance || amount < getLowBalanceThreshold(type);
  }

  Duration get timeSinceUpdate {
    return DateTime.now().difference(lastUpdated);
  }

  bool get needsRefresh {
    // Consider balance stale after 1 hour for transit cards, 24 hours for others
    final maxAge = type == BalanceType.transit 
        ? const Duration(hours: 1)
        : const Duration(hours: 24);
    return timeSinceUpdate > maxAge;
  }

  CardBalance copyWith({
    Decimal? amount,
    Currency? currency,
    BalanceType? type,
    BalanceStatus? status,
    DateTime? lastUpdated,
    DateTime? expiryDate,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
    String? issuerName,
    String? cardNumber,
    List<BalanceComponent>? components,
  }) {
    return CardBalance(
      id: id,
      cardId: cardId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? DateTime.now(),
      expiryDate: expiryDate ?? this.expiryDate,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
      issuerName: issuerName ?? this.issuerName,
      cardNumber: cardNumber ?? this.cardNumber,
      components: components ?? this.components,
    );
  }

  static String getCurrencySymbol(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
      case Currency.jpy:
        return '¥';
      case Currency.cad:
        return 'C\$';
      case Currency.aud:
        return 'A\$';
      case Currency.chf:
        return 'CHF ';
      case Currency.cny:
        return '¥';
      case Currency.hkd:
        return 'HK\$';
      case Currency.sgd:
        return 'S\$';
    }
  }

  static String getCurrencyName(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return 'US Dollar';
      case Currency.eur:
        return 'Euro';
      case Currency.gbp:
        return 'British Pound';
      case Currency.jpy:
        return 'Japanese Yen';
      case Currency.cad:
        return 'Canadian Dollar';
      case Currency.aud:
        return 'Australian Dollar';
      case Currency.chf:
        return 'Swiss Franc';
      case Currency.cny:
        return 'Chinese Yuan';
      case Currency.hkd:
        return 'Hong Kong Dollar';
      case Currency.sgd:
        return 'Singapore Dollar';
    }
  }

  static Decimal getLowBalanceThreshold(BalanceType type) {
    switch (type) {
      case BalanceType.transit:
        return Decimal.fromInt(5); // $5 for transit cards
      case BalanceType.payment:
        return Decimal.fromInt(50); // $50 for payment cards
      case BalanceType.giftCard:
        return Decimal.fromInt(10); // $10 for gift cards
      case BalanceType.loyalty:
        return Decimal.fromInt(0); // No threshold for loyalty
      case BalanceType.prepaid:
        return Decimal.fromInt(20); // $20 for prepaid cards
      case BalanceType.unknown:
        return Decimal.fromInt(10); // $10 default
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardBalance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CardBalance{id: $id, cardId: $cardId, amount: $formattedAmount, type: $type}';
  }
}

class BalanceComponent {
  final String name;
  final Decimal amount;
  final String? description;
  final DateTime? expiryDate;

  BalanceComponent({
    required this.name,
    required this.amount,
    this.description,
    this.expiryDate,
  });

  factory BalanceComponent.fromMap(Map<String, dynamic> map) {
    return BalanceComponent(
      name: map['name'],
      amount: Decimal.parse(map['amount'].toString()),
      description: map['description'],
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount.toString(),
      'description': description,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount.toString(),
      'description': description,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  bool get isExpired {
    return expiryDate != null && DateTime.now().isAfter(expiryDate!);
  }
}