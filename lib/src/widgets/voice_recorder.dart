import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

class VoiceRecorderButton extends StatefulWidget {
  @override
  _VoiceRecorderButtonState createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool isRecording = false;
  bool isLocked = false;
  bool isCanceled = false;
  bool isPlaying = false;

  Offset startPosition = Offset.zero;
  String? filePath;
  double waveformHeight = 2.0;
  int recordDuration = 0;
  Timer? _timer;
  Timer? _waveformTimer;
  Random random = Random();

  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _player.openPlayer();

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

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    filePath = '${directory.path}/recording.aac';
    await _recorder.startRecorder(toFile: filePath);

    setState(() {
      isRecording = true;
      isCanceled = false;
      isLocked = false;
      recordDuration = 0;
    });

    _animationController.forward(); // Start animation

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => recordDuration++);
    });

    _waveformTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        waveformHeight = 5 + random.nextInt(15).toDouble();
      });
    });
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    await _recorder.stopRecorder();
    _waveformTimer?.cancel();
    _timer?.cancel();

    setState(() {
      isRecording = false;
      waveformHeight = 2.0;
    });

    _animationController.reverse(); // Stop animation

    if (cancel && filePath != null) {
      File(filePath!).delete();
      setState(() => filePath = null);
    }
  }

  Future<void> _playRecording() async {
    if (filePath != null && File(filePath!).existsSync()) {
      setState(() => isPlaying = true);
      await _player.startPlayer(fromURI: filePath, whenFinished: () {
        setState(() => isPlaying = false);
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _player.stopPlayer();
    setState(() => isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return isLocked
        ? Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform Animation
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
                height: waveformHeight + (index.isEven ? 2 : -2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 5),
        // Row with Send, Play, Delete
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                print("Audio Sent: $filePath");
                setState(() => isLocked = false);
              },
            ),
            IconButton(
              icon: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.green),
              onPressed: isPlaying ? _stopPlayback : _playRecording,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _stopRecording(cancel: true);
                setState(() => isLocked = false);
              },
            ),
          ],
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onLongPressStart: (details) {
            _startRecording();
            startPosition = details.globalPosition;
          },
          onLongPressMoveUpdate: (details) {
            double dx = details.globalPosition.dx - startPosition.dx;
            double dy = details.globalPosition.dy - startPosition.dy;

            if (dx < -100) {
              setState(() => isCanceled = true);
              _stopRecording(cancel: true);
            }

            if (dy < -100) {
              setState(() => isLocked = true);
            }
          },
          onLongPressEnd: (details) {
            if (!isLocked && !isCanceled) {
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
                    isLocked ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
        if (isRecording)
          Text("← Slide to Cancel",
              style: TextStyle(color: Colors.red, fontSize: 14)),
        if (isRecording)
          Text(
            "${(recordDuration ~/ 60).toString().padLeft(2, '0')}:${(recordDuration % 60).toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _animationController.dispose();
    _timer?.cancel();
    _waveformTimer?.cancel();
    super.dispose();
  }
}
