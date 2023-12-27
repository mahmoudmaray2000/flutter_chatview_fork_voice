import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordButton extends StatefulWidget {
  const RecordButton({
    Key? key,
    required this.controller,
    required this.onSubmitVoice,
    required this.backGroundColor,
  }) : super(key: key);

  final AnimationController controller;
  final Function(String path) onSubmitVoice;
  final Color backGroundColor;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  static const double size = 55;

  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  Record? record;

  bool isLocked = false;
  bool showLottie = false;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * Globals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + Globals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    record != null ? record!.dispose() : null;
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        lockSlider(),
        cancelSlider(),
        audioButton(
          color: widget.backGroundColor,
          onSubmitVoice: widget.onSubmitVoice,
        ),
        if (isLocked) timerLocked(onSubmitVoice: widget.onSubmitVoice),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned(
      bottom: -lockerAnimation.value,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: isRecording==true? Colors.white:Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: Column(
                children: const [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned(
      right: -timerAnimation.value,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              showLottie ? const LottieAnimation() : Text(recordDuration),
              const SizedBox(width: size),
              FlowShader(
                child: Row(
                  children: const [
                    Icon(Icons.keyboard_arrow_left),
                    Text("Slide to cancel")
                  ],
                ),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
              const SizedBox(width: size),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked({Function(String path)? onSubmitVoice}) {
    return Positioned(
      right: 0,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Globals.borderRadius),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // mainAxisSize: MainAxisSize.max,
            children: [
              //Todo: edit this
              // GestureDetector(
              //   behavior: HitTestBehavior.translucent,
              //   onTap: () async {
              //     widget.controller.reverse();
              //     print("pressss");
              //     Vibrate.feedback(FeedbackType.success);
              //     timer?.cancel();
              //     timer = null;
              //     startTime = null;
              //     recordDuration = "00:00";
              //
              //     var filePath = await Record().stop();
              //     AudioState.files.add(filePath!);
              //     Globals.audioListKey.currentState!
              //         .insertItem(AudioState.files.length - 1);
              //     debugPrint(filePath);
              //     setState(() {
              //       isLocked = false;
              //     });
              //
              //     // Timer(const Duration(milliseconds: 1440), () async {
              //     //   widget.controller.reverse();
              //     //   debugPrint("Cancelled recording");
              //     //   var filePath = await record.stop();
              //     //   debugPrint(filePath);
              //     //   File(filePath!).delete();
              //     //   debugPrint("Deleted $filePath");
              //     //   setState(() {
              //     //     showLottie = false;
              //     //     isLocked=false;
              //     //
              //     //   });
              //     // });
              //   },
              //   child: const Center(
              //     child: Icon(
              //       Icons.delete,
              //       color: Colors.red,
              //     ),
              //   ),
              // ),
              Text(recordDuration),
              FlowShader(
                child: const Text("Tap lock to send"),
                duration: const Duration(seconds: 3),
                flowColors: const [Colors.white, Colors.grey],
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  widget.controller.reverse();

                  Vibrate.feedback(FeedbackType.success);

                  timer?.cancel();
                  timer = null;
                  startTime = null;
                  recordDuration = "00:00";

                  var filePath = await Record().stop();
                  AudioState.files.add(filePath!);
                  debugPrint(filePath);
                  setState(() {
                    isLocked = false;
                  });
                  onSubmitVoice!(filePath);
                },
                child: const Center(
                  child: Icon(
                    Icons.send,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget audioButton(
      {Function(String path)? onSubmitVoice, required Color color}) {
    return GestureDetector(
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          child: Icon(
            Icons.mic,
            color: Colors.white,
          ),
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
      onLongPressDown: (_) {
        debugPrint("onLongPressDown");
        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        debugPrint("onLongPressEnd");

        if (isCancelled(details.localPosition, context)) {
          Vibrate.feedback(FeedbackType.heavy);
          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();
            debugPrint("Cancelled recording");
            var filePath = await record!.stop();
            debugPrint(filePath);
            File(filePath!).delete();
            debugPrint("Deleted $filePath");
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();

          Vibrate.feedback(FeedbackType.heavy);
          debugPrint("Locked recording");
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        } else {
          widget.controller.reverse();

          Vibrate.feedback(FeedbackType.success);

          timer?.cancel();
          timer = null;
          startTime = null;
          recordDuration = "00:00";

          var filePath = await Record().stop();
          AudioState.files.add(filePath!);
          // Globals.audioListKey.currentState!
          //     .insertItem(AudioState.files.length - 1);
          debugPrint(filePath);
          onSubmitVoice!(filePath);
        }
        setState(() {
          isRecording=false;
        });
      },
      onLongPressCancel: () {
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onLongPress: () async {
        debugPrint("onLongPress");
        final documentPath =
            "${(await getApplicationDocumentsDirectory()).path}/";

        Vibrate.feedback(FeedbackType.success);
        if (await Record().hasPermission()) {
          record = Record();
          await record!.start(
            path:
                "${documentPath}audio_${DateTime.now().millisecondsSinceEpoch}.m4a",
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            samplingRate: 44100,
          );
          setState(() {
            isRecording = true;
          });

          startTime = DateTime.now();
          timer = Timer.periodic(const Duration(seconds: 1), (_) {
            final minDur = DateTime.now().difference(startTime!).inMinutes;
            final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
            String min = minDur < 10 ? "0$minDur" : minDur.toString();
            String sec = secDur < 10 ? "0$secDur" : secDur.toString();
            setState(() {
              recordDuration = "$min:$sec";
            });
          });
        }
      },
    );
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}

class Globals {
  Globals._();

  static init() async {
    documentPath = "${(await getApplicationDocumentsDirectory()).path}/";
  }

  static const double borderRadius = 27;
  static const double defaultPadding = 8;
  static String documentPath = '';
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}

class AudioState {
  AudioState._();

  static List<String> files = [];
}

class FlowShader extends StatefulWidget {
  const FlowShader({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.direction = Axis.horizontal,
    this.flowColors = const <Color>[Colors.white, Colors.black],
  })  : assert(flowColors.length == 2),
        super(key: key);

  final Widget child;
  final Axis direction;
  final Duration duration;
  final List<Color> flowColors;

  @override
  _FlowShaderState createState() => _FlowShaderState();
}

class _FlowShaderState extends State<FlowShader>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animation1;
  late Animation animation2;
  late Animation animation3;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final TweenSequenceItem seqbw = TweenSequenceItem(
      tween: ColorTween(
        begin: widget.flowColors.last,
        end: widget.flowColors.first,
      ),
      weight: 1,
    );
    final TweenSequenceItem seqwb = TweenSequenceItem(
      tween: ColorTween(
        begin: widget.flowColors.first,
        end: widget.flowColors.last,
      ),
      weight: 1,
    );
    animation1 = TweenSequence([seqbw, seqwb]).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.45, curve: Curves.linear),
      ),
    );
    animation2 = TweenSequence([seqbw, seqwb]).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.15, 0.75, curve: Curves.linear),
      ),
    );
    animation3 = TweenSequence([seqbw, seqwb]).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.45, 1, curve: Curves.linear),
      ),
    );
    controller.repeat();
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          colors: [
            animation3.value,
            animation2.value,
            animation1.value,
          ],
          begin: widget.direction == Axis.horizontal
              ? Alignment.centerLeft
              : Alignment.topCenter,
          end: widget.direction == Axis.horizontal
              ? Alignment.centerRight
              : Alignment.bottomCenter,
        ).createShader(rect);
      },
      child: widget.child,
    );
  }
}

class LottieAnimation extends StatefulWidget {
  const LottieAnimation({Key? key}) : super(key: key);

  @override
  State<LottieAnimation> createState() => _LottieAnimationState();
}

class _LottieAnimationState extends State<LottieAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Lottie.asset(
        'packages/chatview/assets/json/dustbin.json',
        controller: controller,
        onLoaded: (composition) {
          controller
            ..duration = composition.duration
            ..forward();
          debugPrint("Lottie Duration: ${composition.duration}");
        },
        height: 40,
        width: 40,
      ),
    );
  }
}
