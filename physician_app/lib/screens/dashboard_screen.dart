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
  String _userName = 'Dr. Rajesh Verma';
  String _activeFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchQueue();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _fetchQueue());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Dr. Rajesh Verma';
      });
    }
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
          _error = 'Could not load live patient queue.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) context.go('/login');
  }

  List<dynamic> get _filteredQueue {
    return _queue.where((entry) {
      // Filter tab
      if (_activeFilter == 'urgent' && entry['priority'] != 'urgent') return false;
      if (_activeFilter == 'waiting' && entry['status'] != 'physician_review') return false;
      if (_activeFilter == 'completed' && entry['status'] != 'completed') return false;

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (entry['patient_name'] ?? '').toString().toLowerCase();
        final complaint = (entry['chief_complaint'] ?? '').toString().toLowerCase();
        final abha = (entry['abha_id'] ?? '').toString().toLowerCase();
        final uhid = (entry['uhid'] ?? '').toString().toLowerCase();
        return name.contains(q) || complaint.contains(q) || abha.contains(q) || uhid.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final urgentCount = _queue.where((q) => q['priority'] == 'urgent').length;
    final waitingCount = _queue.where((q) => q['status'] == 'physician_review').length;
    final totalCount = _queue.length;
    final completedCount = _queue.where((q) => q['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // 1. Institutional Top Bar (Stitch Screen 1)
          _buildTopInstitutionalBar(urgentCount),

          // 2. Main Body with Left Navigation & Center Console
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Navigation Drawer
                _buildLeftSidebar(),

                // Center Main Workspace
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Context Band
                            _buildContextBanner(),
                            const SizedBox(height: 16),

                            // Metrics Band (5 Tiles)
                            _buildMetricsBand(
                              total: totalCount,
                              waiting: waitingCount,
                              urgent: urgentCount,
                              completed: completedCount,
                            ),
                            const SizedBox(height: 20),

                            // Filter Chips & Search Bar
                            _buildFilterSection(totalCount, urgentCount, waitingCount, completedCount),
                            const SizedBox(height: 16),

                            // Triage Queue Table
                            _buildQueueTable(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInstitutionalBar(int urgentCount) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // Emblem & Hospital Details
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            width: 1,
            color: AppTheme.border,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Text(
                    'Arogya-Saathi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '(आरोग्य-साथी)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Text(
                'AIIMS New Delhi • OPD Block 3, Cardiology',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Central Search Input
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search patient by ABHA ID, UHID or name...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // ABDM Verified Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.cloud_done, size: 15, color: AppTheme.secondary),
                SizedBox(width: 6),
                Text(
                  'ABDM Connected (M2/M3) • FHIR R4',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondary),
                ),
              ],
            ),
          ),

          if (urgentCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.urgentBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.urgentBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency, size: 15, color: AppTheme.urgent),
                  const SizedBox(width: 6),
                  Text(
                    '$urgentCount Urgent Alert${urgentCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.urgent),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(width: 16),
          Container(height: 28, width: 1, color: AppTheme.border),
          const SizedBox(width: 16),

          // User Profile Pill & Sign Out
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _userName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              Row(
                children: const [
                  CircleAvatar(radius: 3, backgroundColor: AppTheme.secondary),
                  SizedBox(width: 4),
                  Text(
                    'Room 204 • In Consultation',
                    style: TextStyle(fontSize: 11, color: AppTheme.secondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'CLINICAL OPERATIONS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
            ),
          ),
          _buildSidebarItem('Triage Queue', Icons.view_kanban, isActive: true, badge: _queue.isNotEmpty ? '${_queue.length}' : null),
          _buildSidebarItem('Active Patient Chart', Icons.personal_injury, onTap: () {
            if (_queue.isNotEmpty) {
              context.go('/workspace/${_queue.first['encounter_id']}');
            }
          }),
          _buildSidebarItem('Red Flag Emergency', Icons.emergency, isUrgent: _queue.any((q) => q['priority'] == 'urgent'), onTap: () {
            if (_queue.isNotEmpty) {
              context.go('/workspace/${_queue.first['encounter_id']}');
            }
          }),
          _buildSidebarItem('Diagnostics & OCR', Icons.document_scanner),
          _buildSidebarItem('Medical Timeline', Icons.timeline),

          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'CODING & STANDARDS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
            ),
          ),
          _buildSidebarItem('AYUSH / Integrative', Icons.spa),
          _buildSidebarItem('ICD-11 & NAMASTE', Icons.menu_book),
          _buildSidebarItem('FHIR R4 Inspector', Icons.data_object),
          _buildSidebarItem('Sign-off & Audit', Icons.verified),

          const Spacer(),

          // OPD Session Status Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('OPD Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Session AM-II • Room 204\nQueue: ${_queue.length} registered',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool isActive = false, bool isUrgent = false, String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Colors.white
                  : (isUrgent ? AppTheme.urgent : AppTheme.textSecondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withValues(alpha: 0.2) : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_hospital, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Cardiology OPD Block 3',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Session AM-II',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Live Patient Triage & Intake Ingestion Console • ABHA M2/M3 Synced',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 3, backgroundColor: AppTheme.secondary),
                    SizedBox(width: 6),
                    Text(
                      'AI Triage Service: Active (Cloud LLM)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _fetchQueue,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBand({
    required int total,
    required int waiting,
    required int urgent,
    required int completed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return GridView.count(
          crossAxisCount: isNarrow ? 2 : 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isNarrow ? 2.0 : 1.8,
          children: [
            _buildStatTile('Total Checked-In', '$total', 'Registered', Icons.how_to_reg, AppTheme.primary, 1.0),
            _buildStatTile('Waiting Intake', '$waiting', 'in queue lounge', Icons.hourglass_top, AppTheme.tertiary, total > 0 ? waiting / total : 0.0),
            _buildStatTile('In Consultation', '1', 'Active (Room 204)', Icons.medical_services, AppTheme.secondary, 1.0),
            _buildStatTile('Urgent Triage Alert', '$urgent', 'Cardio-angina risk', Icons.emergency, AppTheme.urgent, urgent > 0 ? 1.0 : 0.0, isUrgent: urgent > 0),
            _buildStatTile('Completed', '$completed', 'Processed', Icons.check_circle, AppTheme.textSecondary, total > 0 ? completed / total : 0.0),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, String sub, IconData icon, Color color, double progress, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.urgentBg.withValues(alpha: 0.5) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUrgent ? AppTheme.urgentBorder : AppTheme.border,
          width: isUrgent ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isUrgent ? AppTheme.urgent : AppTheme.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? AppTheme.urgent : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUrgent ? AppTheme.urgent : AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(int total, int urgent, int waiting, int completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'All ($total)'),
              _buildFilterChip('urgent', 'Urgent / High Risk ($urgent)', isUrgent: true),
              _buildFilterChip('waiting', 'Waiting Review ($waiting)'),
              _buildFilterChip('completed', 'Completed ($completed)'),
            ],
          ),
          Text(
            'Showing ${_filteredQueue.length} of $total patients',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {bool isUrgent = false}) {
    final isSelected = _activeFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _activeFilter = filterKey),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isUrgent ? AppTheme.urgent : AppTheme.textSecondary),
      ),
      selectedColor: isUrgent ? AppTheme.urgent : AppTheme.primary,
      backgroundColor: isUrgent ? AppTheme.urgentBg : AppTheme.surfaceLow,
      side: BorderSide(
        color: isUrgent ? AppTheme.urgentBorder : AppTheme.border,
        width: 0.8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildQueueTable() {
    if (_loading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 32, color: AppTheme.urgent),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.urgent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _fetchQueue, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    final list = _filteredQueue;
    if (list.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text('No matching patients in queue.', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 44, child: Text('Q#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 3, child: Text('PATIENT / IDENTIFIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 4, child: Text('CHIEF COMPLAINT (INTAKE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 2, child: Text('TRIAGE STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                SizedBox(width: 90, child: Text('WAIT TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                SizedBox(width: 110, child: Text('ACTION', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = list[index];
              final isUrgent = entry['priority'] == 'urgent';
              final queueNo = (index + 1).toString().padLeft(2, '0');
              final waitMinutes = entry['waiting_minutes'] ?? 0;

              return Container(
                color: isUrgent ? AppTheme.urgentBg.withValues(alpha: 0.25) : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Q#
                    SizedBox(
                      width: 44,
                      child: Text(
                        queueNo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? AppTheme.urgent : AppTheme.textMuted,
                        ),
                      ),
                    ),

                    // Patient Details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['patient_name'] ?? 'Unknown Patient',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry['age'] ?? '-'} Yrs • ${entry['gender'] ?? '-'}  •  UHID: ${entry['uhid'] ?? 'AI-7824'}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),

                    // Chief Complaint
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry['chief_complaint'] ?? 'No intake complaint',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          if (isUrgent) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.warning, size: 12, color: AppTheme.urgent),
                                SizedBox(width: 4),
                                Text(
                                  'Red Flag Rule Triggered: Cardiac Risk Pathway',
                                  style: TextStyle(fontSize: 11, color: AppTheme.urgent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Triage Status Pill
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppTheme.buildBadge(
                          label: isUrgent ? 'URGENT REVIEW' : 'WAITING PHYSICIAN',
                          icon: isUrgent ? Icons.crisis_alert : Icons.hourglass_empty,
                          isUrgent: isUrgent,
                        ),
                      ),
                    ),

                    // Wait Time
                    SizedBox(
                      width: 90,
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: waitMinutes > 20 ? AppTheme.urgent : AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '$waitMinutes min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: waitMinutes > 20 ? AppTheme.urgent : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Button
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => context.go('/workspace/${entry['encounter_id']}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUrgent ? AppTheme.urgent : AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Open Chart'),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
