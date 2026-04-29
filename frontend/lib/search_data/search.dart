import 'package:http/http.dart' as http;
import 'dart:convert';

/// Model for search parameters matching search_manager.py
class SearchParams {
  final String query;
  final double minDistance;
  final double maxDistance;
  final double longitude;
  final double latitude;

  SearchParams({
    required this.query,
    required this.minDistance,
    required this.maxDistance,
    required this.longitude,
    required this.latitude,
  });

  /// Convert to query parameters for API request
  Map<String, String> toQueryParams() {
    return {
      'query': query,
      'minDistance': minDistance.toString(),
      'maxDistance': maxDistance.toString(),
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
    };
  }
}

/// Model for car park data from search results
class CarPark {
  final int id;
  final String name;
  final double longitude;
  final double latitude;
  final double distance; // distance in km from user location
  final Map<String, dynamic> rawData; // store any additional fields

  CarPark({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.distance,
    required this.rawData,
  });

  /// Create CarPark from JSON response
  factory CarPark.fromJson(Map<String, dynamic> json) {
    return CarPark(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      longitude: (json['longitude'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      rawData: json,
    );
  }

  @override
  String toString() => 'CarPark(name: $name, distance: $distance km)';
}

/// Search service to fetch car parks from backend
class SearchService {
  final String baseUrl;
  String? _activeRequestKey;
  Future<List<CarPark>>? _activeRequest;

  SearchService({this.baseUrl = 'http://localhost:8080'});

  String _buildRequestKey(SearchParams params) {
    return [
      params.query.trim().toLowerCase(),
      params.minDistance.toStringAsFixed(4),
      params.maxDistance.toStringAsFixed(4),
      params.longitude.toStringAsFixed(6),
      params.latitude.toStringAsFixed(6),
    ].join('|');
  }

  /// Fetch car parks based on search parameters
  /// Returns list of CarPark objects or throws an exception
  Future<List<CarPark>> searchCarParks(SearchParams params) async {
    final requestKey = _buildRequestKey(params);

    if (_activeRequestKey == requestKey && _activeRequest != null) {
      return _activeRequest!;
    }

    final request = _performSearch(params);
    _activeRequestKey = requestKey;
    _activeRequest = request;

    try {
      return await request;
    } finally {
      if (_activeRequestKey == requestKey) {
        _activeRequestKey = null;
        _activeRequest = null;
      }
    }
  }

  Future<List<CarPark>> _performSearch(SearchParams params) async {
    final uri = Uri.parse('$baseUrl/search-all');

    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Search request timeout'),
        );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarPark.fromJson(json)).toList();
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body)['error'] ?? 'Bad request';
      throw Exception(error);
    } else if (response.statusCode == 500) {
      throw Exception('Server error: Failed to fetch car parks');
    } else {
      throw Exception('Unexpected error: ${response.statusCode}');
    }
  }

  /// Helper function to search with specific radius
  Future<List<CarPark>> searchWithinRadius({
    required String query,
    required double longitude,
    required double latitude,
    required double radiusKm,
  }) async {
    final params = SearchParams(
      query: query,
      minDistance: 0,
      maxDistance: radiusKm,
      longitude: longitude,
      latitude: latitude,
    );
    return searchCarParks(params);
  }

  /// Helper function to search within a distance range
  Future<List<CarPark>> searchInDistanceRange({
    required String query,
    required double longitude,
    required double latitude,
    required double minDistanceKm,
    required double maxDistanceKm,
  }) async {
    final params = SearchParams(
      query: query,
      minDistance: minDistanceKm,
      maxDistance: maxDistanceKm,
      longitude: longitude,
      latitude: latitude,
    );
    return searchCarParks(params);
  }
}
