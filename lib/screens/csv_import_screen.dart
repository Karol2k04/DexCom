// screens/csv_import_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/glucose_provider.dart';
import '../theme/app_theme.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  bool _isImporting = false;
  String? _importedFileName;

  Future<void> _pickAndImportCsv() async {
    try {
      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = result.files.first;

      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Could not read file data'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
        return;
      }

      setState(() {
        _isImporting = true;
        _importedFileName = file.name;
      });

      final provider = Provider.of<GlucoseProvider>(context, listen: false);

      await provider.importFromCsv(file.bytes!, file.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully imported ${provider.glucoseData.length} readings',
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after successful import
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import failed: $e'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<GlucoseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV Data'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Icon(Icons.upload_file, size: 80, color: AppTheme.primaryBlue),
            const SizedBox(height: 16),

            // Title
            Text(
              'Import Dexcom Clarity CSV',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.white : AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Load glucose data from your Dexcom Clarity export file',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 32),

            // Current status card
            if (provider.dataSource == 'csv')
              Card(
                elevation: 0,
                color: AppTheme.successGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.successGreen,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✅ CSV Data Loaded',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.glucoseData.length} readings loaded',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            provider.clearCsvData();
                            setState(() {
                              _importedFileName = null;
                            });
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Clear CSV Data'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerRed,
                            side: const BorderSide(color: AppTheme.dangerRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Import button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _pickAndImportCsv,
                icon: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Icon(Icons.file_upload),
                label: Text(
                  _isImporting ? 'Importing...' : 'Select CSV File',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 0,
              color: AppTheme.primaryBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Export from Dexcom Clarity',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1️⃣ Log in to clarity.dexcom.com\n\n'
                      '2️⃣ Click on "Reports" in the menu\n\n'
                      '3️⃣ Select your date range\n\n'
                      '4️⃣ Click "Export" and choose CSV format\n\n'
                      '5️⃣ Save the file and import it here\n\n'
                      '📊 The app will display all your glucose readings and statistics\n\n'
                      '💡 You can switch between CSV data and live Dexcom connection anytime',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.grey[300] : AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Supported format card
            Card(
              elevation: 0,
              color: isDark ? AppTheme.darkCard : AppTheme.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Supported File Format',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '✅ Dexcom Clarity CSV exports\n'
                      '✅ Files containing EGV (glucose) readings\n'
                      '✅ Standard Clarity export format\n\n'
                      '⚠️ File must include these columns:\n'
                      '  • Timestamp\n'
                      '  • Event Type\n'
                      '  • Glucose Value (mg/dL)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
