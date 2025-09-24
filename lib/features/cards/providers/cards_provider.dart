import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/database_service.dart';
import '../../../core/models/nfc_card.dart';

class CardsProvider extends ChangeNotifier {
  final DatabaseService _database = DatabaseService();

  List<NFCCard> _allCards = [];
  List<NFCCard> _filteredCards = [];
  List<NFCCard> _favoriteCards = [];
  List<NFCCard> _recentCards = [];
  
  bool _isLoading = false;
  String _searchQuery = '';
  CardType? _selectedTypeFilter;
  CardStatus? _selectedStatusFilter;
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // Getters
  List<NFCCard> get allCards => _allCards;
  List<NFCCard> get filteredCards => _filteredCards;
  List<NFCCard> get favoriteCards => _favoriteCards;
  List<NFCCard> get recentCards => _recentCards;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  CardType? get selectedTypeFilter => _selectedTypeFilter;
  CardStatus? get selectedStatusFilter => _selectedStatusFilter;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Statistics
  int get totalCards => _allCards.length;
  int get activeCards => _allCards.where((card) => card.status == CardStatus.active).length;
  int get favoriteCardsCount => _favoriteCards.length;
  int get archivedCards => _allCards.where((card) => card.status == CardStatus.archived).length;
  int get clonedCards => _allCards.where((card) => card.isCloned).length;

  Future<void> initialize() async {
    await loadCards();
  }

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allCards = await _database.getAllCards();
      _favoriteCards = await _database.getFavoriteCards();
      _recentCards = await _database.getRecentCards(limit: 10);
      
