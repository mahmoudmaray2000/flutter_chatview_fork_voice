import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart'; // ADD THIS IMPORT
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class VoiceRecorderButton extends StatefulWidget {
  @override
  _VoiceRecorderButtonState createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLocked = false;
  bool _isCanceled = false;
  bool _isPlaying = false;

  Offset _startPosition = Offset.zero;
  String? _filePath; // This holds the path of the *finished* recording
  double _waveformHeight = 2.0;
  Duration _recordDuration = Duration.zero;
  Timer? _recordingTimer;
  Timer? _waveformTimer;
  final Random _random = Random();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
      if (playerState.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
        _audioPlayer.seek(Duration.zero);
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.red)
        .animate(_animationController);
  }

  // --- FIXED: Generate a new path for each recording ---
  Future<String> _getNewRecordingPath() async {
    final directory =
        await getTemporaryDirectory(); // Use temp directory for recordings
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$timestamp.aac';
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _stopRecording(cancel: true);
      }
      await _audioPlayer.stop();

      // Generate a unique file path for this new recording session
      String newFilePath = await _getNewRecordingPath();

      // Start the recorder with the required path parameter
      await _audioRecorder.start(
        const RecordConfig(),
        path: newFilePath, // Use the newly generated path
      );

      setState(() {
        _isRecording = true;
        _isCanceled = false;
        _isLocked = false;
        _recordDuration = Duration.zero;
        _isPlaying = false;
        // Don't set _filePath yet, only if the recording is successful and not canceled
      });

      _animationController.forward();
      _startTimer();

      _waveformTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        setState(() {
          _waveformHeight = 5 + _random.nextInt(15).toDouble();
        });
      });
    } catch (e) {
      print("Failed to start recording: $e");
      // Consider showing an error message to the user here
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration += Duration(seconds: 1);
      });
    });
  }

  // --- FIXED: Use the path returned by stop() ---
  Future<void> _stopRecording({bool cancel = false}) async {
    _waveformTimer?.cancel();
    _recordingTimer?.cancel();

    // Stop the recording and get the path of the file that was being recorded
    String? recordedFilePath = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _waveformHeight = 2.0;
    });

    _animationController.reverse();

    if (cancel) {
      // Delete the file we were just recording to
      if (recordedFilePath != null) {
        final file = File(recordedFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      // Clear the stored path since we canceled
      setState(() {
        _filePath = null;
      });
    } else {
      // Save the path of the successfully completed recording
      setState(() {
        _filePath = recordedFilePath; // This is the path we started with
      });
      // Preload the new audio file for playback
      if (_filePath != null) {
        await _audioPlayer.setFilePath(_filePath!);
      }
    }
  }

  Future<void> _playRecording() async {
    if (_filePath == null) return;
    try {
      await _audioPlayer.play();
    } catch (e) {
      print("Playback failed: $e");
      // Try to reset the audio source if play fails
      await _audioPlayer.setFilePath(_filePath!);
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
  }

  // ... build methods ( _buildLockedUI, _buildRecordingUI ) remain the same ...
  @override
  Widget build(BuildContext context) {
    return _isLocked ? _buildLockedUI() : _buildRecordingUI();
  }

  Widget _buildLockedUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 30,
          width: 100,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 100),
                width: 6,
                height: _waveformHeight + (index.isEven ? 2 : -2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                print("Audio Sent: $_filePath");
                setState(() => _isLocked = false);
              },
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.stop : Icons.play_arrow,
                color: Colors.green,
              ),
              onPressed: _isPlaying ? _stopPlayback : _playRecording,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await _stopRecording(cancel: true);
                if (mounted) {
                  setState(() {
                    _isLocked = false;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    String formattedDuration =
        "${_recordDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
        "${_recordDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onLongPressStart: (details) {
            _startRecording();
            _startPosition = details.globalPosition;
          },
          onLongPressMoveUpdate: (details) {
            double dx = details.globalPosition.dx - _startPosition.dx;
            double dy = details.globalPosition.dy - _startPosition.dy;

            if (dx < -100 && !_isCanceled) {
              setState(() => _isCanceled = true);
              _stopRecording(cancel: true);
            }

            if (dy < -100 && !_isLocked) {
              setState(() => _isLocked = true);
            }
          },
          onLongPressEnd: (details) {
            if (!_isLocked && !_isCanceled) {
              _stopRecording();
            }
          },
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colorAnimation.value,
                  ),
                  child: Icon(
                    _isLocked ? Icons.lock : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        if (_isRecording && !_isCanceled) ...[
          Text("← Slide to Cancel",
              style: TextStyle(color: Colors.red, fontSize: 14)),
          Text(
            formattedDuration,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ],
    );
  }

  // ... dispose() remains the same ...
  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _animationController.dispose();
    _recordingTimer?.cancel();
    _waveformTimer?.cancel();
    super.dispose();
  }
}
