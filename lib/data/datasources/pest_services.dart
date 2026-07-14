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

  /// Map jenis tanaman -> nama tabel detail penyakit di Supabase
  static const Map<String, String> _diseaseTableByPlant = {
    'Tomat': 'penyakit_tomat',
    'Padi': 'penyakit_padi',
    'Teh': 'penyakit_teh',
  };

  /// Fetch detail penyakit dari tabel sesuai jenis tanaman.
  /// Tabel: penyakit_tomat / penyakit_padi / penyakit_teh (skema identik).
  Future<Map<String, dynamic>?> fetchDiseaseDetailByName({
    required String plantType,
    required String name,
  }) async {
    final table = _diseaseTableByPlant[plantType];
    if (table == null) {
      debugPrint('PestService: No disease table for plant "$plantType"');
      return null;
    }

    try {
      final response = await _supabase
          .from(table)
          .select()
          .ilike('nama_penyakit', name)
          .maybeSingle()
          .timeout(_timeout);

      return response;
    } catch (e) {
      debugPrint('PestService Error fetching disease from $table: $e');
      return null;
    }
  }

  /// Fetch tomato disease detail from penyakit_tomat table.
  /// Dipertahankan untuk kompatibilitas; delegasi ke [fetchDiseaseDetailByName].
  Future<Map<String, dynamic>?> fetchTomatoDiseaseByName(String name) {
    return fetchDiseaseDetailByName(plantType: 'Tomat', name: name);
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage(String filePath) async {
    try {
      // Validate session before upload — expired JWT causes RLS 403
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Sesi tidak ditemukan. Silakan masuk kembali.');
      }
      final expiresAt = session.expiresAt;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt != null && nowSeconds >= expiresAt) {
        await _supabase.auth.refreshSession();
      }

      final file = File(filePath);
      final extension = filePath.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'history/$fileName';

      await _supabase.storage.from('images').upload(path, file);

      final String publicUrl =
          _supabase.storage.from('images').getPublicUrl(path);
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
          .eq('user_id', _supabase.auth.currentUser!.id)
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
      await _supabase
          .from('prediction_history')
          .delete()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .timeout(_timeout);
      debugPrint('PestService: Successfully deleted all history');
    } catch (e) {
      debugPrint('PestService Error deleting all history: $e');
      rethrow;
    }
  }
}
