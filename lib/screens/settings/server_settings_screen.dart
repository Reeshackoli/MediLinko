import 'package:flutter/material.dart';
import '../../core/constants/api_config.dart';

/// Settings screen to configure backend server URL
/// Allows users to change API endpoint without recompiling app
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testResult;

  // Preset options for quick selection
  final List<Map<String, String>> _presets = [
    {'name': 'Localhost (Emulator/Web)', 'url': 'http://localhost:3000/api'},
    {'name': 'Current WiFi IP', 'url': 'http://10.40.93.175:3000/api'},
    {'name': 'Previous WiFi IP', 'url': 'http://192.168.29.106:3000/api'},
    {'name': 'Ngrok Tunnel', 'url': 'https://your-ngrok-url.ngrok-free.app/api'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    setState(() => _isLoading = true);
    try {
      final savedUrl = await ApiConfig.getSavedUrl();
      _urlController.text = savedUrl ?? ApiConfig.baseUrl;
    } catch (e) {
      _urlController.text = ApiConfig.baseUrl;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final url = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
      await ApiConfig.setUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Backend URL saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (_urlController.text.trim().isEmpty) {
      setState(() => _testResult = '❌ Enter a URL first');
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final url = _urlController.text.trim().replaceAll(RegExp(r'/api$'), '');
      // Simple validation
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        setState(() {
          _testResult = '❌ Invalid URL format';
          _isTesting = false;
        });
        return;
      }

      setState(() {
        _testResult = '✓ URL format is valid\n(Tap Save to apply)';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Invalid URL: $e';
        _isTesting = false;
      });
    }
  }

  void _usePreset(String url) {
    setState(() {
      _urlController.text = url;
      _testResult = null;
    });
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default?'),
        content: const Text('This will clear your custom URL and use the default IP address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiConfig.resetToDefault();
        _urlController.text = ApiConfig.baseUrl;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reset to default URL')),
          );
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to default',
            onPressed: _resetToDefault,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Backend Server Configuration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Set your backend server URL here. This allows you to:'
                              '\n• Use the app on any WiFi network'
                              '\n• Connect to ngrok tunnels'
                              '\n• Switch between local and cloud servers',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // URL input
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Backend URL',
                        hintText: 'http://your-ip:3000/api',
                        prefixIcon: const Icon(Icons.link),
                        border: const OutlineInputBorder(),
                        helperText: 'Enter full URL including http:// or https://',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a URL';
                        }
                        try {
                          final uri = Uri.parse(value);
                          if (!uri.hasScheme) {
                            return 'URL must start with http:// or https://';
                          }
                        } catch (e) {
                          return 'Invalid URL format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Test button
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_isTesting ? 'Testing...' : 'Test URL Format'),
                    ),

                    // Test result
                    if (_testResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!.startsWith('✓')
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testResult!.startsWith('✓')
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            color: _testResult!.startsWith('✓')
                                ? Colors.green.shade900
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Quick presets
                    Text(
                      'Quick Presets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...(_presets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: () => _usePreset(preset['url']!),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset['url']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()),

                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveUrl,
                      icon: const Icon(Icons.save),
                      label: const Text('Save & Apply'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Help text
                    Card(
                      color: Colors.amber.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'How to find your IP:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Windows: Run "ipconfig" in Command Prompt\n'
                              '2. Look for "IPv4 Address"\n'
                              '3. Use format: http://YOUR_IP:3000/api',
                              style: TextStyle(fontSize: 12),
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
