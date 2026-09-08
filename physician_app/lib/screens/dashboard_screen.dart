import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _queue = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  String _userName = 'Physician';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchQueue();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchQueue());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Physician';
    });
  }

  Future<void> _fetchQueue() async {
    try {
      final queue = await ApiService.getQueue();
      if (mounted) {
        setState(() {
          _queue = queue;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load patient queue.';
          _loading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final urgentCount = _queue.where((q) => q['priority'] == 'urgent').length;
    final waitingCount = _queue.where((q) => q['status'] == 'physician_review').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arogya-Saathi Physician'),
        actions: [
          Center(child: Text(_userName, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary))),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _logout,
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.primary)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good ${_getGreeting()}, ${_userName.split(' ')[0]}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text('${_queue.length} patients waiting', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _fetchQueue,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface, foregroundColor: AppTheme.primary),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              children: [
                _buildStatCard('Total Patients', _queue.length.toString(), AppTheme.primary),
                const SizedBox(width: 16),
                _buildStatCard('Urgent', urgentCount.toString(), AppTheme.urgent),
                const SizedBox(width: 16),
                _buildStatCard('Waiting Review', waitingCount.toString(), AppTheme.secondary),
              ],
            ),
            const SizedBox(height: 32),

            // Queue List
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Patient Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1),
                    if (_loading)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (_error != null)
                      Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: AppTheme.urgent))))
                    else if (_queue.isEmpty)
                      const Expanded(child: Center(child: Text('No patients in queue', style: TextStyle(color: AppTheme.textSecondary))))
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: _queue.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = _queue[index];
                            final isUrgent = entry['priority'] == 'urgent';
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              tileColor: isUrgent ? AppTheme.urgentBg : null,
                              title: Text(entry['patient_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${entry['age'] ?? '-'} yrs • ${entry['gender'] ?? '-'}'),
                                  const SizedBox(height: 4),
                                  Text(entry['chief_complaint'] ?? 'No complaint provided', maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isUrgent)
                                    const Text('⚠ URGENT', style: TextStyle(color: AppTheme.urgent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('${entry['waiting_minutes']} min', style: TextStyle(color: (entry['waiting_minutes'] ?? 0) > 20 ? AppTheme.urgent : AppTheme.textSecondary)),
                                ],
                              ),
                              onTap: () => context.go('/workspace/${entry['encounter_id']}'),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