      _applyFilters();
    } catch (e) {
      debugPrint('Failed to load cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCards() async {
    await loadCards();
  }

  Future<void> addCard(NFCCard card) async {
    try {
      await _database.insertCard(card);
      await loadCards(); // Reload to get the updated list
    } catch (e) {
      debugPrint('Failed to add card: $e');
      rethrow;
    }
  }

  Future<void> updateCard(NFCCard card) async {
    try {
      await _database.updateCard(card);
      
      // Update local lists
      final index = _allCards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _allCards[index] = card;
      }
      
      await loadCards(); // Refresh to ensure consistency
    } catch (e) {
      debugPrint('Failed to update card: $e');
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _database.deleteCard(cardId);
      _allCards.removeWhere((card) => card.id == cardId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete card: $e');
      rethrow;
    }
  }

  Future<void> deleteMultipleCards(List<String> cardIds) async {
    try {
      for (final cardId in cardIds) {
        await _database.deleteCard(cardId);
      }
      
      _allCards.removeWhere((card) => cardIds.contains(card.id));
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete multiple cards: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(NFCCard card) async {
    try {
      final newStatus = card.status == CardStatus.favorite 
          ? CardStatus.active 
          : CardStatus.favorite;
      
      final updatedCard = card.copyWith(status: newStatus);
      await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      rethrow;
    }
  }

  Future<void> archiveCard(NFCCard card) async {
    try {
      final updatedCard = card.copyWith(status: CardStatus.archived);
      await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Failed to archive card: $e');
      rethrow;
    }
  }

  Future<void> restoreCard(NFCCard card) async {
    try {
      final updatedCard = card.copyWith(status: CardStatus.active);
      await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Failed to restore card: $e');
      rethrow;
    }
  }

  Future<void> duplicateCard(NFCCard card) async {
    try {
      final duplicatedCard = NFCCard(
        name: '${card.name} (Copy)',
        description: card.description,
        type: card.type,
        rawData: Map<String, dynamic>.from(card.rawData),
        uid: List<int>.from(card.uid),
        standard: card.standard,
        tags: List<String>.from(card.tags),
        metadata: {
          ...card.metadata,
          'duplicated_from': card.id,
          'duplicated_at': DateTime.now().toIso8601String(),
        },
      );
      
      await addCard(duplicatedCard);
    } catch (e) {
      debugPrint('Failed to duplicate card: $e');
      rethrow;
    }
  }

  // Search and filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(CardType? type) {
    _selectedTypeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(CardStatus? status) {
    _selectedStatusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void setSorting(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = !_sortAscending;
    }
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTypeFilter = null;
    _selectedStatusFilter = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredCards = List<NFCCard>.from(_allCards);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredCards = _filteredCards.where((card) {
        return card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (card.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
               card.formattedUID.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               card.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply type filter
    if (_selectedTypeFilter != null) {
      _filteredCards = _filteredCards.where((card) => card.type == _selectedTypeFilter).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != null) {
      _filteredCards = _filteredCards.where((card) => card.status == _selectedStatusFilter).toList();
    }

    // Apply sorting
    _filteredCards.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'type':
          comparison = a.type.index.compareTo(b.type.index);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'read_count':
          comparison = a.readCount.compareTo(b.readCount);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  // Analytics and statistics
  Map<CardType, int> getCardTypeDistribution() {
    final distribution = <CardType, int>{};
    
    for (final card in _allCards) {
      distribution[card.type] = (distribution[card.type] ?? 0) + 1;
    }
    
    return distribution;
  }

  Map<String, int> getMonthlyCardStats() {
    final monthlyStats = <String, int>{};
    
    for (final card in _allCards) {
      final monthKey = '${card.createdAt.year}-${card.createdAt.month.toString().padLeft(2, '0')}';
      monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
    }
    
    return monthlyStats;
  }

  List<NFCCard> getMostReadCards({int limit = 5}) {
    final sortedCards = List<NFCCard>.from(_allCards);
    sortedCards.sort((a, b) => b.readCount.compareTo(a.readCount));
    return sortedCards.take(limit).toList();
  }

  List<NFCCard> getRecentlyAddedCards({int limit = 5}) {
    final sortedCards = List<NFCCard>.from(_allCards);
    sortedCards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedCards.take(limit).toList();
  }

  // Import/Export functionality
  Future<Map<String, dynamic>> exportCards({
    List<String>? cardIds,
    bool includeArchivedCards = false,
  }) async {
    try {
      List<NFCCard> cardsToExport;
      
      if (cardIds != null) {
        cardsToExport = _allCards.where((card) => cardIds.contains(card.id)).toList();
      } else {
        cardsToExport = includeArchivedCards 
            ? _allCards 
            : _allCards.where((card) => card.status != CardStatus.archived).toList();
      }

      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'total_cards': cardsToExport.length,
        'cards': cardsToExport.map((card) => card.toJson()).toList(),
      };

      return exportData;
    } catch (e) {
      debugPrint('Failed to export cards: $e');
      rethrow;
    }
  }

  Future<String> exportCardsToFile({
    List<String>? cardIds,
    bool includeArchivedCards = false,
    String format = 'json',
  }) async {
    try {
      final exportData = await exportCards(
        cardIds: cardIds,
        includeArchivedCards: includeArchivedCards,
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'nfc_cards_export_$timestamp.$format';
      final file = File('${directory.path}/$fileName');

      String content;
      if (format.toLowerCase() == 'csv') {
        content = _convertToCSV(exportData['cards'] as List);
      } else {
        content = const JsonEncoder.withIndent('  ').convert(exportData);
      }

      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Failed to export cards to file: $e');
      rethrow;
    }
  }

  String _convertToCSV(List cards) {
    if (cards.isEmpty) return '';

    final headers = [
      'ID', 'Name', 'Description', 'Type', 'Status', 'UID', 'Standard',
      'Created At', 'Updated At', 'Read Count', 'Is Cloned'
    ];

    final csvLines = <String>[headers.join(',')];

    for (final card in cards) {
      final row = [
        card['id'],
        '"${card['name']}"',
        '"${card['description'] ?? ''}"',
        card['type'],
        card['status'],
        '"${card['uid'].join(':')}"',
        '"${card['standard']}"',
        card['createdAt'],
        card['updatedAt'],
        card['readCount'],
        card['isCloned'],
      ];
      csvLines.add(row.join(','));
    }

    return csvLines.join('\n');
  }

  Future<int> importCards(Map<String, dynamic> importData) async {
    try {
      final cards = importData['cards'] as List?;
      if (cards == null) return 0;

      int importedCount = 0;
      
      for (final cardData in cards) {
        try {
          final cardMap = Map<String, dynamic>.from(cardData);
          
          // Convert JSON format back to database format
          if (cardMap['type'] is String) {
            cardMap['type'] = CardType.values
                .firstWhere((e) => e.name == cardMap['type'])
                .index;
          }
          
          if (cardMap['status'] is String) {
            cardMap['status'] = CardStatus.values
                .firstWhere((e) => e.name == cardMap['status'])
                .index;
          }

          final card = NFCCard.fromMap(cardMap);
          await addCard(card);
          importedCount++;
        } catch (e) {
          debugPrint('Failed to import individual card: $e');
          // Continue with next card
        }
      }

      return importedCount;
    } catch (e) {
      debugPrint('Failed to import cards: $e');
      rethrow;
    }
  }

  Future<void> shareCard(NFCCard card) async {
    try {
      final exportData = await exportCards(cardIds: [card.id]);
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${card.name}.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NFC Card: ${card.name}',
        subject: 'Shared NFC Card Data',
      );
    } catch (e) {
      debugPrint('Failed to share card: $e');
      rethrow;
    }
  }

  Future<void> shareMultipleCards(List<String> cardIds) async {
    try {
      final exportData = await exportCards(cardIds: cardIds);
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/nfc_cards_${cardIds.length}.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NFC Cards Export (${cardIds.length} cards)',
        subject: 'Shared NFC Cards Data',
      );
    } catch (e) {
      debugPrint('Failed to share multiple cards: $e');
      rethrow;
    }
  }

  // Utility methods
  NFCCard? getCardById(String id) {
    try {
      return _allCards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  List<NFCCard> getCardsByType(CardType type) {
    return _allCards.where((card) => card.type == type).toList();
  }

  List<NFCCard> getCardsByStatus(CardStatus status) {
    return _allCards.where((card) => card.status == status).toList();
  }

  List<String> getAllTags() {
    final allTags = <String>{};
    for (final card in _allCards) {
      allTags.addAll(card.tags);
    }
    return allTags.toList()..sort();
  }

  List<NFCCard> getCardsByTag(String tag) {
    return _allCards.where((card) => card.tags.contains(tag)).toList();
  }

  Future<void> addTagToCard(NFCCard card, String tag) async {
    try {
      if (!card.tags.contains(tag)) {
        final updatedTags = List<String>.from(card.tags)..add(tag);
        final updatedCard = card.copyWith(tags: updatedTags);
        await updateCard(updatedCard);
      }
    } catch (e) {
      debugPrint('Failed to add tag to card: $e');
      rethrow;
    }
  }

  Future<void> removeTagFromCard(NFCCard card, String tag) async {
    try {
      final updatedTags = List<String>.from(card.tags)..remove(tag);
      final updatedCard = card.copyWith(tags: updatedTags);
      await updateCard(updatedCard);
    } catch (e) {
      debugPrint('Failed to remove tag from card: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}