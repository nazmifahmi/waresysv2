import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
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

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _stopListening();
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
      );

      if (!_isInitialized) {
        debugPrint('Failed to initialize speech recognition');
        return false;
      }

      debugPrint('Voice service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing voice service: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<bool> startListening({
    String localeId = 'id_ID', // Indonesian by default
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      debugPrint('Already listening');
      return true;
    }

    try {
      _recognizedText = '';
      _isListening = true;
      _listeningStreamController.add(true);

      final available = await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _textStreamController.add(_recognizedText);
          
          if (result.finalResult) {
            _stopListening();
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId,
        onSoundLevelChange: (level) {
          _soundLevelStreamController.add(level);
        },
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      if (!available) {
        _stopListening();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _stopListening();
      return false;
    }
  }

  /// Stop listening for speech
  Future<void> stopListening() async {
    await _stopListening();
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }

    _isListening = false;
    _listeningStreamController.add(false);
    _soundLevelStreamController.add(0.0);
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

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    return _speechToText.isAvailable;
  }

  /// Cancel current speech recognition
  Future<void> cancel() async {
    await _speechToText.cancel();
    _stopListening();
  }

  /// Dispose resources
  void dispose() {
    _stopListening();
    if (_isRecording) {
      stopRecording();
    }
    _textStreamController.close();
    _listeningStreamController.close();
    _soundLevelStreamController.close();
  }
}