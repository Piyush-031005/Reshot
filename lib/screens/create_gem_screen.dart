import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/hidden_gem_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';
import '../widgets/cartoon_widgets.dart';

class CreateGemScreen extends StatefulWidget {
  const CreateGemScreen({super.key});

  @override
  State<CreateGemScreen> createState() => _CreateGemScreenState();
}

class _CreateGemScreenState extends State<CreateGemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // GPS State
  double? _latitude;
  double? _longitude;
  // Fix 3: store actual altitude from GPS, null if unavailable.
  double? _altitude;
  bool _isGpsLoading = false;
  String _gpsStatusMessage = 'Initializing GPS...';
  bool _gpsError = false;

  // Selected Tags
  final List<String> _availableTags = [
    'Waterfall',
    'Viewpoint',
    'Temple',
    'Cafe',
    'Sunrise Spot',
    'Hidden Gem'
  ];
  final List<String> _selectedTags = [];

  // Manual Coordinates override values
  double _manualLat = 29.5985;
  double _manualLng = 80.2033;
  bool _useManualCoordinates = false;

  // Fix 4: prevent duplicate saves
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchGpsCoordinates();
  }

  Future<void> _fetchGpsCoordinates() async {
    setState(() {
      _isGpsLoading = true;
      _gpsError = false;
      _gpsStatusMessage = 'Auto-capturing location coordinates...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isGpsLoading = false;
          _gpsError = true;
          _gpsStatusMessage = 'Location services are disabled on your device.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGpsLoading = false;
            _gpsError = true;
            _gpsStatusMessage = 'Location permissions denied. Please enable them to auto-capture.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isGpsLoading = false;
          _gpsError = true;
          _gpsStatusMessage = 'Location permissions permanently denied. Use manual entries.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        // Fix 3: capture real altitude from GPS fix.
        _altitude = position.altitude;
        // Fix 5: successful GPS retrieval disables manual mode.
        _useManualCoordinates = false;
        _gpsError = false;
        _isGpsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGpsLoading = false;
        _gpsError = true;
        _gpsStatusMessage = 'GPS signal lost or timed out. Please retry or select manually.';
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final lat = _useManualCoordinates ? _manualLat : _latitude;
    final lng = _useManualCoordinates ? _manualLng : _longitude;

    if (lat == null || lng == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: CyberTheme.cyberBlack,
          title: const Text('GPS Required'),
          content: const Text(
              'No valid coordinates found. Please retry GPS lock or enable manual override coordinates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: CyberTheme.limeGreen)),
            )
          ],
        ),
      );
      return;
    }

    _showConfirmationDialog(lat, lng);
  }

  // Fix 3: format altitude for display and storage.
  String _formatAltitude() {
    if (_useManualCoordinates || _altitude == null) return 'Unknown';
    return '${_altitude!.toStringAsFixed(0)}m';
  }

  void _showConfirmationDialog(double lat, double lng) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: CyberTheme.cardWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: CyberTheme.outlineBlack, width: 3),
            boxShadow: const [
              BoxShadow(
                color: CyberTheme.outlineBlack,
                offset: Offset(6, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CyberTheme.limeGreen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  border: const Border(
                    bottom: BorderSide(color: CyberTheme.outlineBlack, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(
                      'Confirm Gem',
                      style: GoogleFonts.boogaloo(
                        fontSize: 20,
                        color: CyberTheme.inkBlack,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReviewRow('📍 Spot Name', _nameController.text),
                      const SizedBox(height: 10),
                      _buildReviewRow('📝 Description', _descController.text),
                      const SizedBox(height: 10),
                      _buildReviewRow('🌐 Latitude', lat.toStringAsFixed(6)),
                      const SizedBox(height: 10),
                      _buildReviewRow('🌐 Longitude', lng.toStringAsFixed(6)),
                      const SizedBox(height: 10),
                      _buildReviewRow('⬆️ Altitude', _formatAltitude()),
                      const SizedBox(height: 10),
                      _buildReviewRow(
                        '🏷️ Tags',
                        _selectedTags.isEmpty ? 'None' : _selectedTags.join(', '),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Once confirmed, this gem is saved to your explorer index.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.boogaloo(
                                        fontSize: 15, color: const Color(0xFF888888)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatefulBuilder(
                              builder: (context, setDialogState) {
                                return GestureDetector(
                                  onTap: _isSaving
                                      ? null
                                      : () async {
                                          setDialogState(() {});
                                          await _saveGem(lat, lng, ctx);
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: CyberTheme.limeGreen,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: CyberTheme.outlineBlack, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: CyberTheme.outlineBlack,
                                          offset: Offset(3, 3),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: CyberTheme.inkBlack,
                                              ),
                                            )
                                          : Text(
                                              '✓ Save Gem',
                                              style: GoogleFonts.boogaloo(
                                                fontSize: 15,
                                                color: CyberTheme.inkBlack,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

  Widget _buildReviewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.boogaloo(
            fontSize: 15,
            color: CyberTheme.inkBlack,
          ),
        ),
      ],
    );
  }

  Future<void> _saveGem(double lat, double lng, BuildContext dialogContext) async {
    // Fix 4: guard against duplicate taps.
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newGem = HiddenGemModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      latitude: lat,
      longitude: lng,
      // Fix 3: use real altitude if available, otherwise 'Unknown'.
      altitude: _formatAltitude(),
      tags: _selectedTags.toList(),
      photoPath: 'placeholder_custom',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final provider = context.read<AppRepositoryProvider>();
      await provider.saveHiddenGem(newGem);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving gem: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.cream,
      appBar: AppBar(
        backgroundColor: CyberTheme.cream,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CyberTheme.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CyberTheme.outlineBlack, width: 2),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: CyberTheme.inkBlack, size: 20),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💎', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'ADD A GEM',
              style: GoogleFonts.boogaloo(
                fontSize: 20,
                color: CyberTheme.inkBlack,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── GPS Status Card ─────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: CyberTheme.cartoonCard,
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isGpsLoading
                            ? CyberTheme.electricBlue
                            : _gpsError && !_useManualCoordinates
                                ? CyberTheme.hotPink
                                : CyberTheme.limeGreen,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        border: const Border(
                          bottom: BorderSide(color: CyberTheme.outlineBlack, width: 3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isGpsLoading
                                ? '📡'
                                : _gpsError && !_useManualCoordinates
                                    ? '❌'
                                    : '✅',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isGpsLoading
                                ? 'Finding Location...'
                                : _gpsError && !_useManualCoordinates
                                    ? 'GPS Error'
                                    : _useManualCoordinates
                                        ? 'Manual Coords'
                                        : 'GPS Locked!',
                            style: GoogleFonts.boogaloo(
                              fontSize: 15,
                              color: CyberTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_isGpsLoading) ...[
                            const LinearProgressIndicator(
                              color: CyberTheme.electricBlue,
                              backgroundColor: Color(0xFFEEEEEE),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _gpsStatusMessage,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: const Color(0xFF666666),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else if (_gpsError && !_useManualCoordinates) ...[
                            Text(
                              _gpsStatusMessage,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: CyberTheme.hotPink,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: CartoonButton(
                                    label: 'Retry GPS',
                                    emoji: '🔄',
                                    color: CyberTheme.electricBlue,
                                    textColor: Colors.white,
                                    height: 46,
                                    fontSize: 13,
                                    onTap: _fetchGpsCoordinates,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CartoonButton(
                                    label: 'Manual',
                                    emoji: '🗺️',
                                    color: CyberTheme.limeGreen,
                                    textColor: CyberTheme.inkBlack,
                                    height: 46,
                                    fontSize: 13,
                                    onTap: () => setState(() => _useManualCoordinates = true),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _useManualCoordinates
                                      ? 'Manual Override Active'
                                      : 'Auto-captured!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF444444),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _fetchGpsCoordinates,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: CyberTheme.electricBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: CyberTheme.electricBlue, width: 1.5),
                                    ),
                                    child: Text(
                                      '🔄 Retry',
                                      style: GoogleFonts.nunito(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: CyberTheme.electricBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_useManualCoordinates) ...[
                              _buildSliderRow('LAT', _manualLat, 28.0, 31.0,
                                  (val) => setState(() => _manualLat = val)),
                              const SizedBox(height: 8),
                              _buildSliderRow('LNG', _manualLng, 78.0, 81.0,
                                  (val) => setState(() => _manualLng = val)),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _CoordChip(
                                      label: 'LAT',
                                      value: _latitude?.toStringAsFixed(5) ?? '-',
                                      color: CyberTheme.hotPink,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _CoordChip(
                                      label: 'LNG',
                                      value: _longitude?.toStringAsFixed(5) ?? '-',
                                      color: CyberTheme.electricBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _CoordChip(
                                      label: 'ALT',
                                      value: _altitude != null
                                          ? '${_altitude!.toStringAsFixed(0)}m'
                                          : '...',
                                      color: CyberTheme.limeGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Spot Name ───────────────────────────────────────────────
              SectionHeader(title: 'SPOT NAME', emoji: '📍'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: CyberTheme.inkBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Birthi View Bridge',
                  filled: true,
                  fillColor: CyberTheme.cardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: CyberTheme.outlineBlack, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: CyberTheme.limeGreen, width: 3),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('🏷️', style: TextStyle(fontSize: 18)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a spot name.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Description ─────────────────────────────────────────────
              SectionHeader(title: 'DESCRIPTION', emoji: '📝'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: CyberTheme.inkBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe how to find the spot and compose the framing...',
                  filled: true,
                  fillColor: CyberTheme.cardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: CyberTheme.outlineBlack, width: 2.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: CyberTheme.electricBlue, width: 3),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a description.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Tags ────────────────────────────────────────────────────
              SectionHeader(title: 'SPOT TAGS', emoji: '🏷️'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  final tagColor = CyberTheme.gemTypeColor(tag);
                  final tagEmoji = CyberTheme.gemTypeEmoji(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? tagColor : CyberTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? CyberTheme.outlineBlack : const Color(0xFFCCCCCC),
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: CyberTheme.outlineBlack,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$tagEmoji ${tag.toUpperCase()}',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? CyberTheme.inkBlack : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // ── Submit ──────────────────────────────────────────────────
              CartoonButton(
                label: 'SUBMIT GEM',
                emoji: '💎',
                color: CyberTheme.hotPink,
                textColor: Colors.white,
                height: 60,
                onTap: _handleSubmit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
      String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: GoogleFonts.boogaloo(fontSize: 13, color: CyberTheme.inkBlack),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CyberTheme.hotPink,
              inactiveTrackColor: const Color(0xFFDDDDDD),
              thumbColor: CyberTheme.hotPink,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        Text(
          value.toStringAsFixed(3),
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CyberTheme.inkBlack,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

// ─── Coord Chip ───────────────────────────────────────────────────────────────
class _CoordChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CoordChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CyberTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
