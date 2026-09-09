import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

class VoiceInterviewScreen extends StatefulWidget {
  const VoiceInterviewScreen({super.key});

  @override
  State<VoiceInterviewScreen> createState() => _VoiceInterviewScreenState();
}

class _VoiceInterviewScreenState extends State<VoiceInterviewScreen> with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus, bitRate: 128000),
          path: kIsWeb ? '' : '${Directory.systemTemp.path}/audio.webm',
        );
        setState(() {
          _isRecording = true;
        });
        _pulseController.repeat(reverse: true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    _pulseController.stop();
    _pulseController.reset();

    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final state = context.read<AppState>();
        if (state.interviewId == null) {
          throw Exception("No active interview.");
        }

        List<int> bytes;
        if (kIsWeb) {
          final response = await http.get(Uri.parse(path));
          bytes = response.bodyBytes;
        } else {
          bytes = await File(path).readAsBytes();
        }

        // Upload
        final result = await ApiService.submitAudioFile(
          interviewId: state.interviewId!,
          audioBytes: bytes,
          language: state.languageCode,
        );

        if (result.containsKey('transcript')) {
          state.setTranscript(result['transcript']);
        }
        
        if (result.containsKey('findings') && result['findings'] is List) {
           final findings = (result['findings'] as List).map((f) {
             return ClinicalFinding(
               fieldType: f['field_type'] ?? 'unknown',
               value: f['value'] ?? '',
               source: f['source'] ?? 'ai_extracted',
               needsReview: true,
             );
           }).toList();
           state.addFindings(findings);
        }

        if (mounted) {
          context.go('/transcript');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('Voice Interview', 'वॉयस इंटरव्यू')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const FlowProgressIndicator(
                currentStep: 1,
                totalSteps: 6,
                stepLabel: 'Interview',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                state.currentQuestion ?? state.tr('Please describe your symptoms...', 'कृपया अपने लक्षणों का वर्णन करें...'),
                style: AppTextStyles.question,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              if (_isProcessing)
                 const CircularProgressIndicator(color: AppColors.brand)
              else
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red.withOpacity(0.1) : AppColors.brandLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isRecording ? Colors.red : AppColors.brand,
                              width: 2
                            ),
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded, 
                            size: 64, 
                            color: _isRecording ? Colors.red : AppColors.brand
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isProcessing 
                    ? state.tr('Processing audio with AI...', 'AI के साथ ऑडियो प्रोसेस किया जा रहा है...')
                    : _isRecording 
                        ? state.tr('Tap to stop', 'रोकने के लिए टैप करें') 
                        : state.tr('Tap to speak', 'बोलने के लिए टैप करें'),
                style: AppTextStyles.label.copyWith(
                  color: _isRecording ? Colors.red : AppColors.textSecondary
                ),
              ),
              
              const Spacer(),
              
            ],
          ),
        ),
      ),
    );
  }
}
