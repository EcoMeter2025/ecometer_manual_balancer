import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _BalanceMode {
  quickCheck, // initial data entry + quick check
  balancing, // walk outlet vs key, locking them in
  finalCheck, // re-measure everything once at the very end
}

/// Simple settings wrapper using SharedPreferences
class AppSettings {
  static const _keyDarkMode = 'darkMode';
  static const _keyBalanceToIdeal = 'balanceToIdeal';

  // THEME
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? true; // default DARK
  }

  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  // BALANCING MODE (false = DESIGN, true = IDEAL)
  static Future<bool> getBalanceToIdeal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBalanceToIdeal) ?? false; // default DESIGN mode
  }

  static Future<void> setBalanceToIdeal(bool balanceToIdeal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBalanceToIdeal, balanceToIdeal);
  }
}

void main() {
  runApp(const EcoMeterApp());
}

class EcoMeterApp extends StatefulWidget {
  const EcoMeterApp({super.key});

  @override
  State<EcoMeterApp> createState() => _EcoMeterAppState();
}

class _EcoMeterAppState extends State<EcoMeterApp> {
  bool _darkMode = true;
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await AppSettings.getDarkMode();
    setState(() {
      _darkMode = dark;
      _settingsLoaded = true;
    });
  }

  Future<void> _refreshTheme() async {
    final dark = await AppSettings.getDarkMode();
    setState(() {
      _darkMode = dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F7F32);

    final ThemeData darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: accent,
      colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: accent,
        secondary: accent,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    final ThemeData lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: accent,
      colorScheme: ThemeData.light().colorScheme.copyWith(
        primary: accent,
        secondary: accent,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );

    if (!_settingsLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'EcoMeter Outlet Balancer',
      debugShowCheckedModeBanner: false,
      theme: _darkMode ? darkTheme : lightTheme,
      home: HomeScreen(onSettingsChanged: _refreshTheme),
    );
  }
}

/// SHARED APP BAR (logo centered, optional back button)
class EcoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;

  const EcoAppBar({super.key, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      automaticallyImplyLeading: false,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/ecometer_logo.png',
                height: 96,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );
  }
}

/// HOME SCREEN
class HomeScreen extends StatelessWidget {
  final VoidCallback onSettingsChanged;

