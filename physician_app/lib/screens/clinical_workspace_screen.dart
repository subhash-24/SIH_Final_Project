import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ClinicalWorkspaceScreen extends StatefulWidget {
  final String encounterId;
  const ClinicalWorkspaceScreen({super.key, required this.encounterId});

  @override
  State<ClinicalWorkspaceScreen> createState() => _ClinicalWorkspaceScreenState();
}

class _ClinicalWorkspaceScreenState extends State<ClinicalWorkspaceScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String _activeTab = 'clinical';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      final summary = await ApiService.getSummary(widget.encounterId);
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      // Handle error implicitly by keeping summary null
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Encounter not found or failed to load.')),
      );
    }

    final patient = _summary!['patient'] ?? {};
    final redFlags = List<dynamic>.from(_summary!['red_flags'] ?? []);
    final isUrgent = _summary!['priority'] == 'urgent';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
        title: Text('Workspace - ${patient['name']}'),
        actions: [
          if (isUrgent)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.urgentBg, borderRadius: BorderRadius.circular(4)),
              child: const Center(child: Text('URGENT', style: TextStyle(color: AppTheme.urgent, fontWeight: FontWeight.bold))),
            )
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Navigation
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildTabItem('clinical', 'Clinical Details', Icons.article),
                _buildTabItem('timeline', 'Timeline', Icons.timeline),
                _buildTabItem('ayush', 'AYUSH', Icons.spa),
                _buildTabItem('diagnosis', 'Diagnosis', Icons.medical_services),
                _buildTabItem('fhir', 'FHIR Export', Icons.import_export),
              ],
            ),
          ),
          
          // Center Content
          Expanded(
            child: Container(
              color: AppTheme.background,
              padding: const EdgeInsets.all(32),
              child: _buildActiveTabContent(),
            ),
          ),
          
          // Right Panel - Red Flags & Context
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priority & Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                
                if (redFlags.isEmpty)
                  const Text('No symptom pattern alerts detected.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                else
                  ...redFlags.map((flag) => _buildRedFlagCard(flag)).toList(),
                  
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Clinical Safety: All AI outputs are labeled and require physician verification before clinical use.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String id, String label, IconData icon) {
    final isActive = _activeTab == id;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primary : AppTheme.textSecondary),
      title: Text(label, style: TextStyle(
        color: isActive ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal
      )),
      selected: isActive,
      selectedTileColor: const Color(0xFFF0F9FF),
      onTap: () => setState(() => _activeTab = id),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'clinical': return _buildClinicalTab();
      case 'diagnosis': return _buildDiagnosisTab();
      // Additional tabs (timeline, ayush, fhir) can be similarly ported.
      default: return const Center(child: Text('Not yet implemented in Flutter port.'));
    }
  }

  Widget _buildClinicalTab() {
    final findings = _summary!['findings'] ?? {};
    
    return ListView(
      children: [
        const Text('Clinical Assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildSection('Chief Complaint', findings['chief_complaint'] ?? []),
        _buildSection('History of Present Illness', findings['hpi'] ?? []),
        _buildSection('Review of Systems', findings['ros'] ?? []),
      ],
    );
  }

  Widget _buildSection(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(item['value'] ?? '', style: const TextStyle(fontSize: 15))),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0))
                  ),
                  child: Text((item['source'] ?? '').replaceAll('_', ' ').toUpperCase(), 
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )).toList()
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Diagnosis Entry', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Search Diagnosis Code/Term',
            hintText: 'Type to search...',
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Physician Notes',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Confirm Diagnosis'),
        )
      ],
    );
  }

  Widget _buildRedFlagCard(Map<String, dynamic> flag) {
    final isUrgent = flag['severity'] == 'urgent';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.urgentBg : const Color(0xFFFFF7ED),
        border: Border.all(color: isUrgent ? const Color(0xFFFECACA) : const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isUrgent ? Icons.warning : Icons.info, color: isUrgent ? AppTheme.urgent : const Color(0xFFF97316), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(flag['rule_name'] ?? 'Alert', style: TextStyle(fontWeight: FontWeight.bold, color: isUrgent ? AppTheme.urgent : const Color(0xFFF97316)))),
            ],
          ),
          const SizedBox(height: 8),
          Text(flag['reason'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          if (flag['status'] == 'detected') ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await ApiService.acknowledgeRedFlag(flag['id']);
                _loadSummary();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
                foregroundColor: isUrgent ? AppTheme.urgent : const Color(0xFFF97316),
                side: BorderSide(color: isUrgent ? AppTheme.urgent : const Color(0xFFF97316)),
              ),
              child: const Text('Acknowledge'),
            )
          ] else if (flag['status'] == 'acknowledged') ...[
            const SizedBox(height: 8),
            const Text('✓ Acknowledged', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
          ]
        ],
      ),
    );
  }
}
