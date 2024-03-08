import 'package:flutter/material.dart';
import 'package:flutter_translation/components/button.dart';
import 'package:flutter_translation/image_translation_page.dart';
import 'package:flutter_translation/sound_translation_page.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aplikasi Translasi',
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                Get.to(() => SoundTranslationPage());
              },
              child: Button(
                text: 'Translasi Suara',
                icon: Icons.voice_chat,
              ),
            ),
            InkWell(
              onTap: () {
                Get.to(() => ImageTranslationPage());
              },
              child: Button(
                text: 'Translasi Gambar',
                icon: Icons.image,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
