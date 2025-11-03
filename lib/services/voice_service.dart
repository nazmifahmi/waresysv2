import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart';  // <-- REMOVED due to compatibility issues
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // final SpeechToText _speechToText = SpeechToText();  // <-- REMOVED
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isRecording = false;
  String _recognizedText = '';
  
  // Stream controllers for real-time updates
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStreamController = StreamController<bool>.broadcast();
  final StreamController<double> _soundLevelStreamController = StreamController<double>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isRecording => _isRecording;
  String get recognizedText => _recognizedText;
  
  // Streams
  Stream<String> get textStream => _textStreamController.stream;
  Stream<bool> get listeningStream => _listeningStreamController.stream;
  Stream<double> get soundLevelStream => _soundLevelStreamController.stream;

  /// Initialize the voice service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // NOTE: Speech-to-text functionality temporarily disabled due to Android Gradle Plugin compatibility issues
      // Initialize speech to text
      // _isInitialized = await _speechToText.initialize(
      //   onError: (error) {
      //     debugPrint('Speech recognition error: ${error.errorMsg}');
      //   },
      //   onStatus: (status) {
      //     debugPrint('Speech recognition status: $status');
      //     _isListening = status == 'listening';
      //     _listeningStreamController.add(_isListening);
      //   },
      // );

      // For now, just mark as initialized for recording functionality
      _isInitialized = true;
      
      debugPrint('Voice service initialized successfully (recording only)');
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Start listening for speech (currently disabled)
  Future<bool> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      debugPrint('Voice service not initialized');
      return false;
    }

    // NOTE: Speech-to-text functionality temporarily disabled
    debugPrint('Speech-to-text functionality is currently disabled due to compatibility issues');
    return false;

    // try {
    //   final success = await _speechToText.listen(
    //     onResult: (result) {
    //       _recognizedText = result.recognizedWords;
    //       _textStreamController.add(_recognizedText);
    //       debugPrint('Recognized text: $_recognizedText');
    //     },
    //     listenFor: listenFor ?? const Duration(seconds: 30),
    //     pauseFor: pauseFor ?? const Duration(seconds: 3),
    //     partialResults: true,
    //     onSoundLevelChange: (level) {
    //       _soundLevelStreamController.add(level);
    //     },
    //     localeId: localeId,
    //   );
    //   
    //   if (success) {
    //     _isListening = true;
    //     _listeningStreamController.add(_isListening);
    //   }
    //   
    //   return success;
    // } catch (e) {
    //   debugPrint('Failed to start listening: $e');
    //   return false;
    // }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // await _speechToText.stop();  // <-- REMOVED
      _isListening = false;
      _listeningStreamController.add(_isListening);
      debugPrint('Stopped listening');
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
  }

  /// Cancel listening for speech
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      // await _speechToText.cancel();  // <-- REMOVED
      _isListening = false;
      _recognizedText = '';
      _listeningStreamController.add(_isListening);
      _textStreamController.add(_recognizedText);
      debugPrint('Cancelled listening');
    } catch (e) {
      debugPrint('Failed to cancel listening: $e');
    }
  }

  /// Start recording audio to file
  Future<bool> startRecording({String? filePath}) async {
    if (_isRecording) {
      debugPrint('Already recording');
      return true;
    }

    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Check if recorder has permission
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('Audio recorder permission denied');
        return false;
      }

      // Generate file path if not provided
      filePath ??= await _generateAudioFilePath();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isRecording = true;
      debugPrint('Started recording to: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('Not currently recording');
      return null;
    }

    try {
      final filePath = await _audioRecorder.stop();
      _isRecording = false;
      debugPrint('Stopped recording. File saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Generate a unique file path for audio recording
  Future<String> _generateAudioFilePath() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'voice_recording_$timestamp.aac';
    
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/$fileName';
    } else if (Platform.isIOS) {
      return '/var/mobile/Containers/Data/Application/Documents/$fileName';
    } else {
      return fileName;
    }
  }

  /// Get available locales for speech recognition (currently disabled)
  Future<List<String>> getAvailableLocales() async {
    // NOTE: Speech-to-text functionality temporarily disabled
    debugPrint('Speech-to-text functionality is currently disabled due to compatibility issues');
    return [];
    
    // if (!_isInitialized) {
    //   await initialize();
    // }
    // return _speechToText.locales();
  }

  /// Check if speech recognition is available (currently disabled)
  Future<bool> isAvailable() async {
    // NOTE: Speech-to-text functionality temporarily disabled
    debugPrint('Speech-to-text functionality is currently disabled due to compatibility issues');
    return false;
    
    // return _speechToText.isAvailable;
  }

  /// Cancel current speech recognition (currently disabled)
  Future<void> cancel() async {
    // NOTE: Speech-to-text functionality temporarily disabled
    debugPrint('Speech-to-text functionality is currently disabled due to compatibility issues');
    
    // await _speechToText.cancel();
    // _stopListening();
  }

  /// Dispose resources
  void dispose() {
    // Stop any ongoing operations
    if (_isListening) {
      _isListening = false;
      _listeningStreamController.add(false);
    }
    
    if (_isRecording) {
      stopRecording();
    }
    
    _textStreamController.close();
    _listeningStreamController.close();
    _soundLevelStreamController.close();
  }
}