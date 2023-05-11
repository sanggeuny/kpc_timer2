import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TimerStatus {
  running, //작업(공부)중
  paused, //일시정지중
  stopped, // 정지
  resting, // 휴식
}

class TimerScreen extends StatefulWidget {
  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const WORK_TIME = 25;
  static const REST_TIME = 5;

  /// SharedPreference 객체 선언
  late SharedPreferences prefs;

  //앱에서 사용할 상태(State) 선언
  late int _timer; //현재 타이머의 시간
  late int _pomodoroCount; //달성한 뽀모도로 개수
  late TimerStatus _timerStatus;

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _pomodoroCount = prefs.getInt('pomodoro') ?? 0; // null 일 경우 0
  }

  @override
  void initState() {
    super.initState();
    _timer = WORK_TIME;
    //_pomodoroCount = 0;
    loadPrefs();
    _timerStatus = TimerStatus.stopped;
  }

  /// [1] run: 작업을 시작하는 이벤트
  void run() {
    setState(() {
      _timerStatus = TimerStatus.running;
      runTimer();
    });
  }

  /// [2] rest: 휴식 이벤트
  void rest() {
    setState(() {
      _timerStatus = TimerStatus.resting;
      _timer = REST_TIME;
    });
  }

  /// [3] pause: 일시정지 이벤트
  void pause() {
    setState(() {
      _timerStatus = TimerStatus.paused;
    });
  }

  /// [4] resume: 계속하기 이벤트
  void resume() {
    run();
  }

  /// [5] stop: 포기하기 이벤트
  void stop() {
    setState(() {
      _timerStatus = TimerStatus.stopped;
      _timer = WORK_TIME;
    });
  }

  /// [*] Timer 기능 구현
  void runTimer() async {
    Timer.periodic(Duration(seconds: 1), (t) {
      switch (_timerStatus) {
        case TimerStatus.paused:
          t.cancel();
          break;
        case TimerStatus.stopped:
          t.cancel();
          break;
        case TimerStatus.running:
          if (_timer <= 0) {
            rest();
          } else {
            setState(() {
              _timer -= 1;
            });
          }
          break;
        case TimerStatus.resting:
          if (_timer <= 0) {
            setState(() {
              _pomodoroCount += 1;
              prefs.setInt('pomodoro', _pomodoroCount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('오늘 $_pomodoroCount개의 뽀모도로를 달성했습니다!'),
                ),
              );
            });
            t.cancel();
            stop();
          } else {
            setState(() {
              _timer -= 1;
            });
          }
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> runningButtons = [
      ElevatedButton(
        onPressed: _timerStatus == TimerStatus.paused ? resume : pause,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        child: Text(
          _timerStatus == TimerStatus.paused ? '계속하기' : '일시정지',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      Padding(padding: EdgeInsets.all(20)),
      ElevatedButton(
        onPressed: stop,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        child: Text(
          '포기하기',
          style: TextStyle(fontSize: 16),
        ),
      )
    ];
    List<Widget> stoppedButtons = [
      ElevatedButton(
        onPressed: run,
        style: ElevatedButton.styleFrom(
            backgroundColor: _timerStatus == TimerStatus.resting
                ? Colors.green
                : Colors.blue),
        child: Text(
          '시작하기',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      )
    ];
    return Scaffold(
      appBar: AppBar(title: Text('뽀모도로 타이머')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ///타이머 위젯
          Container(
            height: 500,
            width: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerStatus == TimerStatus.resting
                  ? Colors.green
                  : Colors.blue,
            ),
            child: Center(
              child: Text(
                //_timer.toString(),
                (_timer ~/ 60).toString().padLeft(2, '0') +
                    '분' +
                    (_timer % 60).toString().padLeft(2, '0') +
                    '초',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _timerStatus == TimerStatus.resting // 휴식중이냐?
                ? const [] //아예 버튼 없이
                : _timerStatus == TimerStatus.stopped // 정지(초기) 상태냐?
                    ? stoppedButtons // 정지된 버튼
                    : runningButtons, // 동작 중 버튼
          ),
        ],
      ),
    );
  }
}
