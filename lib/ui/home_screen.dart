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
  final _formKey = GlobalKey<FormState>();

  Uint8List? _appleCsvBytes;
  String? _appleFileName;

  Uint8List? _googleCsvBytes;
  String? _googleFileName;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = savedKey;
      });
    }
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }

  Future<void> _pickAppleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _appleCsvBytes = result.files.first.bytes;
        _appleFileName = result.files.first.name;
      });
    }
  }

  Future<void> _pickGoogleFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _googleCsvBytes = result.files.first.bytes;
        _googleFileName = result.files.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews Insight App')),
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
                  "Analyze App Reviews",
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Upload CSV exports from App Store Connect or Google Play Console.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // API Key Input
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: "Gemini API Key",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) =>
                      value!.isEmpty ? "API Key is required" : null,
                ),
                const SizedBox(height: 24),

                // Apple File Picker
                ListTile(
                  title: const Text("Apple App Store CSV"),
                  subtitle: Text(_appleFileName ?? "No file selected"),
                  leading: const Icon(Icons.apple),
                  trailing: ElevatedButton(
                    onPressed: _pickAppleFile,
                    child: const Text("Select File"),
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),

                // Google File Picker
                ListTile(
                  title: const Text("Google Play Store CSV"),
                  subtitle: Text(_googleFileName ?? "No file selected"),
                  leading: const Icon(Icons.android),
                  trailing: ElevatedButton(
                    onPressed: _pickGoogleFile,
                    child: const Text("Select File"),
                  ),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_appleCsvBytes == null && _googleCsvBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please upload at least one CSV file.",
                            ),
                          ),
                        );
                        return;
                      }

                      _saveApiKey(_apiKeyController.text);

                      final provider = Provider.of<ReviewProvider>(
                        context,
                        listen: false,
                      );
                      provider.setApiKey(_apiKeyController.text);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardScreen(),
                        ),
                      );

                      provider.analyzeFiles(
                        appleCsv: _appleCsvBytes,
                        googleCsv: _googleCsvBytes,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text("Start Analysis"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
