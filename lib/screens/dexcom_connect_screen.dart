import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glucose_provider.dart';
import '../theme/app_theme.dart';
import 'package:dexcom/dexcom.dart';
import 'health_screen.dart';

/// COMPATIBLE DexcomConnectScreen - Same structure, better error display
/// 
/// Changes:
/// 1. Better error message display
/// 2. Enhanced region selector with descriptions
/// 3. Helpful tooltips and guidance
/// 4. All navigation and integration stays the same!

class DexcomConnectScreen extends StatefulWidget {
  const DexcomConnectScreen({super.key});

  @override
  State<DexcomConnectScreen> createState() => _DexcomConnectScreenState();
}

class _DexcomConnectScreenState extends State<DexcomConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  DexcomRegion _selectedRegion = DexcomRegion.ous;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<GlucoseProvider>(context, listen: false);

      try {
        await provider.connectDexcom(
          _usernameController.text.trim(),
          _passwordController.text,
          region: _selectedRegion,
        );

        if (mounted && provider.isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Connected! ${provider.glucoseData.length} readings loaded',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Connection failed: $e'),
              backgroundColor: AppTheme.dangerRed,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final provider = Provider.of<GlucoseProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect from Dexcom?'),
        content: const Text(
          'This will remove your connection and clear all glucose data from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disconnected from Dexcom'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<GlucoseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Dexcom'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Icon(
                Icons.health_and_safety,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Connect Your Dexcom',
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
                'Enter your Dexcom Share credentials to sync your glucose data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 32),

              // ERROR MESSAGE DISPLAY (IMPROVED)
              if (provider.errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.dangerRed.withOpacity(0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.dangerRed,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Connection Issue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Connection Status Card (when connected)
              if (provider.isConnected)
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
                                    '✅ Connected',
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
                            onPressed: _handleDisconnect,
                            icon: const Icon(Icons.logout),
                            label: const Text('Disconnect'),
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

              // Login Form (when not connected)
              if (!provider.isConnected) ...[
                // IMPROVED Region Selection with better descriptions
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
                            Text(
                              'Server Region',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : AppTheme.darkGray,
                              ),
                            ),
                            SizedBox(width: 8),
                            Tooltip(
                              message: 'Select the region matching where you downloaded the DexCom app',
                              child: Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<DexcomRegion>(
                          value: _selectedRegion,
                          decoration: InputDecoration(
                            hintText: 'Select your region',
                            prefixIcon: const Icon(
                              Icons.public,
                              color: AppTheme.primaryBlue,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: DexcomRegion.us,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text('🇺🇸 ', style: TextStyle(fontSize: 20)),
                                      Text('United States'),
                                    ],
                                  ),
                                  Text(
                                    'For US App Store accounts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: DexcomRegion.ous,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text('🌍 ', style: TextStyle(fontSize: 20)),
                                      Text('Outside US'),
                                    ],
                                  ),
                                  Text(
                                    'EU, UK, Canada, Australia',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: DexcomRegion.jp,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text('🇯🇵 ', style: TextStyle(fontSize: 20)),
                                      Text('Japan'),
                                    ],
                                  ),
                                  Text(
                                    'For Japanese accounts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRegion = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Username Field
                Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[400]
                                : AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email, username, or phone number',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: AppTheme.primaryBlue,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Dexcom username';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                Card(
                  elevation: 0,
                  color: isDark ? AppTheme.darkCard : AppTheme.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[400]
                                : AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your Dexcom password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: AppTheme.primaryBlue,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkSurface
                                : AppTheme.lightGray,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Dexcom password';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Health integration quick link
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HealthScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.health_and_safety),
                    label: const Text('Open Health Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Connect Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: provider.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Connecting...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Connect to Dexcom',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info Card (IMPROVED)
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
                            'Before Connecting',
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
                        '✅ Enable Share in your DexCom app (Settings → Share)\n\n'
                        '✅ Add at least 1 follower (can be yourself)\n\n'
                        '✅ Ensure your G7 sensor is active\n\n'
                        '✅ Select the correct region:\n'
                        '    • US App Store → United States\n'
                        '    • EU/UK/Canada → Outside US\n\n'
                        '🔒 Your credentials are secure and only used for DexCom',
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
            ],
          ),
        ),
      ),
    );
  }
}