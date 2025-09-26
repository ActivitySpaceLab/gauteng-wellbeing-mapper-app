import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/survey_models.dart';

/// Service for generating probabilistic density maps from GPS location data
/// Based on GPS error circles with transparency inversely related to accuracy
class ProbabilisticDensityService {
  
  /// Generate a probabilistic density raster from location data
  /// Each location creates a circle with radius = GPS error
  /// Transparency inversely proportional to error (large error = more transparent)
  /// Overlapping circles accumulate opacity to show density
  static Future<ui.Image?> generateProbabilisticDensityRaster({
    required List<LocationTrack> locations,
    required LatLngBounds bounds,
    int resolution = 512,
  }) async {
    if (locations.isEmpty) return null;
    
    print('[ProbabilisticDensity] Generating probabilistic density map from ${locations.length} locations');
    
    // Calculate raster dimensions
    double latRange = bounds.north - bounds.south;
    double lngRange = bounds.east - bounds.west;
    int width = (lngRange * resolution).round();
    int height = (latRange * resolution).round();
    
    // Ensure reasonable raster size (prevent memory issues)
    if (width > 1024 || height > 1024) {
      double scaleFactor = math.min(1024.0 / width, 1024.0 / height);
      width = (width * scaleFactor).round();
      height = (height * scaleFactor).round();
      print('[ProbabilisticDensity] ⚠️ Scaled down raster to ${width}x${height} to prevent memory issues');
    }
    
    // Create accumulation grid for opacity values
    List<List<double>> opacityGrid = List.generate(
      height, 
      (_) => List.filled(width, 0.0)
    );
    
    print('[ProbabilisticDensity] Processing locations with GPS error circles...');
    
    // Process each location as an error circle
    for (LocationTrack location in locations) {
      double accuracy = location.accuracy ?? 10.0; // Default 10m if no accuracy data
      
      // Skip locations with very poor accuracy (>200m) as they're probably not useful
      if (accuracy > 200.0) continue;
      
      // Convert lat/lng to pixel coordinates
      double centerX = ((location.longitude - bounds.west) / lngRange) * width;
      double centerY = ((bounds.north - location.latitude) / latRange) * height;
      
      // Convert accuracy from meters to pixels
      double radiusPixels = _metersToPixels(
        accuracy, location.latitude, bounds, width, height
      );
      
      // Calculate base opacity: smaller error = more opaque
      // GPS error represents 68% confidence circle, so we scale accordingly
      double baseOpacity = _calculateBaseOpacity(accuracy);
      
      // Draw error circle with appropriate transparency
      _drawErrorCircle(
        opacityGrid, centerX, centerY, radiusPixels, baseOpacity, width, height
      );
    }
    
    // Convert opacity grid to RGBA image
    return _opacityGridToImage(opacityGrid, width, height);
  }
  
  /// Calculate base opacity based on GPS accuracy
  /// More accurate locations (smaller error) get higher opacity
  static double _calculateBaseOpacity(double accuracy) {
    // Inverse relationship: smaller accuracy = higher opacity
    // Scale from 0.1 (very poor accuracy) to 0.8 (very good accuracy)
    
    if (accuracy <= 3.0) return 0.8;   // Excellent GPS (indoor/outdoor boundary)
    if (accuracy <= 5.0) return 0.6;   // Very good GPS (clear sky)
    if (accuracy <= 10.0) return 0.4;  // Good GPS (normal conditions)
    if (accuracy <= 20.0) return 0.3;  // Fair GPS (some obstruction)
    if (accuracy <= 50.0) return 0.2;  // Poor GPS (significant obstruction)
    return 0.1; // Very poor GPS (>50m error)
  }
  
