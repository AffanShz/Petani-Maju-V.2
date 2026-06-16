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

  /// Fetch all prediction history ordered by newest first
  Future<List<Map<String, dynamic>>> fetchPredictionHistory() async {
    try {
      debugPrint('PestService: Fetching prediction history from Supabase...');
      final response = await _supabase
          .from('prediction_history')
          .select()
          .order('created_at', ascending: false)
          .timeout(_timeout);
      debugPrint('PestService: Fetched ${response.length} history items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('PestService Error fetching history: $e');
      rethrow;
    }
  }

  /// Delete a single prediction history item by its ID
  Future<void> deletePredictionHistory(String id) async {
    try {
      debugPrint('PestService: Deleting history item $id...');
      await _supabase
          .from('prediction_history')
          .delete()
          .eq('id', id)
          .timeout(_timeout);
      debugPrint('PestService: Successfully deleted history item $id');
    } catch (e) {
      debugPrint('PestService Error deleting history: $e');
      rethrow;
    }
  }

  /// Delete all prediction history records
  Future<void> deleteAllPredictionHistory() async {
    try {
      debugPrint('PestService: Deleting all history...');
      // Using neq with a non-existing value effectively deletes all rows
      await _supabase
          .from('prediction_history')
          .delete()
          .neq('id', '00000000-0000-0000-0000-000000000000')
          .timeout(_timeout);
      debugPrint('PestService: Successfully deleted all history');
    } catch (e) {
      debugPrint('PestService Error deleting all history: $e');
      rethrow;
    }
  }
}
