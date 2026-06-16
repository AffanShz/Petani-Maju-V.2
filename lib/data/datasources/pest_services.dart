import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PestService {
  SupabaseClient get _supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase not initialized: $e');
      throw Exception('Database service unavailable');
    }
  }

  // Timeout for requests
  static const Duration _timeout = Duration(seconds: 10);

  Future<List<Map<String, dynamic>>> fetchPests({String? query}) async {
    try {
      debugPrint('PestService: Fetching pests from Supabase...');

      var dbQuery = _supabase.from('hama').select();

      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.ilike('nama', '%$query%');
      }

      final response =
          await dbQuery.order('nama', ascending: true).timeout(_timeout);

      debugPrint('PestService: Successfully fetched ${response.length} pests');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('PestService Error: $e');
      rethrow;
    }
  }

  /// Fetch a single pest by ID
  Future<Map<String, dynamic>?> fetchPestById(int id) async {
    try {
      final response = await _supabase
          .from('hama')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('PestService Error fetching pest by ID: $e');
      rethrow;
    }
  }

  /// Fetch a single pest by name
  Future<Map<String, dynamic>?> fetchPestByName(String name) async {
    try {
      final response = await _supabase
          .from('hama')
          .select()
          .ilike('nama', name)
          .maybeSingle()
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('PestService Error fetching pest by name: $e');
      return null;
    }
  }

  /// Fetch tomato disease detail from penyakit_tomat table
  Future<Map<String, dynamic>?> fetchTomatoDiseaseByName(String name) async {
    try {
      final response = await _supabase
          .from('penyakit_tomat')
          .select()
          .ilike('nama_penyakit', name)
          .maybeSingle()
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('PestService Error fetching tomato disease: $e');
      return null;
    }
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      final extension = filePath.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'history/$fileName';

      await _supabase.storage.from('images').upload(path, file);
      
      final String publicUrl = _supabase.storage.from('images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('PestService Error uploading image: $e');
      rethrow;
    }
  }

  /// Save prediction result to history
  Future<void> savePredictionHistory(Map<String, dynamic> data) async {
    try {
      debugPrint('PestService: Saving prediction history to Supabase...');
      // Ensure column names match schema: created_at is handled by DB default or passed here
      await _supabase.from('prediction_history').insert(data).timeout(_timeout);
      debugPrint('PestService: Successfully saved prediction history');
    } catch (e) {
      debugPrint('PestService Error saving history: $e');
    }
  }
}