  const HomeScreen({super.key, required this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F7F32);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Scaffold(
      appBar: const EcoAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                children: const [
                  TextSpan(
                    text: 'Pro',
                    style: TextStyle(color: Color(0xFF2F7F32)),
                  ),
                  TextSpan(text: 'Portional Balancing Guide'),
                ],
              ),
            ),
            Text(
              '''from the makers of EcoMeter
Technician Built Tools | TAB Certified Accuracy''',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            _HomeCard(
              title: 'Proportional Balance',
              subtitle: '''
Enter outlet(s) design CFM
Enter outlet(s) measured CFM
Run EcoMeter ProPortional Quick Check.
''',
              icon: Icons.tune,
              enabled: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BalanceCalculatorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const _HomeCard(
              title: 'Full Project Workflow (Pro)',
              subtitle:
                  'Outlet sets, jobs, reports, and cloud backup are coming soon.',
              icon: Icons.assignment,
              enabled: false,
              onTap: null,
            ),
            const SizedBox(height: 12),
            _HomeCard(
              title: 'Settings',
              subtitle:
                  'Theme (dark / light) and default balancing mode (design vs ideal).',
              icon: Icons.settings,
              enabled: true,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                onSettingsChanged();
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'EcoMeter Pro is just getting started.\n'
                'Job storage, reports, and more tools will roll out with the next update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F7F32);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    final bgCard = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111111)
        : Colors.white;
    final borderColor = accent.withOpacity(0.4);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Card(
        color: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, size: 32, color: accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled) Icon(Icons.chevron_right, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// SETTINGS SCREEN
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _balanceToIdeal = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await AppSettings.getDarkMode();
    final ideal = await AppSettings.getBalanceToIdeal();
    if (!mounted) return;
    setState(() {
      _darkMode = dark;
      _balanceToIdeal = ideal;
      _loading = false;
    });
  }

  Future<void> _updateDarkMode(bool value) async {
    setState(() {
      _darkMode = value;
    });
    await AppSettings.setDarkMode(value);
  }

  Future<void> _updateBalancingMode(bool value) async {
    setState(() {
      _balanceToIdeal = value;
    });
    await AppSettings.setBalanceToIdeal(value);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F7F32);
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.black,
        ),
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            activeColor: accent,
            title: Text('Dark mode', style: TextStyle(color: textColor)),
            subtitle: Text(
              'Turn off for light mode (white background).',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
            value: _darkMode,
            onChanged: _updateDarkMode,
          ),
          const SizedBox(height: 24),
          Text(
            'Balancing Mode',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            activeColor: accent,
            value: false,
            groupValue: _balanceToIdeal,
            onChanged: (val) => _updateBalancingMode(val ?? false),
            title: Text(
              'Balance to DESIGN tolerances (recommended)',
              style: TextStyle(color: textColor),
            ),
            subtitle: Text(
              'Once an outlet is within design tolerance (yellow or green), it is not re-balanced.',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
          RadioListTile<bool>(
            activeColor: accent,
            value: true,
            groupValue: _balanceToIdeal,
            onChanged: (val) => _updateBalancingMode(val ?? true),
            title: Text(
              'Balance to IDEAL tolerance (nerd mode)',
              style: TextStyle(color: textColor),
            ),
            subtitle: Text(
              'Continue balancing yellow outlets until everything is in tight green tolerance.',
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== PROPORTIONAL BALANCE SCREEN (OUTLETS) =====

class BalanceCalculatorScreen extends StatefulWidget {
  const BalanceCalculatorScreen({super.key});

  @override
  State<BalanceCalculatorScreen> createState() =>
      _BalanceCalculatorScreenState();
}

class _BalanceCalculatorScreenState extends State<BalanceCalculatorScreen> {
  final ScrollController _scrollController = ScrollController();

  // Tolerances (%)
  final TextEditingController _minusTolController = TextEditingController(
    text: '10',
  );
  final TextEditingController _plusTolController = TextEditingController(
    text: '10',
  );

  // Dynamic outlet list
  final List<_OutletEntry> _outlets = [];

  // Computed results
  int? _keyIndex;
  String? _globalMessage;
  Color _globalMessageColor = Colors.red;

  // Balancing state
  _BalanceMode _mode = _BalanceMode.quickCheck;
  int? _currentBalancingIndex;
  int? _lockedKeyIndex;
  final Set<int> _lockedOutlets = {};
  bool _requiresKeyRecheck = false;

  // System gate
  bool _awaitingSystemFix = false;

  // Final summary
  bool _showFinalSummary = false;

  // Balancing mode: false = DESIGN, true = IDEAL
  bool _balanceToIdeal = false;

  @override
  void initState() {
    super.initState();
    _addOutlet();
    _loadBalancingMode();
  }

  Future<void> _loadBalancingMode() async {
    final ideal = await AppSettings.getBalanceToIdeal();
    if (!mounted) return;
    setState(() {
      _balanceToIdeal = ideal;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _minusTolController.dispose();
    _plusTolController.dispose();
    for (final o in _outlets) {
      o.dispose();
    }
    super.dispose();
  }

  // Focus next measured field and CLEAR its value (for final readings pass)
  void _focusMeasuredAndClear(int index) {
    if (index < 0 || index >= _outlets.length) return;
    final o = _outlets[index];
    final controller = o.measuredController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      controller.text = '';
      FocusScope.of(context).requestFocus(o.measuredFocus);
      controller.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  // Focus measured field and select text
  void _focusMeasuredAndSelect(int index) {
    if (index < 0 || index >= _outlets.length) return;
    final o = _outlets[index];
    final controller = o.measuredController;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(o.measuredFocus);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  // ===== ENTER KEY BEHAVIOR =====

  // Design CFM: walk down column and auto-add
  void _handleDesignSubmitted(int index) {
    if (index < 0 || index >= _outlets.length) return;
    final o = _outlets[index];

    final hasDesign = o.designController.text.trim().isNotEmpty;
    if (!hasDesign) return;

    final isLast = index == _outlets.length - 1;

    if (isLast) {
      _addOutlet();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _outlets.isEmpty) return;
        final newOutlet = _outlets.last;
        newOutlet.designFocus.requestFocus();
        _scrollToBottom();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nextOutlet = _outlets[index + 1];
        nextOutlet.designFocus.requestFocus();
        _scrollToBottom();
      });
    }
  }

  // Dispatch based on mode
  void _handleMeasuredSubmitted(int index) {
    switch (_mode) {
      case _BalanceMode.quickCheck:
        _handleMeasuredSubmittedQuickCheck(index);
        break;
      case _BalanceMode.balancing:
        _handleMeasuredSubmittedBalancing(index);
        break;
      case _BalanceMode.finalCheck:
        _handleMeasuredSubmittedFinal(index);
        break;
    }
  }

  // QUICK CHECK: walk measured column, stop at last designed outlet
  void _handleMeasuredSubmittedQuickCheck(int index) {
    if (index < 0 || index >= _outlets.length) return;
    final o = _outlets[index];

    final hasMeasured = o.measuredController.text.trim().isNotEmpty;
    if (!hasMeasured) return;

    // last index with non-empty Design
    int lastDesignIndex = -1;
    for (int i = 0; i < _outlets.length; i++) {
      if (_outlets[i].designController.text.trim().isNotEmpty) {
        lastDesignIndex = i;
      }
    }

    if (lastDesignIndex == -1) {
      final isLastRow = index == _outlets.length - 1;
      if (!isLastRow) {
        _focusMeasuredAndSelect(index + 1);
      } else {
        FocusScope.of(context).unfocus();
      }
      return;
    }

    if (index > lastDesignIndex) {
      final isLastRow = index == _outlets.length - 1;
      if (!isLastRow) {
        _focusMeasuredAndSelect(index + 1);
      } else {
        FocusScope.of(context).unfocus();
      }
      return;
    }

    if (index < lastDesignIndex) {
      _focusMeasuredAndSelect(index + 1);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  // Scroll so a specific outlet row is visible
  void _scrollToOutletRow(int index) {
    if (index < 0 || index >= _outlets.length) return;
    final ctx = _outlets[index].rowKey.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.25,
    );
  }

  // BALANCING: target ↔ key dance
  void _handleMeasuredSubmittedBalancing(int index) {
    if (_keyIndex == null) return;

    // 1) Finished typing on current non-key target → tell them to re-measure key
    if (_currentBalancingIndex != null &&
        index == _currentBalancingIndex &&
        index != _keyIndex) {
      setState(() {
        _globalMessage =
            'Adjustment recorded for ${_outlets[index].nameController.text}.\n'
            'Re-measure the key outlet: ${_outlets[_keyIndex!].nameController.text}.';
        _globalMessageColor = Colors.white;
        _requiresKeyRecheck = true;
      });

      _focusMeasuredAndSelect(_keyIndex!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToOutletRow(_keyIndex!);
      });

      return;
    }

    // 2) Finished typing on KEY → recalc, then decide what’s next
    if (index == _keyIndex) {
      setState(() {
        _requiresKeyRecheck = false;
      });

      _recalculateAllWithLockedKey();

      final lastTargetIndex = _currentBalancingIndex;

      if (lastTargetIndex != null &&
          lastTargetIndex != _keyIndex &&
          _isWithinDesignTolerance(_outlets[lastTargetIndex])) {
        _lockedOutlets.add(lastTargetIndex);
      }

      final next = _findNextBalancingOutlet();

      if (next == null) {
        setState(() {
          _mode = _BalanceMode.finalCheck;
          _globalMessage =
              'All outlets have been brought within design tolerance.\n'
              'Adjust total flow as needed & re-measure ALL outlets for final check.';
          _globalMessageColor = Colors.green;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToTop();
        });

        return;
      }

      _currentBalancingIndex = next;
      final nextName = _outlets[next].nameController.text;
      final estimate = _computeEstimatedTargetCFM(next);

      setState(() {
        _mode = _BalanceMode.balancing;
        _globalMessage =
            'Key updated.\n'
            'Next, balance $nextName.\n'
            'Adjust $nextName until it is within tolerance of the key outlet.'
            '${estimate != null ? '\n\nEstimated target for $nextName: ${estimate.toStringAsFixed(0)} CFM.' : ''}';
        _globalMessageColor = Colors.green;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToTop();
      });

      return;
    }
  }

  // FINAL CHECK: walk measured column, forcing a fresh reading in each field.
  void _handleMeasuredSubmittedFinal(int index) {
    if (index < 0 || index >= _outlets.length) return;

    final isLast = index == _outlets.length - 1;

    if (!isLast) {
      _focusMeasuredAndClear(index + 1);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  // ===== OUTLET LIST MGMT =====

  void _addOutlet() {
    setState(() {
      _outlets.add(_OutletEntry(name: 'Outlet ${_outlets.length + 1}'));
      _keyIndex = null;
      _globalMessage = null;
      _awaitingSystemFix = false;
      _showFinalSummary = false;
    });
  }

  void _removeOutlet(int index) {
    setState(() {
      _outlets[index].dispose();
      _outlets.removeAt(index);
      _keyIndex = null;
      _globalMessage = null;
      _awaitingSystemFix = false;
      _showFinalSummary = false;
    });
  }

  void _resetAll() {
    for (final o in _outlets) {
      o.dispose();
    }
    _outlets.clear();
    _minusTolController.text = '10';
    _plusTolController.text = '10';
    _keyIndex = null;
    _globalMessage = null;
    _mode = _BalanceMode.quickCheck;
    _currentBalancingIndex = null;
    _lockedKeyIndex = null;
    _lockedOutlets.clear();
    _awaitingSystemFix = false;
    _showFinalSummary = false;
    _requiresKeyRecheck = false;

    setState(() {
      _addOutlet();
    });
  }

  // ===== CALC HELPERS =====

  // Treat blank / invalid measured entries as 0 CFM
  double _coerceMeasuredCFM(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0.0;
    final v = double.tryParse(t);
    if (v == null || v < 0) return 0.0;
    return v;
  }

  void _recalculateAllWithLockedKey() {
    final minusTol = double.tryParse(_minusTolController.text) ?? 10;
    final plusTol = double.tryParse(_plusTolController.text) ?? 10;

    for (final o in _outlets) {
      final design = double.tryParse(o.designController.text);
      final measured = _coerceMeasuredCFM(o.measuredController.text);

      if (design == null || design <= 0) {
        o.percentOfDesign = null;
        o.tolOfKey = null;
        o.statusText = 'Invalid input';
        o.statusColor = Colors.grey;
      } else {
        o.percentOfDesign = (measured / design) * 100.0;
        o.tolOfKey = null;
        o.statusText = '';
        o.statusColor = Colors.grey;
      }
    }

    if (_keyIndex == null) {
      setState(() {});
      return;
    }

    final keyOutlet = _outlets[_keyIndex!];
    final keyPercentOfDesign = keyOutlet.percentOfDesign;
    if (keyPercentOfDesign == null || keyPercentOfDesign <= 0) {
      setState(() {});
      return;
    }

    const greenLimit = 1.05;
    final targetUpper = (1 + plusTol / 100) / (1 - minusTol / 100);

    for (final o in _outlets) {
      final pOutlet = o.percentOfDesign;
      final pKey = keyPercentOfDesign;

      if (pOutlet == null) {
        o.tolOfKey = null;
        if (o.statusText.isEmpty) {
          o.statusText = 'Invalid input';
        }
        o.statusColor = Colors.grey;
        continue;
      }

      final larger = pOutlet > pKey ? pOutlet : pKey;
      final smaller = pOutlet > pKey ? pKey : pOutlet;

      if (smaller <= 0) {
        o.tolOfKey = double.infinity;
        o.statusText =
            '– out of tolerance (ratio > ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.red;
        continue;
      }

      final ratio = larger / smaller;
      o.tolOfKey = ratio;

      if (ratio <= greenLimit) {
        o.statusText =
            '– within ideal tolerance (ratio ≤ ${greenLimit.toStringAsFixed(2)})';
        o.statusColor = Colors.green;
      } else if (ratio <= targetUpper) {
        o.statusText =
            '– within design tolerance (ratio ≤ ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.yellow;
      } else {
        o.statusText =
            '– out of tolerance (ratio > ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.red;
      }
    }

    setState(() {});
  }

  bool _isWithinIdealTolerance(_OutletEntry o) {
    if (o.tolOfKey == null) return false;
    const double greenLimit = 1.05;
    return o.tolOfKey! <= greenLimit;
  }

  bool _isWithinDesignTolerance(_OutletEntry o) {
    if (_keyIndex == null) return false;
    final pOutlet = o.percentOfDesign;
    final pKey = _outlets[_keyIndex!].percentOfDesign;

    if (pOutlet == null || pKey == null) return false;

    final larger = pOutlet > pKey ? pOutlet : pKey;
    final smaller = pOutlet > pKey ? pKey : pOutlet;
    if (smaller <= 0) return false;

    final ratio = larger / smaller;
    final minusTol = double.tryParse(_minusTolController.text) ?? 10;
    final plusTol = double.tryParse(_plusTolController.text) ?? 10;
    final targetUpper = (1 + plusTol / 100) / (1 - minusTol / 100);

    return ratio <= targetUpper;
  }

  int? _findNextBalancingOutlet() {
    if (_keyIndex == null) return null;

    final key = _outlets[_keyIndex!];
    final keyPercent = key.percentOfDesign;
    if (keyPercent == null) return null;

    int? bestIndex;
    double? bestDistance;

    for (int i = 0; i < _outlets.length; i++) {
      if (i == _keyIndex) continue;
      if (_lockedOutlets.contains(i)) continue;

      final o = _outlets[i];

      if (_balanceToIdeal) {
        if (_isWithinIdealTolerance(o)) {
          continue;
        }
      } else {
        if (_isWithinDesignTolerance(o)) {
          continue;
        }
      }

      final p = o.percentOfDesign;
      if (p == null) continue;

      final distance = (p - keyPercent).abs();

      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  // Estimated target CFM for a given balancing outlet using predictive model
  double? _computeEstimatedTargetCFM(int targetIndex) {
    if (_keyIndex == null) return null;
    if (targetIndex < 0 || targetIndex >= _outlets.length) return null;
    if (targetIndex == _keyIndex) return null;

    final keyOutlet = _outlets[_keyIndex!];
    final targetOutlet = _outlets[targetIndex];

    final dKey = double.tryParse(keyOutlet.designController.text);
    final dTarget = double.tryParse(targetOutlet.designController.text);
    final aKey = double.tryParse(keyOutlet.measuredController.text);
    final aTarget = double.tryParse(targetOutlet.measuredController.text);

    if (dKey == null ||
        dTarget == null ||
        aKey == null ||
        aTarget == null ||
        dKey <= 0 ||
        dTarget <= 0 ||
        aKey <= 0 ||
        aTarget <= 0) {
      return null;
    }

    double totalMeasured = 0;
    for (final o in _outlets) {
      final m = double.tryParse(o.measuredController.text);
      if (m != null && m > 0) {
        totalMeasured += m;
      }
    }
    if (totalMeasured <= 0) return null;

    final denominator =
        (-aTarget * dKey) + (aKey * dTarget) + (dKey * totalMeasured);
    if (denominator.abs() < 1e-9) return null;

    final ajPrime = (aKey * dTarget * totalMeasured) / denominator;
    if (ajPrime.isNaN || ajPrime.isInfinite) return null;

    return ajPrime < 0 ? 0 : ajPrime;
  }

  // ===== MAIN BUTTONS =====

  void _runQuickCheck() {
    if (_mode == _BalanceMode.balancing &&
        _requiresKeyRecheck &&
        _keyIndex != null) {
      setState(() {
        _globalMessage =
            'Re-measure the key outlet: ${_outlets[_keyIndex!].nameController.text} '
            'before running another readiness check.';
        _globalMessageColor = Colors.red;
      });

      _focusMeasuredAndSelect(_keyIndex!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToOutletRow(_keyIndex!);
      });

      return;
    }

    FocusScope.of(context).unfocus();

    _mode = _BalanceMode.quickCheck;
    _currentBalancingIndex = null;
    _lockedKeyIndex = null;
    _lockedOutlets.clear();
    _awaitingSystemFix = false;
    _showFinalSummary = false;
    _requiresKeyRecheck = false;

    setState(() {
      _globalMessage = null;
      _keyIndex = null;
    });

    _outlets.removeWhere(
      (o) =>
          o.designController.text.trim().isEmpty &&
          o.measuredController.text.trim().isEmpty,
    );

    if (_outlets.isEmpty) {
      setState(() {
        _globalMessage = 'Add at least one outlet.';
        _globalMessageColor = Colors.red;
      });
      _scrollToTop();
      return;
    }

    final minusTolRaw = double.tryParse(_minusTolController.text);
    final plusTolRaw = double.tryParse(_plusTolController.text);

    if (minusTolRaw == null || plusTolRaw == null) {
      setState(() {
        _globalMessage = 'Enter valid numeric tolerances.';
        _globalMessageColor = Colors.red;
      });
      _scrollToTop();
      return;
    }

    final double minusTol = minusTolRaw;
    final double plusTol = plusTolRaw;

    double totalDesign = 0;
    double totalMeasured = 0;

    for (final o in _outlets) {
      final design = double.tryParse(o.designController.text);
      final measured = _coerceMeasuredCFM(o.measuredController.text);

      if (design != null) totalDesign += design;
      totalMeasured += measured;

      if (design == null || design <= 0) {
        o.percentOfDesign = null;
        o.tolOfKey = null;
        o.statusText = 'Invalid input';
        o.statusColor = Colors.grey;
      } else {
        o.percentOfDesign = (measured / design) * 100.0;
        o.tolOfKey = null;
        o.statusText = '';
        o.statusColor = Colors.grey;
      }
    }

    int? keyIndex;
    double? lowestPercent;

    for (int i = 0; i < _outlets.length; i++) {
      final o = _outlets[i];

      final design = double.tryParse(o.designController.text);
      final measuredRaw = double.tryParse(o.measuredController.text.trim());

      final hasValidKeyMeasurement =
          design != null &&
          design > 0 &&
          measuredRaw != null &&
          measuredRaw > 0;

      if (!hasValidKeyMeasurement) {
        continue;
      }

      if (o.percentOfDesign != null) {
        if (lowestPercent == null || o.percentOfDesign! < lowestPercent) {
          lowestPercent = o.percentOfDesign!;
          keyIndex = i;
        }
      }
    }

    if (keyIndex == null || lowestPercent == null) {
      setState(() {
        _globalMessage =
            'No valid outlets. Ensure at least one outlet has design CFM and measured CFM > 0.';
        _globalMessageColor = Colors.red;
      });
      _scrollToTop();
      return;
    }

    final keyPercentOfDesign = lowestPercent;

    const greenLimit = 1.05;
    final targetUpper = (1 + plusTol / 100) / (1 - minusTol / 100);

    bool allWithinDesignTol = true;

    for (final o in _outlets) {
      final pOutlet = o.percentOfDesign;
      final pKey = keyPercentOfDesign;

      if (pOutlet == null) {
        o.tolOfKey = null;
        o.statusText = o.statusText.isEmpty ? 'Invalid input' : o.statusText;
        o.statusColor = Colors.grey;
        allWithinDesignTol = false;
        continue;
      }

      final larger = pOutlet > pKey ? pOutlet : pKey;
      final smaller = pOutlet > pKey ? pKey : pOutlet;

      if (smaller <= 0) {
        o.tolOfKey = double.infinity;
        o.statusText =
            '– out of tolerance (ratio > ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.red;
        allWithinDesignTol = false;
        continue;
      }

      final ratio = larger / smaller;
      o.tolOfKey = ratio;

      if (ratio <= greenLimit) {
        o.statusText =
            '– within ideal tolerance (ratio ≤ ${greenLimit.toStringAsFixed(2)})';
        o.statusColor = Colors.green;
      } else if (ratio <= targetUpper) {
        o.statusText =
            '– within design tolerance (ratio ≤ ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.yellow;
      } else {
        o.statusText =
            '– out of tolerance (ratio > ${targetUpper.toStringAsFixed(2)})';
        o.statusColor = Colors.red;
        allWithinDesignTol = false;
      }
    }

    double? totalPercent;
    bool systemWithinJobTol = false;

    if (totalDesign > 0 && totalMeasured > 0) {
      totalPercent = (totalMeasured / totalDesign) * 100.0;
      final low = 100 - minusTol;
      final high = 100 + plusTol;
      systemWithinJobTol = totalPercent >= low && totalPercent <= high;
    }

    if (allWithinDesignTol && systemWithinJobTol && totalPercent != null) {
      setState(() {
        _keyIndex = keyIndex;
        _mode = _BalanceMode.finalCheck;
        _globalMessage =
            'Proportional Check complete.\n'
            '• All outlets are within design tolerance.\n'
            '• System total is ${totalPercent!.toStringAsFixed(1)} % of design '
            '(within ${minusTol.toStringAsFixed(0)}–${plusTol.toStringAsFixed(0)} %).\n'
            '\nYou can proceed with final readings.';
        _globalMessageColor = Colors.green;
      });

      _scrollToTop();
      return;
    }

    if (totalDesign > 0 && totalMeasured > 0) {
      final totalPercentForGate = (totalMeasured / totalDesign) * 100.0;

      if (totalPercentForGate < 80.0 || totalPercentForGate > 120.0) {
        setState(() {
          _keyIndex = keyIndex;
          _mode = _BalanceMode.quickCheck;
          _awaitingSystemFix = true;
          _globalMessage =
              'Readiness Check complete.\n'
              'System total is ${totalPercentForGate.toStringAsFixed(1)} % of design.\n'
              'You must be between 80–120 % of design before balancing outlets.\n\n'
              'Adjust fan speed and/or branch dampers to bring this outlet group '
              'within 80 % of design, then re-run Readiness Check.';
          _globalMessageColor = Colors.red;
        });

        _scrollToTop();
        return;
      }
    }

    _keyIndex = keyIndex;
    _lockedKeyIndex = keyIndex;
    _lockedOutlets.clear();
    _currentBalancingIndex = _findNextBalancingOutlet();

    if (_currentBalancingIndex == null) {
      setState(() {
        _mode = _BalanceMode.quickCheck;
        _globalMessage =
            'Quick Check complete. No other outlets to balance relative to key.';
        _globalMessageColor = Colors.green;
      });

      _scrollToTop();
      return;
    }

    final firstTarget = _currentBalancingIndex!;
    final targetName = _outlets[firstTarget].nameController.text;
    final estimate = _computeEstimatedTargetCFM(firstTarget);

    setState(() {
      _mode = _BalanceMode.balancing;
      _globalMessage =
          'Readiness Check complete.\n'
          'Key outlet is ${_outlets[_keyIndex!].nameController.text}.\n'
          'Begin balancing at $targetName.\n'
          'Adjust $targetName until it is within tolerance of the key outlet.'
          '${estimate != null ? '\n\nEstimated target for $targetName: ${estimate.toStringAsFixed(0)} CFM.' : ''}';
      _globalMessageColor = Colors.green;
    });

    _scrollToTop();
  }

  void _finishFinalReadings() {
    FocusScope.of(context).unfocus();

    _recalculateAllWithLockedKey();

    double totalDesign = 0;
    double totalMeasured = 0;

    for (final o in _outlets) {
      final design = double.tryParse(o.designController.text);
      final measured = _coerceMeasuredCFM(o.measuredController.text);

      if (design != null) totalDesign += design;
      totalMeasured += measured;
    }

    final minusTol = double.tryParse(_minusTolController.text) ?? 10;
    final plusTol = double.tryParse(_plusTolController.text) ?? 10;

    double? totalPercent;
    if (totalDesign > 0 && totalMeasured > 0) {
      totalPercent = (totalMeasured / totalDesign) * 100.0;
    }

    if (totalPercent != null) {
      final low = 100 - minusTol;
      final high = 100 + plusTol;

      if (totalPercent < low || totalPercent > high) {
        setState(() {
          _showFinalSummary = false;
          _mode = _BalanceMode.finalCheck;
          _globalMessage =
              'Final system total is ${totalPercent!.toStringAsFixed(1)} % of design.\n'
              'This is outside the project tolerance of '
              '${minusTol.toStringAsFixed(0)}–${plusTol.toStringAsFixed(0)} %.\n\n'
              'Adjust fan speed and/or branch dampers to bring the system total back '
              'within tolerance, then re-measure ALL outlets and run Final Readings again.';
          _globalMessageColor = Colors.red;
        });
        _scrollToTop();
        return;
      }
    }

    bool allWithinDesignTol = true;
    final targetUpper = (1 + plusTol / 100.0) / (1 - minusTol / 100.0);

    for (final o in _outlets) {
      final tol = o.tolOfKey;
      if (tol != null && tol > targetUpper) {
        allWithinDesignTol = false;
        break;
      }
    }

    if (!allWithinDesignTol) {
      int? worstIndex;
      double? worstTol;

      for (int i = 0; i < _outlets.length; i++) {
        final tol = _outlets[i].tolOfKey;
        if (tol != null && tol > targetUpper) {
          if (worstTol == null || tol > worstTol) {
            worstTol = tol;
            worstIndex = i;
          }
        }
      }

      if (_keyIndex != null && worstIndex != null) {
        _mode = _BalanceMode.balancing;
        _showFinalSummary = false;
        _currentBalancingIndex = worstIndex;
        _lockedOutlets.clear();

        final targetName = _outlets[worstIndex].nameController.text;
        final estimate = _computeEstimatedTargetCFM(worstIndex);
        final keyName = _outlets[_keyIndex!].nameController.text;

        setState(() {
          _globalMessage =
              'Final system total is within project tolerance, but one or more outlets '
              'are still out of design tolerance.\n\n'
              'Key outlet is $keyName.\n'
              'Next, balance $targetName.\n'
              'Adjust $targetName until it is within tolerance of the key outlet.'
              '${estimate != null ? '\n\nEstimated target for $targetName: ${estimate.toStringAsFixed(0)} CFM.' : ''}';
          _globalMessageColor = Colors.red;
        });

        _scrollToTop();
        return;
      }
    }

    setState(() {
      _showFinalSummary = true;
      _mode = _BalanceMode.finalCheck;
      _globalMessage =
          'Final readings locked in.\n'
          'System total is ${totalPercent?.toStringAsFixed(1) ?? '—'} % of design '
          '(within ${minusTol.toStringAsFixed(0)}–${plusTol.toStringAsFixed(0)} %).';
      _globalMessageColor = Colors.green;
    });
    _scrollToTop();
  }

  // ===== SCROLL HELPERS =====

  void _scrollToTop() {
    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onRecheckAfterSystemFix() {
    for (final o in _outlets) {
      o.percentOfDesign = null;
      o.tolOfKey = null;
      o.statusText = '';
      o.statusColor = Colors.grey;
    }

    setState(() {
      _globalMessage = null;
      _globalMessageColor = Colors.red;
      _mode = _BalanceMode.quickCheck;
      _keyIndex = null;
      _currentBalancingIndex = null;
      _lockedKeyIndex = null;
      _lockedOutlets.clear();
      _awaitingSystemFix = false;
      _showFinalSummary = false;
      _requiresKeyRecheck = false;
    });

    _focusMeasuredAndSelect(0);
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2F7F32);
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    double totalDesign = 0;
    double totalMeasured = 0;
    for (final o in _outlets) {
      final d = double.tryParse(o.designController.text);
      final m = double.tryParse(o.measuredController.text);
      if (d != null) totalDesign += d;
      if (m != null) totalMeasured += m;
    }

    double? totalPercentOfDesign;
    if (totalDesign > 0 && totalMeasured > 0) {
      totalPercentOfDesign = (totalMeasured / totalDesign) * 100.0;
    }

    return Scaffold(
      appBar: const EcoAppBar(showBack: true),
      resizeToAvoidBottomInset: true,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            controller: _scrollController,
            children: [
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Pro',
                      style: TextStyle(color: Color(0xFF2F7F32)),
                    ),
                    TextSpan(text: 'Portional Balance Guide'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_mode == _BalanceMode.quickCheck) ...[
                Text(
                  '1) Enter the DESIGN CFM for each outlet.\n'
                  '2) Enter the MEASURED CFM for each outlet.\n'
                  '3) When your readings are in, tap "CHECK PROPORTIONAL READINESS" to lock the key outlet and start balancing.\n\n'
                  'If the system total is between 80–120 % of design, you\'ll be guided into balancing mode.\n'
                  'Once you are in balancing mode, use the Save Reading buttons to walk back and forth between the current outlet and the key.',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
              ] else
                const SizedBox(height: 8),
              if (_globalMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _globalMessageColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _globalMessage!,
                        style: TextStyle(color: _globalMessageColor),
                      ),
                      if (_awaitingSystemFix) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _onRecheckAfterSystemFix,
                          child: const Text(
                            'Modifications Have Been Made – Recheck All Outlets',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Text(
                'Tolerances (%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: 'Minus tolerance',
                      controller: _minusTolController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      label: 'Plus tolerance',
                      controller: _plusTolController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Outlets',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              if (_outlets.isEmpty)
                Text(
                  'No outlets added.',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
              for (int i = 0; i < _outlets.length; i++) _buildOutletCard(i),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addOutlet,
                  child: const Text('+ Add Outlet'),
                ),
              ),
              if (_outlets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: textColor.withOpacity(0.24)),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF111111)
                        : Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Totals',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Design: ${totalDesign.toStringAsFixed(0)} CFM   '
                        'Measured: ${totalMeasured.toStringAsFixed(0)} CFM',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                      if (totalPercentOfDesign != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '% of design: ${totalPercentOfDesign.toStringAsFixed(1)} %',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_mode == _BalanceMode.balancing &&
                  _keyIndex != null &&
                  _currentBalancingIndex != null) ...[
                const SizedBox(height: 16),
                _buildBalancingPanel(),
              ],
              if (_showFinalSummary) ...[
                const SizedBox(height: 16),
                _buildFinalSummary(
                  totalDesign,
                  totalMeasured,
                  totalPercentOfDesign,
                ),
              ],
              const SizedBox(height: 16),
              if (!_showFinalSummary) ...[
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    onPressed: _outlets.isEmpty
                        ? null
                        : (_mode == _BalanceMode.finalCheck
                              ? _finishFinalReadings
                              : (_mode == _BalanceMode.balancing
                                    ? null
                                    : _runQuickCheck)),
                    child: Text(
                      _mode == _BalanceMode.finalCheck
                          ? 'FINISH FINAL READINGS'
                          : 'CHECK PROPORTIONAL READINESS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: _resetAll,
                child: Text(
                  'RESET',
                  style: TextStyle(color: textColor.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 24),
              if (_keyIndex != null) _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutletCard(int index) {
    final o = _outlets[index];
    final isKey = _keyIndex == index;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Container(
      key: o.rowKey,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isKey ? const Color(0xFF2F7F32) : textColor.withOpacity(0.24),
          width: isKey ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: o.nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Outlet name',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: textColor.withOpacity(0.24),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: textColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeOutlet(index),
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Design CFM',
                  controller: o.designController,
                  focusNode: o.designFocus,
                  onSubmitted: (_) => _handleDesignSubmitted(index),
                  onEditingComplete: () => _handleDesignSubmitted(index),
                  onTap: index == 0 ? _scrollToBottom : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  label: 'Measured CFM',
                  controller: o.measuredController,
                  focusNode: o.measuredFocus,
                  onSubmitted: (_) => _handleMeasuredSubmitted(index),
                  onEditingComplete: () => _handleMeasuredSubmitted(index),
                  onChanged: (value) {
                    if (_mode == _BalanceMode.balancing && _keyIndex != null) {
                      if (index == _currentBalancingIndex &&
                          index != _keyIndex) {
                        if (!_requiresKeyRecheck) {
                          setState(() {
                            _requiresKeyRecheck = true;
                          });
                        }
                      } else if (index == _keyIndex) {
                        if (_requiresKeyRecheck) {
                          setState(() {
                            _requiresKeyRecheck = false;
                          });
                        }
                      }
                    }
                  },
                  selectOnTap: true,
                  onTap: () {
                    if (_mode == _BalanceMode.finalCheck) {
                      o.measuredController.text = '';
                      o.measuredController.selection =
                          const TextSelection.collapsed(offset: 0);
                    }
                  },
                ),
              ),
            ],
          ),
          if (o.percentOfDesign != null || o.tolOfKey != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (o.percentOfDesign != null)
                    _buildResultRow(
                      '% of design',
                      '${o.percentOfDesign!.toStringAsFixed(1)} %',
                    ),
                  if (o.tolOfKey != null)
                    _buildResultRow(
                      'Tol. of key',
                      o.tolOfKey!.toStringAsFixed(3),
                    ),
                  if (o.statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        o.statusText,
                        style: TextStyle(
                          color: o.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final keyOutlet = _outlets[_keyIndex!];
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Outlet (lowest % of design)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2F7F32), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                keyOutlet.nameController.text,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              if (keyOutlet.percentOfDesign != null)
                Text(
                  '% of design: ${keyOutlet.percentOfDesign!.toStringAsFixed(1)} %',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Balancing panel with Save Reading buttons
  Widget _buildBalancingPanel() {
    if (_keyIndex == null || _currentBalancingIndex == null) {
      return const SizedBox.shrink();
    }

    final keyOutlet = _outlets[_keyIndex!];
    final targetOutlet = _outlets[_currentBalancingIndex!];

    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    const accent = Color(0xFF2F7F32);

    final estimatedTarget = _computeEstimatedTargetCFM(_currentBalancingIndex!);

    String _fmtMeasured(_OutletEntry o) {
      final t = o.measuredController.text.trim();
      return t.isEmpty ? '—' : '$t CFM';
    }

    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.8), width: 1.5),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111111)
            : Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Balancing Step',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust the current outlet until it is in tolerance of the key outlet, '
            'then re-measure the key outlet and save both readings.',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Adjusting outlet',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            targetOutlet.nameController.text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Current measured: ${_fmtMeasured(targetOutlet)}',
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
          ),
          if (estimatedTarget != null) ...[
            const SizedBox(height: 2),
            Text(
              'Estimated target: ${estimatedTarget.toStringAsFixed(0)} CFM',
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                _handleMeasuredSubmittedBalancing(_currentBalancingIndex!);
              },
              child: const Text(
                'SAVE ADJUSTING READING',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Key outlet (locked)',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            keyOutlet.nameController.text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Current measured: ${_fmtMeasured(keyOutlet)}',
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                _handleMeasuredSubmittedBalancing(_keyIndex!);
              },
              child: const Text(
                'SAVE KEY READING',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
    bool selectOnTap = false,
    VoidCallback? onTap,
    void Function(String)? onChanged,
    VoidCallback? onEditingComplete,
  }) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      onEditingComplete: () {
        if (onEditingComplete != null && onSubmitted == null) {
          onEditingComplete();
        }
      },
      onChanged: onChanged,
      onTap: () {
        if (selectOnTap) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        }
        if (onTap != null) onTap();
      },
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.24)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSummary(
    double totalDesign,
    double totalMeasured,
    double? totalPercentOfDesign,
  ) {
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Summary (read-only in Free version)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111111)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: textColor.withOpacity(0.24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total design: ${totalDesign.toStringAsFixed(0)} CFM   '
                'Total measured: ${totalMeasured.toStringAsFixed(0)} CFM',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              if (totalPercentOfDesign != null)
                Text(
                  '% of design: ${totalPercentOfDesign.toStringAsFixed(1)} %',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 8),
              Divider(color: textColor.withOpacity(0.24)),
              const SizedBox(height: 4),
              Text(
                'Outlet details:',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              for (final o in _outlets) ...[
                Text(
                  o.nameController.text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Design: ${o.designController.text} CFM   '
                  'Measured: ${o.measuredController.text} CFM',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                if (o.percentOfDesign != null)
                  Text(
                    '% of design: ${o.percentOfDesign!.toStringAsFixed(1)} %',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                if (o.tolOfKey != null)
                  Text(
                    'Tol. of key: ${o.tolOfKey!.toStringAsFixed(3)}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                if (o.statusText.isNotEmpty)
                  Text(
                    o.statusText,
                    style: TextStyle(
                      color: o.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                Divider(color: textColor.withOpacity(0.18), height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saving projects and generating reports will be available in EcoMeter Pro.',
          style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
        ),
      ],
    );
  }
}

// ===== OUTLET MODEL =====

class _OutletEntry {
  final TextEditingController nameController;
  final TextEditingController designController;
  final TextEditingController measuredController;

  final FocusNode designFocus;
  final FocusNode measuredFocus;

  final GlobalKey rowKey;

  double? percentOfDesign;
  double? tolOfKey;
  String statusText;
  Color statusColor;

  _OutletEntry({required String name})
    : nameController = TextEditingController(text: name),
      designController = TextEditingController(),
      measuredController = TextEditingController(),
      designFocus = FocusNode(),
      measuredFocus = FocusNode(),
      rowKey = GlobalKey(),
      percentOfDesign = null,
      tolOfKey = null,
      statusText = '',
      statusColor = Colors.grey;

  void dispose() {
    nameController.dispose();
    designController.dispose();
    measuredController.dispose();
    designFocus.dispose();
    measuredFocus.dispose();
  }
}
