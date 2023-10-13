import 'package:canmoya/box_widget.dart';
import 'package:canmoya/camera_Setting.dart';
import 'package:canmoya/recognition.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_view.dart';
import 'package:flutter_tts/flutter_tts.dart';


class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Results to draw bounding boxes
  List<Recognition>? results;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // 카메라와 마이크 권한 요청
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    // 권한 상태 확인
    print(statuses[Permission.camera]);
    print(statuses[Permission.microphone]);
  }

  /// Realtime stats
  int totalElapsedTime = 0;

  final FlutterTts flutterTts = FlutterTts();

  /// Scaffold Key
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("ko-KR");  // 한국어로 설정
    await flutterTts.speak(text);
  }

  String? previousLabel;  // 이전에 감지된 객체명을 저장할 변수

  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
      if (results.isNotEmpty && results[0].score! > 0.75) {
        // 첫 번째 객체의 예측 확률이 75% 이상이고, 이전에 감지된 객체와 현재 감지된 객체가 다른 경우
        if (previousLabel != results[0].label) {
          speak("${results[0].label}");  // 첫 번째 객체의 이름을 읽는다
          previousLabel = results[0].label;  // 현재 감지된 객체명을 previousLabel에 저장
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '캔모야 프로젝트',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
        ),
      ),
      body: Stack(
        children: [
          CameraView(resultsCallback, updateElapsedTimeCallback),
          boundingBoxes(results),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  resultsList(results),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        statsRow('이미지 추론 시간:', '$totalElapsedTime ms'),
                        statsRow('이미지 크기',
                            '${CameraSettings.inputImageSize?.width} X ${CameraSettings.inputImageSize?.height}'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns Stack of bounding boxes
  Widget boundingBoxes(List<Recognition>? results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
        result: e,
      ))
          .toList(),
    );
  }

  Widget resultsList(List<Recognition>? results) {
    if (results == null) {
      return Container();
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return Container(
            height: 20,
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(index + 1)}. 객체명: ${results[index].label}',
                      style: TextStyle(fontSize: 13)),
                  Text(
                      '예측확률: ${(results[index].score! * 100).toStringAsFixed(1)} %',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // /// Callback to get inference results from [CameraView]
  // void resultsCallback(List<Recognition> results) {
  //   setState(() {
  //     this.results = results;
  //   });
  // }

  void updateElapsedTimeCallback(int elapsedTime) {
    setState(() {
      totalElapsedTime = elapsedTime;
    });
  }
}

/// Row for one Stats field
Padding statsRow(left, right) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(left), Text(right)],
    ),
  );
}
