import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:agrinova/core/constants/colors.dart';
import 'package:agrinova/features/chatbot/widgets/recommended_drugs_list.dart';
import 'package:agrinova/data/models/chat_message.dart';
import 'package:agrinova/data/repositories/calendar_repository.dart';
import 'package:agrinova/features/calendar/bloc/calendar_bloc.dart';
import 'package:agrinova/features/calendar/screens/calendar_screen.dart';
import 'package:agrinova/features/chatbot/bloc/chatbot_bloc.dart';
import 'package:agrinova/features/drugs/screens/drug_screen.dart';
import 'package:agrinova/features/scanner/screens/scanner_screen.dart';
import 'package:agrinova/features/weather/screens/weather_detail_screen.dart';

class DrugCatalogLoader {
  static List<Map<String, dynamic>>? _cachedCatalog;

  static Future<List<Map<String, dynamic>>> loadCatalog() async {
    if (_cachedCatalog != null) return _cachedCatalog!;
    try {
      final jsonString =
          await rootBundle.loadString('katalog_obat_tanaman.json');
      final data = jsonDecode(jsonString) as List<dynamic>;
      _cachedCatalog =
          data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return _cachedCatalog!;
    } catch (e) {
      debugPrint('ChatBubble: Failed to load drug catalog: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> findDrugsFromContent(
      String content, List<Map<String, dynamic>> catalog) {
    if (content.isEmpty || catalog.isEmpty) return [];

    final matched = <Map<String, dynamic>>[];

    // 1. Tag match [RECOMMENDED_DRUGS: ...]
    final tagRegex =
        RegExp(r'\[RECOMMENDED_DRUGS:\s*(.*?)\]', caseSensitive: false);
    final tagMatch = tagRegex.firstMatch(content);
    if (tagMatch != null) {
      final rawList = tagMatch.group(1) ?? '';
      final names =
          rawList.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);

      for (final name in names) {
        final q = name.toLowerCase();
        for (final item in catalog) {
          final drugName = (item['nama_obat'] ?? item['nama'] ?? '')
              .toString()
              .toLowerCase();
          final id = (item['id'] ?? '').toString().toLowerCase();
          if (drugName == q ||
              id == q ||
              drugName.contains(q) ||
              q.contains(drugName)) {
            if (!matched.any((m) => m['id'] == item['id'])) {
              matched.add(item);
            }
          }
        }
      }
    }

    // 2. Mention scan fallback jika tag belum dicantumkan AI
    if (matched.isEmpty) {
      final lowerContent = content.toLowerCase();
      for (final item in catalog) {
        final drugName =
            (item['nama_obat'] ?? item['nama'] ?? '').toString().toLowerCase();
        if (drugName.length >= 5 && lowerContent.contains(drugName)) {
          if (!matched.any((m) => m['id'] == item['id'])) {
            matched.add(item);
          }
        }
      }
    }

    // 3. Match pencarian berdasarkan bahan aktif (Active Ingredient)
    if (matched.isEmpty) {
      final lowerContent = content.toLowerCase();
      for (final item in catalog) {
        final bahanAktif = (item['bahan_aktif'] ?? '').toString().toLowerCase();
        if (bahanAktif.isNotEmpty) {
          final words = bahanAktif
              .split(RegExp(r'[\s%,/]+'))
              .where((w) => w.length >= 4 && !RegExp(r'^\d+$').hasMatch(w));
          for (final word in words) {
            if (lowerContent.contains(word)) {
              if (!matched.any((m) => m['id'] == item['id'])) {
                matched.add(item);
                if (matched.length >= 4) break;
              }
            }
          }
        }
      }
    }

    return matched;
  }
}

class CalendarConfirmationCardWidget extends StatefulWidget {
  final Map<String, dynamic> actionData;

  const CalendarConfirmationCardWidget({super.key, required this.actionData});

  static final Map<String, String> _actionStatusCache = {};

