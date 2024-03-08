import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class SoundTranslationPage extends StatefulWidget {
  @override
  _SoundTranslationPageState createState() => _SoundTranslationPageState();
}

class _SoundTranslationPageState extends State<SoundTranslationPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _path;
  String? _translationResult;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Consider handling the permission denial gracefully.
      throw Exception('Microphone permission not granted');
    }

    // Initialize the recorder.
    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
    // Additional setup can be done here if needed, e.g., setting audio format.
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!_recorder.isRecording) {
      final directory = await getApplicationDocumentsDirectory();
      _path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.wav';

      // Ensure the recorder is initialized and ready before starting.
      await _recorder.startRecorder(
        toFile: _path,
        codec: Codec.pcm16WAV, // Adjust according to the desired format
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (_path != null) {
      _sendFile(_path!);
    }
  }

  Future<void> _sendFile(String path) async {
    Dio dio = Dio();
    try {
      FormData formData = FormData.fromMap({
        "voice_note":
            await MultipartFile.fromFile(path, filename: "voice_note.aac"),
      });

      var response = await dio.post(
        "https://stt.megalogic.id",
        data: formData,
      );

      if (response.statusCode == 200) {
        print("Upload successful");
        final Map<String, dynamic> responseData = response.data;
        final String message = responseData['status']['message'];
        final dynamic data = responseData['data'];
        print(message);
        print(data);
        setState(() {
          _translationResult = data['translation_result'];
        });
        // Optionally, clear the recorded file
      } else {
        print("Failed to upload voice note");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _translateBack() async {
    if (_translationResult != null) {
      Dio dio = Dio();
      try {
        var response = await dio.post(
          "https://stt.megalogic.id",
          data: {
            "text": _translationResult,
            "source": "ar", // Target language of the previous translation
            "target": "id" // Indonesian language
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = response.data;
          final String message = responseData['status']['message'];
          final dynamic data = responseData['data'];
          print(message);
          print(data);
          setState(() {
            _translationResult = data['translation_text'];
          });
        } else {
          print("Failed to translate back");
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translasi Suara'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _toggleRecording,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text(
                _isRecording
                    ? 'Berhenti merekam dan terjemahkan'
                    : 'Mulai merekam',
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            _translationResult != null
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Hasil Translasi:\n$_translationResult',
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _translateBack,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            textStyle: TextStyle(fontSize: 20),
                          ),
                          child: Text(
                            'Terjemahkan Kembali ke Bahasa Indonesia',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}
