import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../providers/review_provider.dart';
import '../models/review.dart';
import 'widgets/sidebar.dart';
import 'widgets/insight_card.dart';

class DashboardScreen extends StatefulWidget {
  final String appName;

  const DashboardScreen({super.key, this.appName = "App"});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Config State
  final _apiKeyController = TextEditingController();
  final _appIdController = TextEditingController();
  final _appNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // App State variables
  String _currentAppName = "Visana App";
  String _appAName = "Visana App";
  String _appAId = "1221367995";
  String _appBName = "myPoints";
  String _appBId = "6745941827";

  // Google CSV State
  List<Uint8List>? _appAGoogleCsvs;
  List<String>? _appAGoogleFileNames;
  List<Uint8List>? _appBGoogleCsvs;
  List<String>? _appBGoogleFileNames;

  bool _isAppASelected = true;
  bool _isConfigLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _apiKeyController.text = prefs.getString('gemini_api_key') ?? '';
      _appAName = prefs.getString('appA_name') ?? "Visana App";
      _appAId = prefs.getString('appA_id') ?? "1221367995";
      _appBName = prefs.getString('appB_name') ?? "myPoints";
      _appBId = prefs.getString('appB_id') ?? "6745941827";

      // Default selection
      _isAppASelected = true;
      _updateControllers();
      _currentAppName = _isAppASelected ? _appAName : _appBName;
    });

    // Auto-show config if key is missing
    if (_apiKeyController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfigDialog(context);
      });
    }
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

    // Save current fields to state
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
      setState(() => _isConfigLoading = true);
      Navigator.of(context).pop(); // Close dialog

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

        setState(() {
          _currentAppName = _isAppASelected ? _appAName : _appBName;
        });
      } finally {
        if (mounted) {
          setState(() => _isConfigLoading = false);
        }
      }
    }
  }

  void _showConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Konfiguration"),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App Selector
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text(_appAName),
                                selected: _isAppASelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _saveSettings();
                                    setState(() {
                                      _isAppASelected = true;
                                      _updateControllers();
                                    });
                                    setDialogState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: Text(_appBName),
                                selected: !_isAppASelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _saveSettings();
                                    setState(() {
                                      _isAppASelected = false;
                                      _updateControllers();
                                    });
                                    setDialogState(() {});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // App Config
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
                            setDialogState(() {}); // Update chips
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _appIdController,
                          decoration: const InputDecoration(
                            labelText: "Apple App-ID",
                            border: OutlineInputBorder(),
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
                        const SizedBox(height: 24),

                        // Google CSV
                        const Text(
                          "Google Play CSV",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _pickGoogleFile();
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            (_isAppASelected
                                        ? _appAGoogleFileNames
                                        : _appBGoogleFileNames) !=
                                    null
                                ? "${(_isAppASelected ? _appAGoogleFileNames : _appBGoogleFileNames)!.length} Dateien"
                                : "CSV hochladen",
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // API Key
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: "Gemini API-Key",
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.vpn_key),
                          ),
                          obscureText: true,
                          validator: (v) => v!.isEmpty ? "Benötigt" : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                  onPressed: _performAnalysis,
                  child: const Text("Speichern & Analysieren"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Row(
        children: [
          // Sidebar (Visible on large screens)
          if (MediaQuery.of(context).size.width > 900) const Sidebar(),

          // Main Content
          Expanded(
            child: Consumer<ReviewProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    // Header
                    _buildHeader(context, provider),

                    // Scrollable Area
                    Expanded(
                      child: provider.isLoading || _isConfigLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Intro Section
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      const Text(
                                        "Gemini Insights Comparison",
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Aktualisiert vor wenigen Augenblicken",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Detaillierte KI-gestützte Analyse der App-Store-Bewertungen für $_currentAppName.",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  if (provider.appleReviews.isEmpty &&
                                      provider.googleReviews.isEmpty)
                                    Center(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.analytics_outlined,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          const Text("Keine Daten geladen."),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _showConfigDialog(context),
                                            child: const Text(
                                              "Konfiguration öffnen & Daten laden",
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    _buildInsightsContent(context, provider),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, ReviewProvider provider) {
    return Column(
      children: [
        // Insights Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InsightCard(
                      title: "Apple App Store",
                      iconUrl:
                          "https://upload.wikimedia.org/wikipedia/commons/6/64/Apple_App_Store_icon_2017.png",
                      insights: provider.appleInsights,
                      isNegative: provider.appleInsights.verdict == "NEGATIVE",
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: InsightCard(
                      title: "Google Play Store",
                      iconUrl:
                          "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Google_Play_2022_logo.svg/512px-Google_Play_2022_logo.svg.png",
                      insights: provider.googleInsights,
                      isNegative: provider.googleInsights.verdict == "NEGATIVE",
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  InsightCard(
                    title: "Apple App Store",
                    iconUrl:
                        "https://upload.wikimedia.org/wikipedia/commons/6/64/Apple_App_Store_icon_2017.png",
                    insights: provider.appleInsights,
                    isNegative: provider.appleInsights.verdict == "NEGATIVE",
                  ),
                  const SizedBox(height: 24),
                  InsightCard(
                    title: "Google Play Store",
                    iconUrl:
                        "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Google_Play_2022_logo.svg/512px-Google_Play_2022_logo.svg.png",
                    insights: provider.googleInsights,
                    isNegative: provider.googleInsights.verdict == "NEGATIVE",
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 48),

        // Recommendations Section (Derived from Advice)
        _buildRecommendations(context, provider),

        const SizedBox(height: 48),

        // Review List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Individuelle Reviews",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewList(provider.appleReviews, true),
        const SizedBox(height: 16),
        _buildReviewList(provider.googleReviews, false),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ReviewProvider provider) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width <= 900)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {}, // TODO: Open drawer
                ),
              Text(
                "Analyse: $_currentAppName",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Konfiguration",
            onPressed: () => _showConfigDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, ReviewProvider provider) {
    final allAdvice = [
      ...provider.appleInsights.advice,
      ...provider.googleInsights.advice,
    ].take(4).toList();

    if (allAdvice.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            const Text(
              "Empfohlene Massnahmen",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive Wrap logic
            final double availableWidth = constraints.maxWidth;
            // Target width per card ~300px
            int columns = (availableWidth / 300).floor();
            if (columns < 1) columns = 1;

            // Calculate exact width to fill space
            // formula: (totalWidth - (n-1)*spacing) / n
            final double spacing = 16.0;
            final double itemWidth =
                (availableWidth - (columns - 1) * spacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: allAdvice.map((advice) {
                return Container(
                  width: itemWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Handlungsempfehlung",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        advice,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                        // Removed maxLines and overflow to show full text
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewList(List<Review> reviews, bool isApple) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.take(5).length, // Show top 5
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade400,
                        child: const Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                review.author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isApple ? Icons.apple : Icons.android,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < review.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: i < review.rating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    "${review.date.day}.${review.date.month}.${review.date.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                review.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF334155), // Slate 700
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
