import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/animated_logo.dart';

/// Device Sync Screen
/// Input screen for connecting Sasmita Lens device
class DeviceSyncScreen extends ConsumerStatefulWidget {
  const DeviceSyncScreen({super.key});

  @override
  ConsumerState<DeviceSyncScreen> createState() => _DeviceSyncScreenState();
}

class _DeviceSyncScreenState extends ConsumerState<DeviceSyncScreen> {
  final _deviceIdController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _connectDevice() async {
    final deviceId = _deviceIdController.text.trim();
    
    if (deviceId.isEmpty) {
      _showError('Please enter a device ID');
      return;
    }

    setState(() {
      _isValidating = true;
    });

    // Use the provider to validate and connect
    await ref.read(deviceConnectionProvider.notifier).connectDevice(deviceId);

    setState(() {
      _isValidating = false;
    });

    final connectionState = ref.read(deviceConnectionProvider);
    
    connectionState.when(
      data: (isConnected) {
        if (isConnected) {
          ref.read(deviceIdProvider.notifier).state = deviceId;
          ref.read(isDeviceConnectedProvider.notifier).state = true;
          _showSuccess('Device connected successfully!');
        }
      },
      loading: () {},
      error: (error, _) {
        _showError(error.toString());
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.statusSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isDeviceConnectedProvider);
    final deviceId = ref.watch(deviceIdProvider);
    final connectionState = ref.watch(deviceConnectionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        title: Text(
          'SASMITA LENS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 3,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: AppTheme.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Device Icon with Status
            _DeviceIcon(isConnected: isConnected),
            
            const SizedBox(height: 32),
            
            // Connection Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  // Title
                  Text(
                    isConnected ? 'Device Connected' : 'Sync Device',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    isConnected
                        ? 'Your Sasmita Lens is ready to use'
                        : 'Ensure your lens is turned on and within range.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (!isConnected) ...[
                    // Device ID Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device ID',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _deviceIdController,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 15,
                          decoration: InputDecoration(
                            hintText: 'SAS-XXXX-Lens',
                            prefixIcon: const Icon(
                              Icons.qr_code,
                              color: AppTheme.textMuted,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: AppTheme.backgroundDarker,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppTheme.borderDark,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Connect Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _connectDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: _isValidating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Connecting...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Connect Device',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Help Link
                    TextButton(
                      onPressed: _showHelpDialog,
                      child: Text(
                        'Where do I find my ID?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                    ),
                  ] else ...[
                    // Connected State
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.statusSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.statusSuccess.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.statusSuccess,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sasmita Lens V2',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${deviceId ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.statusSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'CONNECTED',
                                style: TextStyle(
                                  color: AppTheme.statusSuccess,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Disconnect Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(deviceConnectionProvider.notifier).disconnect();
                          ref.read(isDeviceConnectedProvider.notifier).state = false;
                          ref.read(deviceIdProvider.notifier).state = null;
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusError,
                          side: const BorderSide(color: AppTheme.statusError),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Disconnect Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Finding Your Device ID',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Sasmita Lens device ID can be found in the following locations:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildHelpItem('1. On the device label (back of the lens)'),
            _buildHelpItem('2. In the device packaging box'),
            _buildHelpItem('3. In the user manual'),
            _buildHelpItem('4. Format: SAS-XXXX-Lens'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Device Icon with Connection Status
class _DeviceIcon extends StatelessWidget {

  const _DeviceIcon({required this.isConnected});
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected
                ? AppTheme.statusSuccess.withOpacity(0.1)
                : AppTheme.primaryGreen.withOpacity(0.1),
          ),
        ),
        
        // Middle circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected
                ? AppTheme.statusSuccess.withOpacity(0.15)
                : AppTheme.backgroundCard,
            border: Border.all(
              color: isConnected
                  ? AppTheme.statusSuccess.withOpacity(0.3)
                  : AppTheme.borderDark,
              width: 2,
            ),
          ),
          child: Icon(
            isConnected ? Icons.check_circle : Icons.qr_code_scanner,
            color: isConnected ? AppTheme.statusSuccess : AppTheme.primaryGreen,
            size: 40,
          ),
        ),
        
        // Status badge
        Positioned(
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.statusSuccess : AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'CONNECTED' : 'SCANNING',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
