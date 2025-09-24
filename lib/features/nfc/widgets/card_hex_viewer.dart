import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/nfc_card.dart';
import '../../../app/themes.dart';

class CardHexViewer extends StatefulWidget {
  final NFCCard card;

  const CardHexViewer({
    super.key,
    required this.card,
  });

  @override
  State<CardHexViewer> createState() => _CardHexViewerState();
}

class _CardHexViewerState extends State<CardHexViewer> {
  bool _showFormatted = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _buildDataView(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textHint.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search hex data...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copyAllData,
                icon: const Icon(Icons.copy_all),
                tooltip: 'Copy all data',
              ),
              IconButton(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                tooltip: 'Export data',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'View mode:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Formatted'),
                    icon: Icon(Icons.table_chart),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Raw'),
                    icon: Icon(Icons.code),
                  ),
                ],
                selected: {_showFormatted},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    _showFormatted = selection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    if (_showFormatted) {
      return _buildFormattedView();
    } else {
      return _buildRawView();
    }
  }

  Widget _buildFormattedView() {
    final sections = _parseCardData();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            subtitle: Text(
              '${section.data.length} bytes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            leading: Icon(
              section.icon,
              color: AppColors.primary,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHexGrid(section.data),
                    if (section.interpretation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interpretation:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              section.interpretation!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRawView() {
    final rawData = _getRawDataString();
    final highlightedData = _highlightSearchResults(rawData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.3),
          ),
        ),
        child: SelectableText(
          highlightedData,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.darkTextPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildHexGrid(List<int> data) {
    final rows = <Widget>[];
    
    for (int i = 0; i < data.length; i += 16) {
      final rowData = data.sublist(i, (i + 16).clamp(0, data.length));
      rows.add(_buildHexRow(i, rowData));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildHexRow(int offset, List<int> rowData) {
    final hexParts = <Widget>[];
    final asciiParts = <Widget>[];

    // Address
    hexParts.add(
      SizedBox(
        width: 60,
        child: Text(
          '${offset.toRadixString(16).padLeft(4, '0').toUpperCase()}:',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // Hex data
    for (int i = 0; i < 16; i++) {
      if (i < rowData.length) {
        final byte = rowData[i];
        final hexString = byte.toRadixString(16).padLeft(2, '0').toUpperCase();
        
        hexParts.add(
          GestureDetector(
            onTap: () => _showByteDetails(offset + i, byte),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _isSearchMatch(hexString) 
                    ? AppColors.warning.withOpacity(0.3)
                    : null,
              ),
              child: Text(
                hexString,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _getByteColor(byte),
                ),
              ),
            ),
          ),
        );

        // ASCII representation
        final ascii = (byte >= 32 && byte <= 126) ? String.fromCharCode(byte) : '.';
        asciiParts.add(
          Text(
            ascii,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: _getByteColor(byte),
            ),
          ),
        );
      } else {
        hexParts.add(
          const Text(
            '  ',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        );
        asciiParts.add(
          const Text(
            ' ',
            style: TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        );
      }

      // Add space after 8 bytes
      if (i == 7) {
        hexParts.add(const SizedBox(width: 8));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          ...hexParts,
          const SizedBox(width: 16),
          Text('|', style: TextStyle(color: AppColors.textHint)),
          const SizedBox(width: 4),
          ...asciiParts,
          const SizedBox(width: 4),
          Text('|', style: TextStyle(color: AppColors.textHint)),
        ],
      ),
    );
  }

  Color _getByteColor(int byte) {
    if (byte == 0x00) {
      return AppColors.textHint; // Null bytes
    } else if (byte >= 0x20 && byte <= 0x7E) {
      return AppColors.textPrimary; // Printable ASCII
    } else if (byte == 0xFF) {
      return AppColors.warning; // Common padding
    } else {
      return AppColors.info; // Other bytes
    }
  }

  bool _isSearchMatch(String hexString) {
    if (_searchQuery.isEmpty) return false;
    return hexString.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  List<DataSection> _parseCardData() {
    final sections = <DataSection>[];
    final rawData = widget.card.rawData;

    // UID section
    if (widget.card.uid.isNotEmpty) {
      sections.add(DataSection(
        title: 'UID (Unique Identifier)',
        icon: Icons.fingerprint,
        data: widget.card.uid,
        interpretation: 'Unique identifier for this NFC card: ${widget.card.formattedUID}',
      ));
    }

    // NDEF section
    if (rawData.containsKey('ndef')) {
      final ndefData = rawData['ndef'] as Map<String, dynamic>?;
      if (ndefData != null) {
        sections.add(DataSection(
          title: 'NDEF Data',
          icon: Icons.data_object,
          data: _extractBytesFromMap(ndefData),
          interpretation: 'NFC Data Exchange Format - contains structured data records',
        ));
      }
    }

    // MIFARE Classic sections
    if (rawData.containsKey('mifare_classic')) {
      final mifareData = rawData['mifare_classic'] as Map<String, dynamic>?;
      if (mifareData != null && mifareData.containsKey('sectors')) {
        final sectors = mifareData['sectors'] as Map<String, dynamic>;
        
        for (final entry in sectors.entries) {
          final sectorData = entry.value as Map<String, dynamic>;
          if (sectorData.containsKey('blocks')) {
            final blocks = sectorData['blocks'] as List<dynamic>;
            final sectorBytes = <int>[];
            
            for (final block in blocks) {
              if (block is Map<String, dynamic> && block.containsKey('data')) {
                final blockData = block['data'] as List<dynamic>;
                sectorBytes.addAll(blockData.cast<int>());
              }
            }
            
            if (sectorBytes.isNotEmpty) {
              sections.add(DataSection(
                title: 'MIFARE ${entry.key.replaceAll('_', ' ').toUpperCase()}',
                icon: Icons.storage,
                data: sectorBytes,
                interpretation: 'MIFARE Classic sector containing ${blocks.length} blocks',
              ));
            }
          }
        }
      }
    }

    // MIFARE Ultralight pages
    if (rawData.containsKey('mifare_ultralight')) {
      final ultralightData = rawData['mifare_ultralight'] as Map<String, dynamic>?;
      if (ultralightData != null && ultralightData.containsKey('pages')) {
        final pages = ultralightData['pages'] as List<dynamic>;
        final pageBytes = <int>[];
        
        for (final page in pages) {
          if (page is Map<String, dynamic> && page.containsKey('data')) {
            final pageData = page['data'] as List<dynamic>;
            pageBytes.addAll(pageData.cast<int>());
          }
        }
        
        if (pageBytes.isNotEmpty) {
          sections.add(DataSection(
            title: 'MIFARE Ultralight Pages',
            icon: Icons.view_module,
            data: pageBytes,
            interpretation: 'MIFARE Ultralight pages containing user data and configuration',
          ));
        }
      }
    }

    // If no structured data found, show raw bytes
    if (sections.isEmpty) {
      final allBytes = <int>[];
      _extractAllBytes(rawData, allBytes);
      
      if (allBytes.isNotEmpty) {
        sections.add(DataSection(
          title: 'Raw Card Data',
          icon: Icons.memory,
          data: allBytes,
          interpretation: 'Raw data extracted from the NFC card',
        ));
      }
    }

    return sections;
  }

  List<int> _extractBytesFromMap(Map<String, dynamic> data) {
    final bytes = <int>[];
    _extractAllBytes(data, bytes);
    return bytes;
  }

  void _extractAllBytes(dynamic data, List<int> bytes) {
    if (data is List) {
      for (final item in data) {
        if (item is int) {
          bytes.add(item);
        } else if (item is Map<String, dynamic>) {
          _extractAllBytes(item, bytes);
        }
      }
    } else if (data is Map<String, dynamic>) {
      for (final value in data.values) {
        _extractAllBytes(value, bytes);
      }
    }
  }

  String _getRawDataString() {
    final buffer = StringBuffer();
    final rawData = widget.card.rawData;
    
    buffer.writeln('NFC Card Raw Data');
    buffer.writeln('=================');
    buffer.writeln('Card Name: ${widget.card.name}');
    buffer.writeln('Card Type: ${widget.card.type.name}');
    buffer.writeln('UID: ${widget.card.formattedUID}');
    buffer.writeln('Standard: ${widget.card.standard}');
    buffer.writeln('');
    
    _writeMapToBuffer(rawData, buffer, 0);
    
    return buffer.toString();
  }

  void _writeMapToBuffer(dynamic data, StringBuffer buffer, int indent) {
    final indentString = '  ' * indent;
    
    if (data is Map<String, dynamic>) {
      for (final entry in data.entries) {
        buffer.write('$indentString${entry.key}: ');
        
        if (entry.value is Map || entry.value is List) {
          buffer.writeln();
          _writeMapToBuffer(entry.value, buffer, indent + 1);
        } else {
          buffer.writeln(entry.value);
        }
      }
    } else if (data is List) {
      for (int i = 0; i < data.length; i++) {
        buffer.write('$indentString[$i]: ');
        
        if (data[i] is Map || data[i] is List) {
          buffer.writeln();
          _writeMapToBuffer(data[i], buffer, indent + 1);
        } else {
          buffer.writeln(data[i]);
        }
      }
    }
  }

  String _highlightSearchResults(String text) {
    if (_searchQuery.isEmpty) return text;
    // For now, just return the text as-is
    // In a real implementation, you might use RichText to highlight matches
    return text;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _copyAllData() {
    final data = _showFormatted 
        ? widget.card.toJson().toString()
        : _getRawDataString();
    
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _exportData() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showByteDetails(int offset, int byte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Byte Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offset: 0x${offset.toRadixString(16).padLeft(4, '0').toUpperCase()}'),
            Text('Decimal: $byte'),
            Text('Hexadecimal: 0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}'),
            Text('Binary: ${byte.toRadixString(2).padLeft(8, '0')}'),
            Text('ASCII: ${(byte >= 32 && byte <= 126) ? String.fromCharCode(byte) : 'Non-printable'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DataSection {
  final String title;
  final IconData icon;
  final List<int> data;
  final String? interpretation;

  DataSection({
    required this.title,
    required this.icon,
    required this.data,
    this.interpretation,
  });
}