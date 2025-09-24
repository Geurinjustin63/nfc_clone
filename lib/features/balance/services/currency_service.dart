import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/secure_storage_service.dart';
import '../models/card_balance.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final SecureStorageService _storage = SecureStorageService();
  final Map<String, Map<String, Decimal>> _exchangeRates = {};
  DateTime? _lastUpdateTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  // Free API endpoint for exchange rates
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _fallbackApiUrl = 'https://api.fixer.io/latest';

  Future<void> initialize() async {
    await _loadCachedRates();
    await _updateRatesIfNeeded();
  }

  Future<void> _loadCachedRates() async {
    try {
      final cachedData = _storage.getCache<Map<String, dynamic>>('exchange_rates');
      if (cachedData != null) {
        final ratesData = cachedData['rates'] as Map<String, dynamic>;
        final lastUpdate = DateTime.parse(cachedData['last_updated']);
        
        // Convert cached rates to Decimal
        for (final baseCurrency in ratesData.keys) {
          final rates = ratesData[baseCurrency] as Map<String, dynamic>;
          _exchangeRates[baseCurrency] = {};
          
          for (final entry in rates.entries) {
            _exchangeRates[baseCurrency]![entry.key] = Decimal.parse(entry.value.toString());
          }
        }
        
        _lastUpdateTime = lastUpdate;
      }
    } catch (e) {
      print('Error loading cached exchange rates: $e');
    }
  }

  Future<void> _updateRatesIfNeeded() async {
    if (_lastUpdateTime == null || 
        DateTime.now().difference(_lastUpdateTime!) > _cacheExpiry) {
      await updateExchangeRates();
    }
  }

  Future<bool> updateExchangeRates() async {
    try {
      // Update rates for all supported currencies
      final currencies = Currency.values;
      bool anySuccess = false;

      for (final currency in currencies) {
        final success = await _fetchRatesForCurrency(currency);
        if (success) anySuccess = true;
      }

      if (anySuccess) {
        _lastUpdateTime = DateTime.now();
        await _saveCachedRates();
        return true;
      }
    } catch (e) {
      print('Error updating exchange rates: $e');
    }
    return false;
  }

  Future<bool> _fetchRatesForCurrency(Currency baseCurrency) async {
    try {
      final currencyCode = _getCurrencyCode(baseCurrency);
      final url = '$_apiUrl/$currencyCode';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        
        // Convert to Decimal and store
        _exchangeRates[currencyCode] = {};
        for (final entry in rates.entries) {
          _exchangeRates[currencyCode]![entry.key] = Decimal.parse(entry.value.toString());
        }
        
        return true;
      }
    } catch (e) {
      print('Error fetching rates for $baseCurrency: $e');
      
      // Try fallback API
      return await _fetchRatesFromFallbackAPI(baseCurrency);
    }
    return false;
  }

  Future<bool> _fetchRatesFromFallbackAPI(Currency baseCurrency) async {
    try {
      // Use fallback rates or hardcoded rates
      await _setFallbackRates(baseCurrency);
      return true;
    } catch (e) {
      print('Fallback rates also failed: $e');
      return false;
    }
  }

  Future<void> _setFallbackRates(Currency baseCurrency) async {
    // Hardcoded fallback rates (update periodically)
    final fallbackRates = {
      'USD': {
        'EUR': '0.85',
        'GBP': '0.73',
        'JPY': '110.0',
        'CAD': '1.25',
        'AUD': '1.35',
        'CHF': '0.92',
        'CNY': '6.45',
        'HKD': '7.80',
        'SGD': '1.35',
      },
      'EUR': {
        'USD': '1.18',
        'GBP': '0.86',
        'JPY': '129.0',
        'CAD': '1.47',
        'AUD': '1.59',
        'CHF': '1.08',
        'CNY': '7.59',
        'HKD': '9.19',
        'SGD': '1.59',
      },
      'GBP': {
        'USD': '1.37',
        'EUR': '1.16',
        'JPY': '151.0',
        'CAD': '1.71',
        'AUD': '1.85',
        'CHF': '1.26',
        'CNY': '8.84',
        'HKD': '10.70',
        'SGD': '1.85',
      },
    };

    final currencyCode = _getCurrencyCode(baseCurrency);
    if (fallbackRates.containsKey(currencyCode)) {
      _exchangeRates[currencyCode] = {};
      final rates = fallbackRates[currencyCode]!;
      
      for (final entry in rates.entries) {
        _exchangeRates[currencyCode]![entry.key] = Decimal.parse(entry.value);
      }
    }
  }

  Future<void> _saveCachedRates() async {
    try {
      final cacheData = {
        'rates': _exchangeRates.map((baseCurrency, rates) => MapEntry(
          baseCurrency,
          rates.map((currency, rate) => MapEntry(currency, rate.toString())),
        )),
        'last_updated': _lastUpdateTime!.toIso8601String(),
      };

      await _storage.setCache('exchange_rates', cacheData, ttl: _cacheExpiry);
    } catch (e) {
      print('Error saving cached rates: $e');
    }
  }

  Decimal convert(Decimal amount, {required Currency from, required Currency to}) {
    if (from == to) return amount;

    try {
      final fromCode = _getCurrencyCode(from);
      final toCode = _getCurrencyCode(to);

      // Get exchange rate
      final rate = _getExchangeRate(fromCode, toCode);
      if (rate != null) {
        return amount * rate;
      }

      // If direct rate not available, convert through USD
      if (from != Currency.usd && to != Currency.usd) {
        final toUsdRate = _getExchangeRate(fromCode, 'USD');
        final fromUsdRate = _getExchangeRate('USD', toCode);
        
        if (toUsdRate != null && fromUsdRate != null) {
          return amount * toUsdRate * fromUsdRate;
        }
      }
    } catch (e) {
      print('Error converting currency: $e');
    }

    // Return original amount if conversion fails
    return amount;
  }

  Decimal? _getExchangeRate(String from, String to) {
    try {
      return _exchangeRates[from]?[to];
    } catch (e) {
      return null;
    }
  }

  String _getCurrencyCode(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.gbp:
        return 'GBP';
      case Currency.jpy:
        return 'JPY';
      case Currency.cad:
        return 'CAD';
      case Currency.aud:
        return 'AUD';
      case Currency.chf:
        return 'CHF';
      case Currency.cny:
        return 'CNY';
      case Currency.hkd:
        return 'HKD';
      case Currency.sgd:
        return 'SGD';
    }
  }

  Currency? getCurrencyFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return Currency.usd;
      case 'EUR':
        return Currency.eur;
      case 'GBP':
        return Currency.gbp;
      case 'JPY':
        return Currency.jpy;
      case 'CAD':
        return Currency.cad;
      case 'AUD':
        return Currency.aud;
      case 'CHF':
        return Currency.chf;
      case 'CNY':
        return Currency.cny;
      case 'HKD':
        return Currency.hkd;
      case 'SGD':
        return Currency.sgd;
      default:
        return null;
    }
  }

  List<Currency> getSupportedCurrencies() {
    return Currency.values;
  }

  String formatAmount(Decimal amount, Currency currency) {
    final symbol = CardBalance.getCurrencySymbol(currency);
    
    // Format based on currency conventions
    switch (currency) {
      case Currency.jpy:
        // Japanese Yen has no decimal places
        return '$symbol${amount.toInt()}';
      default:
        return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  bool get isOnline {
    return _lastUpdateTime != null && 
           DateTime.now().difference(_lastUpdateTime!) < _cacheExpiry;
  }

  DateTime? get lastUpdateTime => _lastUpdateTime;

  Future<Map<String, dynamic>> getExchangeRateInfo() async {
    return {
      'last_updated': _lastUpdateTime?.toIso8601String(),
      'cache_expiry': _cacheExpiry.inHours,
      'supported_currencies': Currency.values.map((c) => _getCurrencyCode(c)).toList(),
      'available_rates': _exchangeRates.keys.toList(),
      'is_online': isOnline,
    };
  }

  // Currency detection from locale
  Currency detectCurrencyFromLocale(String locale) {
    final currencyMap = {
      'en_US': Currency.usd,
      'en_GB': Currency.gbp,
      'en_CA': Currency.cad,
      'en_AU': Currency.aud,
      'de_DE': Currency.eur,
      'fr_FR': Currency.eur,
      'es_ES': Currency.eur,
      'it_IT': Currency.eur,
      'ja_JP': Currency.jpy,
      'zh_CN': Currency.cny,
      'zh_HK': Currency.hkd,
      'en_SG': Currency.sgd,
      'de_CH': Currency.chf,
      'fr_CH': Currency.chf,
    };

    return currencyMap[locale] ?? Currency.usd;
  }

  // Currency validation
  bool isValidAmount(String amountString, Currency currency) {
    try {
      final amount = Decimal.parse(amountString);
      
      // Check reasonable limits
      if (amount < Decimal.zero) return false;
      if (amount > Decimal.fromInt(1000000)) return false; // $1M limit
      
      // Currency-specific validation
      switch (currency) {
        case Currency.jpy:
          // JPY doesn't have decimal places
          return amount == Decimal.fromInt(amount.toInt());
        default:
          // Most currencies support 2 decimal places
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  Decimal roundToValidPrecision(Decimal amount, Currency currency) {
    switch (currency) {
      case Currency.jpy:
        // Round to whole numbers for JPY
        return Decimal.fromInt(amount.round().toInt());
      default:
        // Round to 2 decimal places for most currencies
        return Decimal.parse(amount.toStringAsFixed(2));
    }
  }
}