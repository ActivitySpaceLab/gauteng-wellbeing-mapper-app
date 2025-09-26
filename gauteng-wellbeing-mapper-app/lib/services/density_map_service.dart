import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/survey_models.dart';

/// Service for generating density maps from GPS location data
/// Supports both standard kernel density estimation and Brownian bridge models
class DensityMapService {
  static const Distance _distance = Distance();
  
  /// Generate a density map raster from location data
  /// 
  /// [locations] - GPS points with accuracy information
  /// [bounds] - Map bounds for raster generation
  /// [resolution] - Pixels per degree (higher = more detailed)
  /// [useBrownianBridge] - Whether to use movement model vs simple density
  /// [bandwidth] - Kernel bandwidth in meters (auto-calculated if null)
  static Future<ui.Image?> generateDensityRaster({
    required List<LocationTrack> locations,
    required LatLngBounds bounds,
    int resolution = 256,
    bool useBrownianBridge = false,
    double? bandwidth,
  }) async {
    if (locations.isEmpty) return null;
    
    print('[DensityMapService] Generating ${useBrownianBridge ? "Brownian bridge" : "standard"} density map');
    print('[DensityMapService] Processing ${locations.length} locations at ${resolution}px resolution');
    
    // Calculate raster dimensions
    double latRange = bounds.north - bounds.south;
    double lngRange = bounds.east - bounds.west;
    int width = (lngRange * resolution).round();
    int height = (latRange * resolution).round();
    
    // Ensure reasonable raster size (prevent memory issues)
    if (width > 2048 || height > 2048) {
      double scaleFactor = math.min(2048.0 / width, 2048.0 / height);
      width = (width * scaleFactor).round();
      height = (height * scaleFactor).round();
      print('[DensityMapService] ⚠️ Scaled down raster to ${width}x${height} to prevent memory issues');
    }
    
    // Create density grid
    List<List<double>> densityGrid = List.generate(
      height, 
      (_) => List.filled(width, 0.0)
    );
    
    // Auto-calculate bandwidth if not provided
    bandwidth ??= _calculateOptimalBandwidth(locations);
    print('[DensityMapService] Using bandwidth: ${bandwidth.toStringAsFixed(1)}m');
    
    if (useBrownianBridge) {
      // Phase 2: Brownian bridge movement model
      _generateBrownianBridgeDensity(
        locations, bounds, densityGrid, width, height, bandwidth
      );
    } else {
      // Phase 1: Standard kernel density estimation
      _generateKernelDensity(
        locations, bounds, densityGrid, width, height, bandwidth
      );
    }
    
    // Convert density grid to image
    return _densityGridToImage(densityGrid, width, height);
  }
  
  /// Standard kernel density estimation with GPS accuracy weighting
  static void _generateKernelDensity(
    List<LocationTrack> locations,
    LatLngBounds bounds,
    List<List<double>> grid,
    int width,
    int height,
    double bandwidth,
  ) {
    double latRange = bounds.north - bounds.south;
    double lngRange = bounds.east - bounds.west;
    
    for (LocationTrack location in locations) {
      // Convert lat/lng to grid coordinates
      double x = ((location.longitude - bounds.west) / lngRange) * width;
      double y = ((bounds.north - location.latitude) / latRange) * height;
      
      // GPS accuracy affects kernel size and weight
      double accuracyMeters = location.accuracy ?? 10.0; // Default 10m if no accuracy data
      double accuracyWeight = 1.0 / math.max(accuracyMeters, 1.0); // Higher accuracy = higher weight
      
      // Convert accuracy from meters to pixels for kernel size
      double accuracyRadius = _metersToPixels(
        accuracyMeters, location.latitude, bounds, width, height
      );
      
      // Adaptive kernel size: combine base bandwidth with GPS accuracy
      double kernelRadius = math.max(bandwidth / 50.0, accuracyRadius);
      
      // Apply Gaussian kernel around this location
      _applyGaussianKernel(
        grid, x, y, kernelRadius, accuracyWeight, width, height
      );
    }
  }
  
