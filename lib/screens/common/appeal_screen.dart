import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import 'dart:async';
import '../../utils/theme.dart';

class AppealScreen extends StatefulWidget {
  final AccountSuspension suspension;

  const AppealScreen({super.key, required this.suspension});

  @override
  State<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appealController = TextEditingController();
  final _reportService = ReportService();
  final _notificationService = NotificationService();
  bool _isSubmitting = false;
  Timer? _countdownTimer;
  Duration? _timeRemaining;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _appealController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.suspension.appealDeadline)) {
      setState(() => _timeRemaining = Duration.zero);
      _countdownTimer?.cancel();
    } else {
      setState(() {
        _timeRemaining = widget.suspension.appealDeadline.difference(now);
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} hari ${duration.inHours % 24} jam';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes % 60} menit';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit ${duration.inSeconds % 60} detik';
    } else {
      return '${duration.inSeconds} detik';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStillAppeal = widget.suspension.canAppeal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajukan Banding'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akun Ditangguhkan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.suspension.isPermanent
                                ? 'Status: PERMANEN'
                                : 'Status: SEMENTARA',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reason
              const Text(
                'Alasan Penangguhan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.suspension.reason,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Countdown timer
              if (!widget.suspension.isPermanent && canStillAppeal)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.lightOrange, AppColors.darkOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waktu Tersisa untuk Banding:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeRemaining != null
                                  ? _formatDuration(_timeRemaining!)
                                  : 'Menghitung...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (!canStillAppeal)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: Colors.black54, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Waktu banding telah habis.\nPenangguhan menjadi permanen.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Appeal form
              if (canStillAppeal && !widget.suspension.appealSubmitted) ...[
                const Text(
                  'Ajukan Banding:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jelaskan mengapa Anda merasa penangguhan ini tidak adil. Berikan bukti atau penjelasan yang mendukung.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _appealController,
                  decoration: const InputDecoration(
                    labelText: 'Pesan Banding',
                    hintText: 'Tuliskan alasan banding Anda di sini...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Pesan banding harus diisi';
                    }
                    if (value.trim().length < 50) {
                      return 'Pesan terlalu singkat (min 50 karakter)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitAppeal,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSubmitting ? 'Mengirim...' : 'Kirim Banding',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (widget.suspension.appealSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banding Telah Dikirim',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Admin akan meninjau banding Anda dalam 1-3 hari kerja.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesan Banding Anda:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.suspension.appealMessage ?? '-',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAppeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User tidak ditemukan');
      }

      final appealMessage = _appealController.text.trim();

      // Submit appeal
      await _reportService.submitAppeal(
        widget.suspension.id ?? '',
        appealMessage,
      );

      // Notify admin
      await _notificationService.notifyAppealSubmitted(
        userId,
        widget.suspension.accountType,
        appealMessage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banding berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