  /// Draw a GPS error circle on the opacity grid
  /// Uses Gaussian-like falloff from center to edge for smooth visualization
  static void _drawErrorCircle(
    List<List<double>> grid,
    double centerX,
    double centerY,
    double radius,
    double baseOpacity,
    int width,
    int height,
  ) {
    // Calculate bounding box for efficiency
    int minX = math.max(0, (centerX - radius).floor());
    int maxX = math.min(width - 1, (centerX + radius).ceil());
    int minY = math.max(0, (centerY - radius).floor());
    int maxY = math.min(height - 1, (centerY + radius).ceil());
    
    double radiusSquared = radius * radius;
    
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        double dx = x - centerX;
        double dy = y - centerY;
        double distanceSquared = dx * dx + dy * dy;
        
        if (distanceSquared <= radiusSquared) {
          // Inside the error circle - calculate falloff
          double distance = math.sqrt(distanceSquared);
          double falloff = _calculateFalloff(distance, radius);
          
          // Add to accumulated opacity (overlapping circles sum up)
          grid[y][x] = math.min(1.0, grid[y][x] + (baseOpacity * falloff));
        }
      }
    }
  }
  
  /// Calculate opacity falloff from center to edge of error circle
  /// Uses a smooth function that's full opacity at center, fading to edge
  static double _calculateFalloff(double distance, double radius) {
    if (radius <= 0) return 1.0;
    
    // Normalized distance [0, 1] where 0 = center, 1 = edge
    double normalizedDistance = distance / radius;
    
    // Smooth falloff: full opacity at center, zero at edge
    // Using cosine function for smooth transition
    return math.cos(normalizedDistance * math.pi / 2);
  }
  
  /// Convert meters to pixel distance at given latitude
  static double _metersToPixels(
    double meters, 
    double latitude, 
    LatLngBounds bounds, 
    int width, 
    int height
  ) {
    // Degrees per meter varies by latitude (Mercator projection effect)
    double metersPerDegree = 111320.0 * math.cos(latitude * math.pi / 180.0);
    double degreesPerMeter = 1.0 / metersPerDegree;
    
    double lngRange = bounds.east - bounds.west;
    double pixelsPerDegree = width / lngRange;
    
    return meters * degreesPerMeter * pixelsPerDegree;
  }
  
  /// Convert opacity grid to RGBA image with heat map colors
  static Future<ui.Image> _opacityGridToImage(
    List<List<double>> grid, 
    int width, 
    int height
  ) async {
    // Create RGBA pixel data
    Uint8List pixels = Uint8List(width * height * 4);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = (y * width + x) * 4;
        double opacity = grid[y][x];
        
        if (opacity <= 0.0) {
          // Transparent pixel
          pixels[index] = 0;     // R
          pixels[index + 1] = 0; // G
          pixels[index + 2] = 0; // B
          pixels[index + 3] = 0; // A
        } else {
          // Heat map color based on accumulated opacity
          Color color = _opacityToHeatmapColor(opacity);
          
          pixels[index] = (color.r * 255).round();     // R
          pixels[index + 1] = (color.g * 255).round(); // G
          pixels[index + 2] = (color.b * 255).round(); // B
          pixels[index + 3] = (color.a * 255).round(); // A
        }
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
  
  /// Convert accumulated opacity to heat map color
  /// Low opacity = blue/green, high opacity = yellow/red
  static Color _opacityToHeatmapColor(double opacity) {
    // Clamp opacity to reasonable range
    opacity = math.min(1.0, opacity);
    
    if (opacity < 0.25) {
      // Low density: transparent blue to blue
      double t = opacity / 0.25;
      return Color.lerp(
        Colors.blue.withValues(alpha: 0.0), 
        Colors.blue.withValues(alpha: 0.6), 
        t
      )!;
    } else if (opacity < 0.5) {
      // Medium-low density: blue to green
      double t = (opacity - 0.25) / 0.25;
      return Color.lerp(
        Colors.blue.withValues(alpha: 0.6), 
        Colors.green.withValues(alpha: 0.7), 
        t
      )!;
    } else if (opacity < 0.75) {
      // Medium-high density: green to yellow
      double t = (opacity - 0.5) / 0.25;
      return Color.lerp(
        Colors.green.withValues(alpha: 0.7), 
        Colors.yellow.withValues(alpha: 0.8), 
        t
      )!;
    } else {
      // High density: yellow to red
      double t = (opacity - 0.75) / 0.25;
      return Color.lerp(
        Colors.yellow.withValues(alpha: 0.8), 
        Colors.red.withValues(alpha: 0.9), 
        t
      )!;
    }
  }
}

/// Bounds helper class for the probabilistic density service
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