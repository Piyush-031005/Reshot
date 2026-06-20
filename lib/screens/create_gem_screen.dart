import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/hidden_gem_model.dart';
import '../providers/repository_provider.dart';
import '../theme/cyber_theme.dart';

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
      builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.cyberDark,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: CyberTheme.hotPink),
            const SizedBox(width: 8),
            Text(
              'CONFIRM_GEM_INTEL.SYS',
              style: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReviewRow('SPOT NAME:', _nameController.text),
              const SizedBox(height: 10),
              _buildReviewRow('DESCRIPTION:', _descController.text),
              const SizedBox(height: 10),
              _buildReviewRow('LATITUDE:', lat.toStringAsFixed(6)),
              const SizedBox(height: 10),
              _buildReviewRow('LONGITUDE:', lng.toStringAsFixed(6)),
              const SizedBox(height: 10),
              // Fix 3: show real altitude in confirmation.
              _buildReviewRow('ALTITUDE:', _formatAltitude()),
              const SizedBox(height: 10),
              _buildReviewRow(
                'TAGS:',
                _selectedTags.isEmpty ? 'None' : _selectedTags.join(', '),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24),
              Text(
                'Verify the coordinates and spot details. Once confirmed, this gem is saved to your explorer index.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          // Fix 4: disable button while saving.
          StatefulBuilder(
            builder: (context, setDialogState) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.limeGreen,
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        setDialogState(() {});
                        await _saveGem(lat, lng, ctx);
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'CONFIRM & SAVE',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.pressStart2p(fontSize: 8, color: CyberTheme.hotPink),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ADD_NEW_GEM.EXE',
          style: GoogleFonts.pressStart2p(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: CyberTheme.limeGreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GPS Status Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: CyberTheme.cartoonDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS RADAR STATUS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9,
                        color: CyberTheme.hotPink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isGpsLoading) ...[
                      const Center(
                        child: CircularProgressIndicator(color: CyberTheme.limeGreen),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(_gpsStatusMessage, style: textTheme.bodyMedium),
                      )
                    ] else if (_gpsError && !_useManualCoordinates) ...[
                      Text(
                        _gpsStatusMessage,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CyberTheme.hotPink,
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            onPressed: _fetchGpsCoordinates,
                            child: const Text('RETRY GPS'),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: CyberTheme.limeGreen, width: 2),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                            onPressed: () {
                              setState(() {
                                _useManualCoordinates = true;
                              });
                            },
                            child: const Text('SELECT MANUALLY',
                                style: TextStyle(color: CyberTheme.limeGreen)),
                          ),
                        ],
                      )
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _useManualCoordinates
                                ? 'MANUAL COORDINATES OVERRIDE'
                                : 'GPS LOCKED SUCCESSFULLY',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 8,
                              color: CyberTheme.limeGreen,
                            ),
                          ),
                          // Fix 5: retry always available; success will reset manual mode.
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                            tooltip: 'Retry GPS',
                            onPressed: _fetchGpsCoordinates,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      if (_useManualCoordinates) ...[
                        Row(
                          children: [
                            const Text('LAT: '),
                            Expanded(
                              child: Slider(
                                value: _manualLat,
                                min: 28.0,
                                max: 31.0,
                                activeColor: CyberTheme.hotPink,
                                onChanged: (val) {
                                  setState(() {
                                    _manualLat = val;
                                  });
                                },
                              ),
                            ),
                            Text(_manualLat.toStringAsFixed(4)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('LNG: '),
                            Expanded(
                              child: Slider(
                                value: _manualLng,
                                min: 78.0,
                                max: 81.0,
                                activeColor: CyberTheme.hotPink,
                                onChanged: (val) {
                                  setState(() {
                                    _manualLng = val;
                                  });
                                },
                              ),
                            ),
                            Text(_manualLng.toStringAsFixed(4)),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'LAT: ${_latitude?.toStringAsFixed(6)}',
                          style:
                              GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LNG: ${_longitude?.toStringAsFixed(6)}',
                          style:
                              GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        // Fix 3: show real altitude from GPS.
                        Text(
                          'ALT: ${_altitude != null ? "${_altitude!.toStringAsFixed(0)}m" : "Acquiring..."}',
                          style:
                              GoogleFonts.pressStart2p(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Spot Name
              Text(
                'SPOT NAME',
                style: textTheme.titleLarge?.copyWith(fontSize: 16, color: CyberTheme.limeGreen),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Birthi View Bridge',
                  hintStyle: TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: CyberTheme.cyberDark,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a name for the spot.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'DESCRIPTION',
                style: textTheme.titleLarge?.copyWith(fontSize: 16, color: CyberTheme.limeGreen),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Describe how to find the rock and compose the framing...',
                  hintStyle: TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: CyberTheme.cyberDark,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tags
              Text(
                'SELECT SPOT TAGS',
                style: textTheme.titleLarge?.copyWith(fontSize: 16, color: CyberTheme.limeGreen),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: CyberTheme.limeGreen,
                    backgroundColor: CyberTheme.cyberDark,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isSelected ? Colors.black : Colors.white24,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    onSelected: (_) => _toggleTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Submit
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.hotPink,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _handleSubmit,
                child: Text(
                  'SUBMIT DETAILS',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