  /// Brownian bridge movement model (estimates probability of movement between GPS fixes)
  static void _generateBrownianBridgeDensity(
    List<LocationTrack> locations,
    LatLngBounds bounds,
    List<List<double>> grid,
    int width,
    int height,
    double bandwidth,
  ) {
    print('[DensityMapService] 🧠 Applying Brownian bridge movement model...');
    
    // Sort locations by timestamp to ensure chronological processing
    List<LocationTrack> sortedLocations = List.from(locations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    for (int i = 0; i < sortedLocations.length - 1; i++) {
      LocationTrack loc1 = sortedLocations[i];
      LocationTrack loc2 = sortedLocations[i + 1];
      
      // Time difference between GPS fixes
      double timeDiff = loc2.timestamp.difference(loc1.timestamp).inSeconds.toDouble();
      
      // Skip if time gap is too large (>1 hour = likely separate activity)
      if (timeDiff > 3600) continue;
      
      // Distance between consecutive points
      double distance = _distance.as(LengthUnit.Meter, 
        LatLng(loc1.latitude, loc1.longitude),
        LatLng(loc2.latitude, loc2.longitude)
      );
      
      // Brownian bridge parameters
      double diffusionCoeff = _calculateDiffusionCoefficient(distance, timeDiff);
      double acc1 = loc1.accuracy ?? 10.0;
      double acc2 = loc2.accuracy ?? 10.0;
      double locationUncertainty = math.sqrt(acc1 * acc1 + acc2 * acc2);
      
      // Generate interpolated probability surface
      _interpolateBrownianBridge(
        loc1, loc2, bounds, grid, width, height,
        timeDiff, diffusionCoeff, locationUncertainty
      );
    }
  }
  
  /// Calculate diffusion coefficient for Brownian bridge
  /// Higher values = more exploration/wandering between GPS fixes
  static double _calculateDiffusionCoefficient(double distance, double timeDiff) {
    // Base diffusion on observed movement speed
    double speed = distance / timeDiff; // m/s
    
    // Human movement diffusion coefficient (empirically derived)
    // Walking: ~1 m²/s, Driving: ~10 m²/s
    if (speed < 2.0) return 1.0; // Walking/stationary
    if (speed < 10.0) return 5.0; // Cycling/slow driving  
    return 10.0; // Fast driving
  }
  
  /// Interpolate movement probability between two GPS fixes using Brownian bridge
  static void _interpolateBrownianBridge(
    LocationTrack loc1,
    LocationTrack loc2,
    LatLngBounds bounds,
    List<List<double>> grid,
    int width,
    int height,
    double timeDiff,
    double diffusionCoeff,
    double locationUncertainty,
  ) {
    // Convert start/end points to grid coordinates
    double latRange = bounds.north - bounds.south;
    double lngRange = bounds.east - bounds.west;
    
    double x1 = ((loc1.longitude - bounds.west) / lngRange) * width;
    double y1 = ((bounds.north - loc1.latitude) / latRange) * height;
    double x2 = ((loc2.longitude - bounds.west) / lngRange) * width;
    double y2 = ((bounds.north - loc2.latitude) / latRange) * height;
    
    // Sample points along potential path
    int numSamples = math.max(10, (timeDiff / 60).round()); // More samples for longer time gaps
    
    for (int i = 0; i <= numSamples; i++) {
      double t = i / numSamples; // Time fraction [0, 1]
      
      // Linear interpolation between endpoints (expected path)
      double expectedX = x1 + t * (x2 - x1);
      double expectedY = y1 + t * (y2 - y1);
      
      // Brownian bridge variance increases towards middle of time interval
      double variance = diffusionCoeff * t * (1 - t) * timeDiff;
      variance += locationUncertainty; // Add GPS uncertainty
      
      // Convert variance to pixel radius
      double stdDev = math.sqrt(variance);
      double kernelRadius = _metersToPixels(
        stdDev, 
        bounds.south + ((height - expectedY) / height) * latRange, // Back to lat
        bounds, 
        width, 
        height
      );
      
      // Apply probability kernel (weight decreases with time interpolation)
      double weight = 1.0 / numSamples;
      _applyGaussianKernel(
        grid, expectedX, expectedY, kernelRadius, weight, width, height
      );
    }
  }
  
  /// Apply Gaussian kernel at given location
  static void _applyGaussianKernel(
    List<List<double>> grid,
    double centerX,
    double centerY,
    double radius,
    double weight,
    int width,
    int height,
  ) {
    int minX = math.max(0, (centerX - radius * 3).floor());
    int maxX = math.min(width - 1, (centerX + radius * 3).ceil());
    int minY = math.max(0, (centerY - radius * 3).floor());
    int maxY = math.min(height - 1, (centerY + radius * 3).ceil());
    
    double radiusSquared = radius * radius;
    double twoRadiusSquared = 2 * radiusSquared;
    
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        double dx = x - centerX;
        double dy = y - centerY;
        double distanceSquared = dx * dx + dy * dy;
        
        if (distanceSquared <= radiusSquared * 9) { // 3-sigma cutoff
          double gaussianValue = math.exp(-distanceSquared / twoRadiusSquared);
          grid[y][x] += gaussianValue * weight;
        }
      }
    }
  }
  
  /// Calculate optimal bandwidth based on data characteristics
  static double _calculateOptimalBandwidth(List<LocationTrack> locations) {
    if (locations.length < 2) return 100.0;
    
    // Silverman's rule of thumb adapted for spatial data
    List<double> distances = [];
    
    for (int i = 1; i < locations.length; i++) {
      double dist = _distance.as(LengthUnit.Meter,
        LatLng(locations[i-1].latitude, locations[i-1].longitude),
        LatLng(locations[i].latitude, locations[i].longitude)
      );
      if (dist > 0 && dist < 1000) distances.add(dist); // Filter outliers
    }
    
    if (distances.isEmpty) return 100.0;
    
    distances.sort();
    double median = distances[distances.length ~/ 2];
    double iqr = distances[(distances.length * 0.75).round()] - 
                 distances[(distances.length * 0.25).round()];
    
    // Adaptive bandwidth: smaller for dense data, larger for sparse
    return math.max(20.0, math.min(200.0, median + iqr * 0.5));
  }
  
  /// Convert meters to pixel distance at given latitude
  static double _metersToPixels(
    double meters, 
    double latitude, 
    LatLngBounds bounds, 
    int width, 
    int height
  ) {
    // Degrees per meter varies by latitude
    double metersPerDegree = 111320.0 * math.cos(latitude * math.pi / 180.0);
    double degreesPerMeter = 1.0 / metersPerDegree;
    
    double lngRange = bounds.east - bounds.west;
    double pixelsPerDegree = width / lngRange;
    
    return meters * degreesPerMeter * pixelsPerDegree;
  }
  
  /// Convert density grid to RGBA image
  static Future<ui.Image> _densityGridToImage(
    List<List<double>> grid, 
    int width, 
    int height
  ) async {
    // Find max density for normalization
    double maxDensity = 0.0;
    for (var row in grid) {
      for (double value in row) {
        if (value > maxDensity) maxDensity = value;
      }
    }
    
    if (maxDensity == 0.0) maxDensity = 1.0; // Prevent division by zero
    
    // Create RGBA pixel data
    Uint8List pixels = Uint8List(width * height * 4);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = (y * width + x) * 4;
        double normalizedDensity = grid[y][x] / maxDensity;
        
        // Heat map color scheme: transparent -> blue -> green -> yellow -> red
        Color color = _densityToHeatmapColor(normalizedDensity);
        
        pixels[index] = (color.r * 255).round();     // R
        pixels[index + 1] = (color.g * 255).round(); // G
        pixels[index + 2] = (color.b * 255).round();  // B
        pixels[index + 3] = (color.a * 255).round(); // A
      }
    }
    
    // Convert to Flutter Image using decodeImageFromPixels
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    
    return completer.future;
  }
  
  /// Convert normalized density to heat map color
  static Color _densityToHeatmapColor(double density) {
    if (density <= 0.0) return Colors.transparent;
    
    // Clamp density and apply power curve for better visual contrast
    density = math.pow(math.min(1.0, density), 0.7).toDouble();
    
    if (density < 0.25) {
      // Transparent to blue
      double t = density / 0.25;
      return Color.lerp(Colors.transparent, Colors.blue[600]!, t)!;
    } else if (density < 0.5) {
      // Blue to green
      double t = (density - 0.25) / 0.25;
      return Color.lerp(Colors.blue[600]!, Colors.green[600]!, t)!;
    } else if (density < 0.75) {
      // Green to yellow
      double t = (density - 0.5) / 0.25;
      return Color.lerp(Colors.green[600]!, Colors.yellow[600]!, t)!;
    } else {
      // Yellow to red
      double t = (density - 0.75) / 0.25;
      return Color.lerp(Colors.yellow[600]!, Colors.red[600]!, t)!;
    }
  }

}

/// Bounds helper class
class LatLngBounds {
  final double north;
  final double south; 
  final double east;
  final double west;
  
  const LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
  
  /// Calculate bounds from a list of locations with padding
  static LatLngBounds fromLocations(List<LocationTrack> locations, {double paddingDegrees = 0.001}) {
    if (locations.isEmpty) {
      return const LatLngBounds(north: 0, south: 0, east: 0, west: 0);
    }
    
    double north = locations.first.latitude;
    double south = locations.first.latitude;
    double east = locations.first.longitude;
    double west = locations.first.longitude;
    
    for (LocationTrack location in locations) {
      if (location.latitude > north) north = location.latitude;
      if (location.latitude < south) south = location.latitude;
      if (location.longitude > east) east = location.longitude;
      if (location.longitude < west) west = location.longitude;
    }
    
    return LatLngBounds(
      north: north + paddingDegrees,
      south: south - paddingDegrees, 
      east: east + paddingDegrees,
      west: west - paddingDegrees,
    );
  }
}