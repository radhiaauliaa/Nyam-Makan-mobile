import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final _reportService = ReportService();
  final _notificationService = NotificationService();
  String _selectedFilter = 'pending'; // pending, resolved, all

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Kelola Laporan'),
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: AppColors.primaryOrange,
            child: Row(
              children: [
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Resolved', 'resolved'),
                _buildFilterChip('Semua', 'all'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _reportService.getReportsStream(
          status: _selectedFilter == 'all' ? null : _selectedFilter,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada laporan',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildReportTypeIcon(report.reportType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReportTypeTitle(report.reportType),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(report.createdAt, locale: 'id'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(report.status),
              ],
            ),
            const Divider(height: 24),

            // Details
            _buildDetailRow('Target ID', report.targetId),
            _buildDetailRow('Target Type', report.targetType),
            if (report.reason.isNotEmpty)
              _buildDetailRow('Alasan', report.reason),

            const SizedBox(height: 16),

            // Actions (only for pending)
            if (report.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDismissDialog(report),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showSuspendDialog(report),
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Suspend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case ReportModel.typeUserSpam:
        icon = Icons.repeat;
        color = AppColors.primaryOrange;
        break;
      case ReportModel.typeUserAbusive:
        icon = Icons.report_problem;
        color = Colors.red;
        break;
      case ReportModel.typeRestaurantPoorRating:
        icon = Icons.star_border;
        color = Colors.amber;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getReportTypeTitle(String type) {
    switch (type) {
      case ReportModel.typeUserSpam:
        return 'Spam Rating';
      case ReportModel.typeUserAbusive:
        return 'Komentar Kasar';
      case ReportModel.typeRestaurantPoorRating:
        return 'Restoran Rating Buruk';
      default:
        return 'Laporan';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppColors.primaryOrange;
        label = 'Pending';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      case 'dismissed':
        color = Colors.grey;
        label = 'Dismissed';
        break;
      default:
        color = Colors.blue;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showDismissDialog(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Laporan'),
        content: const Text(
          'Yakin ingin menolak laporan ini? Tidak ada tindakan yang akan diambil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reportService.resolveReport(report.id, 'dismissed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Laporan ditolak')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(ReportModel report) {
    final reasonController = TextEditingController();
    final durationController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Akun'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suspend ${report.targetType}: ${report.targetId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Suspend',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan alasan penangguhan',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Durasi (hari)',
                  border: OutlineInputBorder(),
                  suffixText: 'hari',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Text(
                'Target memiliki 7 hari untuk banding. Jika tidak, suspend menjadi permanen.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              final duration = int.tryParse(durationController.text) ?? 7;

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan harus diisi')),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                // Suspend account
                await _reportService.suspendAccount(
                  report.targetId,
                  report.targetType,
                  reason,
                  duration,
                );

                // Resolve report
                await _reportService.resolveReport(report.id ?? '', 'resolved');

                // Send notification to suspended account
                await _notificationService.notifyAccountSuspended(
                  report.targetId,
                  reason,
                  duration,
                );

                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Akun ${report.targetId} berhasil di-suspend',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}