  @override
  State<CalendarConfirmationCardWidget> createState() =>
      _CalendarConfirmationCardWidgetState();
}

class _CalendarConfirmationCardWidgetState
    extends State<CalendarConfirmationCardWidget> {
  bool _isSaving = false;
  bool _isSaved = false;
  bool _isCancelled = false;
  String? _errorMessage;

  String get _cardKey => widget.actionData.toString();

  @override
  void initState() {
    super.initState();
    final cached = CalendarConfirmationCardWidget._actionStatusCache[_cardKey];
    if (cached == 'saved') {
      _isSaved = true;
    } else if (cached == 'cancelled') {
      _isCancelled = true;
    }
  }

  List<Map<String, dynamic>> get _schedules {
    final data = widget.actionData;
    if (data.containsKey('schedules') && data['schedules'] is List) {
      final list = data['schedules'] as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [data];
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final calendarRepo = context.read<CalendarRepository>();
      final schedulesList = _schedules;

      for (final item in schedulesList) {
        final namaTanaman =
            item['nama_tanaman']?.toString() ?? 'Kegiatan Pertanian';
        final rawDate = item['tanggal_tanam']?.toString() ?? '';
        final parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
        final catatan = item['catatan']?.toString();

        await calendarRepo.addSchedule(
          namaTanaman: namaTanaman,
          tanggalTanam: parsedDate,
          catatan: catatan,
        );
      }

      if (!mounted) return;
      try {
        context.read<CalendarBloc>().add(LoadSchedules());
      } catch (_) {}

      CalendarConfirmationCardWidget._actionStatusCache[_cardKey] = 'saved';

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Gagal menyimpan jadwal: $e';
        });
      }
    }
  }

  void _handleCancel() {
    CalendarConfirmationCardWidget._actionStatusCache[_cardKey] = 'cancelled';
    setState(() {
      _isCancelled = true;
    });
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    if (parsed.hour != 0 || parsed.minute != 0) {
      return '${DateFormat('d MMM yyyy, HH:mm', 'id').format(parsed)} WIB';
    }
    return DateFormat('d MMM yyyy', 'id').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final items = _schedules;
    final isMultiple = items.length > 1;

    if (_isCancelled) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aksi pembuatan jadwal dibatalkan.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_isSaved) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMultiple
                        ? 'Total ${items.length} Jadwal Berhasil Disimpan!'
                        : 'Jadwal Tanam Berhasil Disimpan!',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final calendarRepo = context.read<CalendarRepository>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => BlocProvider(
                        create: (_) => CalendarBloc(
                          calendarRepository: calendarRepo,
                        )..add(LoadSchedules()),
                        child: const CalendarScreen(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.white,
                  highlightColor: const Color(0xFFAED581),
                  period: const Duration(milliseconds: 2500),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Buka Fitur Kalender',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMultiple
                      ? 'Pratinjau Jadwal Rutin (${items.length} Kegiatan)'
                      : 'Pratinjau Jadwal Tanam Baru',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 12),
          if (!isMultiple) ...[
            _buildDetailRow(Icons.grass, 'Tanaman',
                items[0]['nama_tanaman']?.toString() ?? 'Tanaman'),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.calendar_today_rounded, 'Tanggal',
                _formatDate(items[0]['tanggal_tanam']?.toString())),
            if (items[0]['catatan'] != null &&
                items[0]['catatan'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.notes_rounded, 'Catatan',
                  items[0]['catatan'].toString()),
            ],
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final name = item['nama_tanaman']?.toString() ?? 'Kegiatan';
                  final date = _formatDate(item['tanggal_tanam']?.toString());
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                  fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _handleCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Batal',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isMultiple ? 'Simpan Semua' : 'Simpan Jadwal',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

class WeatherRecommendationCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const WeatherRecommendationCardWidget({super.key, required this.data});

  IconData _getWeatherIcon(String kondisi) {
    final lower = kondisi.toLowerCase();
    if (lower.contains('petir') ||
        lower.contains('badai') ||
        lower.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }
    if (lower.contains('hujan') || lower.contains('rain')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('gerimis') || lower.contains('drizzle')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('berawan') ||
        lower.contains('cloud') ||
        lower.contains('mendung')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('kabut') ||
        lower.contains('fog') ||
        lower.contains('mist')) {
      return Icons.cloud_queue_rounded;
    }
    if (lower.contains('malam') || lower.contains('night')) {
      return Icons.nights_stay_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherIconColor(String kondisi) {
    final lower = kondisi.toLowerCase();
    if (lower.contains('petir') ||
        lower.contains('badai') ||
        lower.contains('thunder')) {
      return Colors.deepPurple;
    }
    if (lower.contains('hujan') || lower.contains('rain')) {
      return Colors.blue.shade700;
    }
    if (lower.contains('gerimis') || lower.contains('drizzle')) {
      return Colors.teal;
    }
    if (lower.contains('berawan') ||
        lower.contains('cloud') ||
        lower.contains('mendung')) {
      return Colors.blueGrey;
    }
    if (lower.contains('malam') || lower.contains('night')) {
      return Colors.indigo;
    }
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    final lokasi = data['lokasi']?.toString() ?? 'Lokasi Kebun';
    final suhu = data['suhu']?.toString() ?? '-';
    final kelembapan = data['kelembapan']?.toString() ?? '-';
    final kondisi = data['kondisi']?.toString() ?? '-';
    final rekomendasi = data['rekomendasi_irigasi']?.toString() ?? '-';
    final pemupukan = data['saran_pemupukan']?.toString();

    final iconData = _getWeatherIcon(kondisi);
    final iconColor = _getWeatherIconColor(kondisi);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F7FA),
            Color(0xFFE8F5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF80DEEA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekomendasi Irigasi Kebun ($lokasi)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064),
                      ),
                    ),
                    Text(
                      '$kondisi • Suhu $suhu • Kelembapan $kelembapan',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF00838F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFB2EBF2)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.water_drop_rounded,
                  size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style:
                        const TextStyle(fontSize: 12.5, color: Colors.black87),
                    children: [
                      const TextSpan(
                        text: 'Penyiraman: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      TextSpan(text: rekomendasi),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (pemupukan != null && pemupukan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco_rounded,
                    size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black87),
                      children: [
                        const TextSpan(
                          text: 'Pemupukan: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen),
                        ),
                        TextSpan(text: pemupukan),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WeatherDetailScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006064),
                side: const BorderSide(color: Color(0xFF00838F)),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.8),
              ),
              child: Shimmer.fromColors(
                baseColor: const Color(0xFF006064),
                highlightColor: const Color(0xFFAED581),
                period: const Duration(milliseconds: 2500),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_queue_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Lihat Prakiraan Cuaca Lengkap',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  void _handleActionLink(BuildContext context, String? href) {
    if (href == null || href.isEmpty) return;

    if (href.startsWith('action:prompt:')) {
      final promptText =
          Uri.decodeComponent(href.substring('action:prompt:'.length));
      try {
        context.read<ChatbotBloc>().add(SendMessage(text: promptText));
      } catch (e) {
        debugPrint('ChatBubble: Failed to dispatch prompt: $e');
      }
      return;
    }

    if (href == 'action:calendar') {
      final calendarRepo = context.read<CalendarRepository>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => BlocProvider(
            create: (_) => CalendarBloc(
              calendarRepository: calendarRepo,
            )..add(LoadSchedules()),
            child: const CalendarScreen(),
          ),
        ),
      );
    } else if (href == 'action:drugs') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DrugScreen()),
      );
    } else if (href == 'action:weather') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
      );
    } else if (href == 'action:scanner') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
    }
  }

  void _openImageViewer(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                clipBehavior: Clip.none,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.black87,
                      child: const Text(
                        'Gambar tidak dapat dimuat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic>? _extractProposeActionData(String content) {
    final regex = RegExp(
      r'\[PROPOSE_ACTION:\s*CREATE_CALENDAR_SCHEDULE\]\s*```(?:json)?\s*(\{.*?\})\s*```',
      dotAll: true,
    );
    var match = regex.firstMatch(content);
    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error parsing propose action json: $e');
        }
      }
    }

    final rawRegex = RegExp(
      r'\[PROPOSE_ACTION:\s*CREATE_CALENDAR_SCHEDULE\]\s*(\{.*?\})',
      dotAll: true,
    );
    match = rawRegex.firstMatch(content);
    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error parsing raw propose action json: $e');
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractWeatherRecommendationData(String content) {
    final regex = RegExp(
      r'\[WEATHER_RECOMMENDATION\]\s*```(?:json)?\s*(\{.*?\})\s*```',
      dotAll: true,
    );
    var match = regex.firstMatch(content);
    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error parsing weather recommendation json: $e');
        }
      }
    }

    final rawRegex = RegExp(
      r'\[WEATHER_RECOMMENDATION\]\s*(\{.*?\})',
      dotAll: true,
    );
    match = rawRegex.firstMatch(content);
    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error parsing raw weather recommendation json: $e');
        }
      }
    }
    return null;
  }

  Widget _buildActionButtonsCard(
      BuildContext context, List<RegExpMatch> matches) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBE7),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: matches.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          final label = m.group(1) ?? '';
          final prompt = m.group(2) ?? '';
          final isLast = idx == matches.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  final text = Uri.decodeComponent(prompt);
                  try {
                    context.read<ChatbotBloc>().add(SendMessage(text: text));
                  } catch (e) {
                    debugPrint('ChatBubble option click error: $e');
                  }
                },
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(14) : Radius.zero,
                  bottom: isLast ? const Radius.circular(14) : Radius.zero,
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: AppColors.primaryGreen,
                          highlightColor: const Color(0xFFAED581),
                          period: const Duration(milliseconds: 2500),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final hasImage = message.imagePath != null && message.imagePath!.isNotEmpty;

    final promptLinkRegex = RegExp(r'\[(.*?)\]\(action:prompt:(.*?)\)');
    final drugTagRegex =
        RegExp(r'\[RECOMMENDED_DRUGS:\s*(.*?)\]', caseSensitive: false);
    final proposeActionRegex = RegExp(
      r'\[PROPOSE_ACTION:\s*CREATE_CALENDAR_SCHEDULE\][\s\S]*?(```(?:json)?[\s\S]*?```|\{[\s\S]*?\})',
    );
    final weatherTagRegex = RegExp(
      r'\[WEATHER_RECOMMENDATION\][\s\S]*?(```(?:json)?[\s\S]*?```|\{[\s\S]*?\})',
    );

    final matches = promptLinkRegex.allMatches(message.content).toList();
    final proposeData = _extractProposeActionData(message.content);
    final weatherData = _extractWeatherRecommendationData(message.content);

    var cleanContent = message.content
        .replaceAll(promptLinkRegex, '')
        .replaceAll(drugTagRegex, '')
        .replaceAll(proposeActionRegex, '')
        .replaceAll(weatherTagRegex, '')
        .trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                child: const Icon(Icons.eco,
                    size: 18, color: AppColors.primaryGreen),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () =>
                          _openImageViewer(context, message.imagePath!),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(message.imagePath!),
                              width: 200,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 200,
                                height: 100,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (message.content.isNotEmpty) const SizedBox(height: 8),
                  ],
                  if (message.content.isEmpty && message.isStreaming)
                    _buildTypingIndicator()
                  else if (isUser)
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    MarkdownBody(
                      data: cleanContent.isNotEmpty
                          ? cleanContent
                          : message.content,
                      onTapLink: (text, href, title) =>
                          _handleActionLink(context, href),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                        h3: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          height: 1.4,
                        ),
                        h4: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        tableHead: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                          fontSize: 12,
                        ),
                        tableBody: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        tableBorder: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        tablePadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        a: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        listBullet: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primaryGreen,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Render Kartu Rekomendasi Irigasi & Cuaca (Agentic Weather Action)
                    if (weatherData != null)
                      WeatherRecommendationCardWidget(data: weatherData),

                    // Render Kartu Pratinjau Konfirmasi Jadwal Tanam (Agentic Calendar Action)
                    if (proposeData != null)
                      CalendarConfirmationCardWidget(actionData: proposeData),

                    // Render FutureBuilder untuk Produk Obat Rekomendasi
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: DrugCatalogLoader.loadCatalog(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final catalog = snapshot.data!;
                        final matched = DrugCatalogLoader.findDrugsFromContent(
                            message.content, catalog);
                        if (matched.isEmpty) return const SizedBox.shrink();
                        return RecommendedDrugsList(drugs: matched);
                      },
                    ),

                    if (matches.isNotEmpty)
                      _buildActionButtonsCard(context, matches),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _Dot(delay: i * 200)),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
