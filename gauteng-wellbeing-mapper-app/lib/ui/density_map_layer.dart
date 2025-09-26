import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/density_map_service.dart' as density_service;
import '../models/survey_models.dart';
import '../db/survey_database.dart';

/// Widget that displays a density map layer on top of the base map
class DensityMapLayer extends StatefulWidget {
  final bool enabled;
  final bool useBrownianBridge;

  const DensityMapLayer({
    Key? key,
    required this.enabled,
    this.useBrownianBridge = false,
  }) : super(key: key);

  @override
  State<DensityMapLayer> createState() => _DensityMapLayerState();
}

class _DensityMapLayerState extends State<DensityMapLayer> {
  ui.Image? _densityImage;
  density_service.LatLngBounds? _imageBounds;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _generateDensityMap();
    }
  }

  @override
  void didUpdateWidget(DensityMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled || 
        widget.useBrownianBridge != oldWidget.useBrownianBridge) {
      if (widget.enabled) {
        _generateDensityMap();
      } else {
        setState(() {
          _densityImage = null;
          _imageBounds = null;
        });
      }
    }
  }

  Future<void> _generateDensityMap() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      print('[DensityMapLayer] 🔥 Generating ${widget.useBrownianBridge ? "Brownian bridge" : "standard"} density map...');
      
      // Load location data from database
      final db = SurveyDatabase();
      final List<LocationTrack> locations = await db.getAllLocationTracks();
      
      if (locations.isEmpty) {
        print('[DensityMapLayer] ⚠️ No location data available for density map');
        setState(() {
          _isGenerating = false;
        });
        return;
      }
      
      // Calculate bounds from location data
      density_service.LatLngBounds bounds = density_service.LatLngBounds.fromLocations(locations, paddingDegrees: 0.005);
      
      print('[DensityMapLayer] 📊 Processing ${locations.length} locations within bounds: ${bounds.north}, ${bounds.south}, ${bounds.east}, ${bounds.west}');
      
      // Generate density raster
      ui.Image? densityImage = await density_service.DensityMapService.generateDensityRaster(
        locations: locations,
        bounds: bounds,
        resolution: 512, // Higher resolution for better quality
        useBrownianBridge: widget.useBrownianBridge,
        bandwidth: null, // Auto-calculate
      );
      
      if (densityImage != null && mounted) {
        setState(() {
          _densityImage = densityImage;
          _imageBounds = bounds;
          _isGenerating = false;
        });
        print('[DensityMapLayer] ✅ Density map generated successfully: ${densityImage.width}x${densityImage.height}');
      } else if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        print('[DensityMapLayer] ❌ Failed to generate density map');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
      print('[DensityMapLayer] ❌ Error generating density map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _densityImage == null || _imageBounds == null) {
      return const SizedBox.shrink();
    }

    return OverlayImageLayer(
      overlayImages: [
        OverlayImage(
          bounds: LatLngBounds(
            LatLng(_imageBounds!.south, _imageBounds!.west),
            LatLng(_imageBounds!.north, _imageBounds!.east),
          ),
          imageProvider: _DensityImageProvider(_densityImage!),
          opacity: 0.7, // Semi-transparent overlay
        ),
      ],
    );
  }

  /// Method to refresh the density map (call when location data changes)
  void refresh() {
    _generateDensityMap();
  }
}

/// Custom image provider for density map images
class _DensityImageProvider extends ImageProvider<_DensityImageProvider> {
  final ui.Image image;

  _DensityImageProvider(this.image);

  @override
  Future<_DensityImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadImage(_DensityImageProvider key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync());
  }

  Future<ImageInfo> _loadAsync() async {
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _DensityImageProvider && other.image == image;
  }

  @override
  int get hashCode => image.hashCode;
}