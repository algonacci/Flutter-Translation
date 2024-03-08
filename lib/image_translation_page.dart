import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class ImageTranslationPage extends StatefulWidget {
  const ImageTranslationPage({super.key});

  @override
  _ImageTranslationPageState createState() => _ImageTranslationPageState();
}

class _ImageTranslationPageState extends State<ImageTranslationPage> {
  File? _image;
  String _recognizedText = '';
  String _translatedText = '';
  bool _isLoading = false;

  final picker = ImagePicker();

  Future<void> getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final filePath = pickedFile.path;
      final fileSize = await File(filePath).length();
      print("Image file size: $fileSize bytes");

      final targetPath = p.join(p.dirname(filePath),
          '${p.basenameWithoutExtension(filePath)}-compressed.jpg');

      final compressedImageFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        targetPath,
        quality: 70, // Adjust the quality as needed
      );

      setState(() {
        if (compressedImageFile != null) {
          _image = File(compressedImageFile.path);
          final compressedFileSize = _image?.length();
          print(compressedFileSize.toString());
          _recognizedText = ''; // Reset recognized text
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      print('Please select an image first.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Dio dio = Dio();
      String url = 'https://ocr.megalogic.id';

      FormData formData = FormData.fromMap({
        'image':
            await MultipartFile.fromFile(_image!.path, filename: 'image.jpg'),
      });

      var response = await dio.post(url, data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _recognizedText = data['data']['recognized_text'];
          _translatedText = data['data']['translated_text'];
        });
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Translasi Gambar'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.photo_library),
                          title: Text('Pilih dari galeri'),
                          onTap: () {
                            getImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_camera),
                          title: Text('Ambil gambar'),
                          onTap: () {
                            getImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: Text('Pilih gambar'),
              ),
              if (_image != null) SizedBox(height: 20),
              if (_image != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Unggah gambar'),
              ),
              SizedBox(height: 20),
              Text(
                'Hasil pembacaan teks dan translasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : _recognizedText.isNotEmpty
                        ? Column(
                            children: [
                              Text(
                                _recognizedText,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _translatedText,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No text recognized',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
