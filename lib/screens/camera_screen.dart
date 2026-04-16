import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';

import '../main.dart';
import '../utils/filter_utils.dart';
import '../models/filter_item.dart';
import '../widgets/visual_filter_selector.dart';
import 'gallery_screen.dart';
import 'preview_screen.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  bool _isFilterMenuOpen = false;
  bool _isRatioMenuOpen = false;

  final List<FilterItem> _filterItems = [
    FilterItem(name: 'Normal'),
    FilterItem(name: 'Siyah Beyaz'),
    FilterItem(name: 'Dram'),
    FilterItem(name: 'Cinematic', lutPath: 'assets/filters/scifi.png'),
    FilterItem(name: 'Vintage'),
  ];
  late FilterItem _selectedFilterItem;

  final List<String> _ratios = ['1:1', '3:4', '4:5', '9:16'];
  String _aspectRatio = '3:4';

  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  int _timerSeconds = 0;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _iconTurns = 0.0;
  
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedFilterItem = _filterItems[0];
    _initCamera(_selectedCameraIndex);
    _initSensors();
  }

  void _initSensors() {
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (!mounted) return;
      if (event.y > 6.0) {
        if (_iconTurns != 0.0) setState(() { _iconTurns = 0.0; });
      } else if (event.x > 6.0) {
        if (_iconTurns != 0.25) setState(() { _iconTurns = 0.25; });
      } else if (event.x < -6.0) {
        if (_iconTurns != -0.25) setState(() { _iconTurns = -0.25; });
      }
    });
  }

  Future<void> _initCamera(int cameraIndex) async {
    if (_controller != null) await _controller!.dispose();
    _controller = CameraController(cameras[cameraIndex], ResolutionPreset.high, enableAudio: false);
    _initializeControllerFuture = _controller!.initialize().then((_) async {
      if (!mounted) return;
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      await _controller!.setFlashMode(_flashMode);
      // Sensör kilitleme (Artık hata vermez)
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      setState(() {});
    });
  }

  Widget _buildTopControlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopControlButton(
          icon: _flashMode == FlashMode.off ? Icons.flash_off : (_flashMode == FlashMode.always ? Icons.flash_on : Icons.flash_auto),
          label: 'Flaş',
          onTap: _toggleFlash,
        ),
        _buildTopControlButton(
          icon: Icons.aspect_ratio,
          label: _aspectRatio,
          onTap: () => setState(() { _isRatioMenuOpen = true; _isFilterMenuOpen = false; }),
        ),
        _buildTopControlButton(
          icon: Icons.timer,
          label: _timerSeconds == 0 ? 'Kapalı' : '${_timerSeconds}s',
          onTap: _toggleTimer,
        ),
        _buildTopControlButton(
          icon: Icons.cameraswitch,
          label: 'Çevir',
          onTap: _toggleCamera,
        ),
        _buildTopControlButton(
          icon: Icons.auto_awesome_mosaic,
          label: 'Toplu',
          onTap: _pickAndEditFromGallery,
        ),
      ],
    );
  }

  Widget _buildBottomPanelContent() {
    if (_isFilterMenuOpen) {
      return VisualFilterSelector(
        filterItems: _filterItems,
        currentFilter: _selectedFilterItem,
        onFilterChanged: (val) => setState(() => _selectedFilterItem = val),
        onCloseMenu: () => setState(() => _isFilterMenuOpen = false),
      );
    }

    return Column(
      children: [
        const Spacer(),
        
        SizedBox(
          height: 60, 
          child: Center(
            child: _isRatioMenuOpen
                ? _buildHorizontalMenu(_ratios, _aspectRatio, (val) => _aspectRatio = val, () => _isRatioMenuOpen = false)
                : _buildTopControlsRow(),
          ),
        ),
        // --------------------------
            
        const Spacer(),
        
        _buildPhotoButtonsRow(),
        
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildPhotoButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAnimatedIcon(Icons.photo_library, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen()))),
        _buildCaptureButton(),
        _buildAnimatedIcon(Icons.auto_awesome, () => setState(() { _isFilterMenuOpen = true; _isRatioMenuOpen = false; })),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double ratioValue = 3 / 4;
    if (_aspectRatio == '1:1') ratioValue = 1.0;
    else if (_aspectRatio == '9:16') ratioValue = 9 / 16;
    else if (_aspectRatio == '4:5') ratioValue = 4 / 5;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                    child: Center(
                      child: _controller == null || _initializeControllerFuture == null
                          ? const CircularProgressIndicator(color: Colors.white)
                          : FutureBuilder<void>(
                              future: _initializeControllerFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: AspectRatio(
                                      aspectRatio: ratioValue,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: 100,
                                          height: 100 * _controller!.value.aspectRatio,
                                          child: GestureDetector(
                                            onScaleStart: (d) => _baseZoom = _currentZoom,
                                            onScaleUpdate: (d) {
                                              setState(() {
                                                _currentZoom = (_baseZoom * d.scale).clamp(_minZoom, _maxZoom);
                                                _controller!.setZoomLevel(_currentZoom);
                                              });
                                            },
                                            child: CameraPreview(_controller!),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const CircularProgressIndicator(color: Colors.white);
                              },
                            ),
                    ),
                  ),
                ),

                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.black,
                  child: _buildBottomPanelContent(),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleCamera() {
    if (cameras.length < 2) return;
    setState(() { _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0; _initCamera(_selectedCameraIndex); });
  }

  void _toggleFlash() {
    setState(() {
      if (_flashMode == FlashMode.off) _flashMode = FlashMode.always;
      else if (_flashMode == FlashMode.always) _flashMode = FlashMode.auto;
      else _flashMode = FlashMode.off;
      _controller?.setFlashMode(_flashMode);
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_timerSeconds == 0) _timerSeconds = 3;
      else if (_timerSeconds == 3) _timerSeconds = 10;
      else _timerSeconds = 0;
    });
  }

  Widget _buildCaptureButton() {
    return AnimatedRotation(
      turns: _iconTurns,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton(
        heroTag: "captureBtn",
        onPressed: _takePhoto,
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, VoidCallback onTap) {
    return AnimatedRotation(
      turns: _iconTurns,
      duration: const Duration(milliseconds: 300),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 32), onPressed: onTap),
    );
  }

  Widget _buildTopControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: AnimatedRotation(
          turns: _iconTurns,
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalMenu(List<String> items, String selected, Function(String) onSelect, VoidCallback onClose) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 5.0),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30), 
            onPressed: () {
              setState(() {
                onClose();
              });
            }
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final isSel = selected == items[index];
              return GestureDetector(
                onTap: () => setState(() => onSelect(items[index])),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.white : Colors.transparent, 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: Colors.white)
                  ),
                  child: Center(
                    child: Text(
                      items[index], 
                      style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)
                    )
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _takePhoto() async {}
  Future<void> _pickAndEditFromGallery() async {}
  Future<void> _processBatchImages(List<XFile> images, FilterItem filter) async {}

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}