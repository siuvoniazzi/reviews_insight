import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../providers/review_provider.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiKeyController = TextEditingController();
  final _appIdController = TextEditingController();
  final _appNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State for App A
  String _appAName = "Visana App";
  String _appAId = "1221367995";
  List<Uint8List>? _appAGoogleCsvs;
  List<String>? _appAGoogleFileNames;

  // State for App B
  String _appBName = "myPoints";
  String _appBId = "6745941827";
  List<Uint8List>? _appBGoogleCsvs;
  List<String>? _appBGoogleFileNames;

  bool _isAppASelected = true; // Toggle state

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _appAName = prefs.getString('appA_name') ?? "Visana App";
      _appAId = prefs.getString('appA_id') ?? "1221367995";
      _appBName = prefs.getString('appB_name') ?? "myPoints";
      _appBId = prefs.getString('appB_id') ?? "6745941827";
      _updateControllers();
    });
  }

  void _updateControllers() {
    if (_isAppASelected) {
      _appNameController.text = _appAName;
      _appIdController.text = _appAId;
    } else {
      _appNameController.text = _appBName;
      _appIdController.text = _appBId;
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _apiKeyController.text);

    // Save current values to state first
    if (_isAppASelected) {
      _appAName = _appNameController.text;
      _appAId = _appIdController.text;
    } else {
      _appBName = _appNameController.text;
      _appBId = _appIdController.text;
    }

    await prefs.setString('appA_name', _appAName);
    await prefs.setString('appA_id', _appAId);
    await prefs.setString('appB_name', _appBName);
    await prefs.setString('appB_id', _appBId);
  }

  Future<void> _pickGoogleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        if (_isAppASelected) {
          _appAGoogleCsvs = result.files.map((f) => f.bytes!).toList();
          _appAGoogleFileNames = result.files.map((f) => f.name).toList();
        } else {
          _appBGoogleCsvs = result.files.map((f) => f.bytes!).toList();
          _appBGoogleFileNames = result.files.map((f) => f.name).toList();
        }
      });
    }
  }

  Future<void> _performAnalysis() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _saveSettings();

        final provider = Provider.of<ReviewProvider>(context, listen: false);
        provider.setApiKey(_apiKeyController.text);
        provider.clearReviews();

        // 1. Fetch Apple Reviews
        await provider.fetchAppleReviews(_appIdController.text);

        // 2. Set Google Reviews if available
        final currentGoogleCsvs = _isAppASelected
            ? _appAGoogleCsvs
            : _appBGoogleCsvs;
        if (currentGoogleCsvs != null) {
          await provider.setGoogleReviewsFromBytes(currentGoogleCsvs);
        }

        // 3. Analyze
        await provider.analyze();

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                appName: _isAppASelected ? _appAName : _appBName,
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Einblicke App')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "App-Bewertungen analysieren",
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),

                // ... (rest of the file remains, handled by replacement chunks) ...
                const SizedBox(height: 16),
                const Text(
                  "Wählen Sie eine App und laden Sie die neuesten Daten.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // API Key Input
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: "Gemini API-Schlüssel",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? "API-Schlüssel ist erforderlich" : null,
                ),
                const SizedBox(height: 24),

                // App Selector Toggle
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(_appAName),
                        selected: _isAppASelected,
                        onSelected: (selected) {
                          if (selected) {
                            _saveSettings(); // save current B state
                            setState(() {
                              _isAppASelected = true;
                              _updateControllers();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(_appBName),
                        selected: !_isAppASelected,
                        onSelected: (selected) {
                          if (selected) {
                            _saveSettings(); // save current A state
                            setState(() {
                              _isAppASelected = false;
                              _updateControllers();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Config Inputs
                TextFormField(
                  controller: _appNameController,
                  decoration: const InputDecoration(
                    labelText: "App Name",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (_isAppASelected)
                        _appAName = val;
                      else
                        _appBName = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _appIdController,
                  decoration: const InputDecoration(
                    labelText: "Apple App-ID",
                    border: OutlineInputBorder(),
                    helperText: "z.B. 1221367995",
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (_isAppASelected)
                        _appAId = val;
                      else
                        _appBId = val;
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Google File Picker
                ListTile(
                  title: const Text("Google Play Store CSV (Optional)"),
                  subtitle: Text(
                    (_isAppASelected
                                ? _appAGoogleFileNames
                                : _appBGoogleFileNames) !=
                            null
                        ? "${(_isAppASelected ? _appAGoogleFileNames : _appBGoogleFileNames)!.length} Dateien ausgewählt"
                        : "Keine Datei ausgewählt",
                  ),
                  leading: const Icon(Icons.android),
                  trailing: ElevatedButton(
                    onPressed: _pickGoogleFile,
                    child: const Text("Upload"),
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _saveSettings(); // Ensure checks functionality

                      final provider = Provider.of<ReviewProvider>(
                        context,
                        listen: false,
                      );
                      provider.setApiKey(_apiKeyController.text);
                      provider.clearReviews(); // Clear previous

                      // 1. Fetch Apple Reviews
                      await provider.fetchAppleReviews(_appIdController.text);

                      // 2. Set Google Reviews if available
                      final currentGoogleCsvs = _isAppASelected
                          ? _appAGoogleCsvs
                          : _appBGoogleCsvs;
                      if (currentGoogleCsvs != null) {
                        await provider.setGoogleReviewsFromBytes(
                          currentGoogleCsvs,
                        );
                      }

                      // 3. Analyze
                      await provider.analyze();

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(
                              appName: _isAppASelected ? _appAName : _appBName,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text("Daten Laden & Analysieren"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
