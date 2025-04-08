import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path; // Importing the path package
import 'package:flutter/material.dart';

Future<File?> copyImageToDocumentsDirectory(File imageFile) async {
  try {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    final fileExtension = path.extension(imageFile.path);  // e.g., .jpg, .png
    final newImagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}$fileExtension';
    final newImageFile = await imageFile.copy(newImagePath);
    print('Image copied to: ${newImageFile.path}');
    return newImageFile;
  } catch (e) {
    print('Error copying image: $e');
    return null;
  }
}

class ImageCopyExample extends StatefulWidget {
  @override
  _ImageCopyExampleState createState() => _ImageCopyExampleState();
}

class _ImageCopyExampleState extends State<ImageCopyExample> {
  File? _imageFile;

  // Pick an image from the gallery
  Future<void> pickAndCopyImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Use ImageSource.camera for camera
    if (pickedFile == null) {
      print('No image selected.');
      return;
    }
    
    File imageFile = File(pickedFile.path);
    File? copiedImage = await copyImageToDocumentsDirectory(imageFile);

    if (copiedImage != null) {
      setState(() {
        _imageFile = copiedImage;
      });
    } else {
      print('Failed to copy image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Copy Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickAndCopyImage,
              child: Text('Pick and Copy Image'),
            ),
            if (_imageFile != null) ...[
              SizedBox(height: 20),
              Image.file(_imageFile!),
              SizedBox(height: 20),
              Text('Copied Image Path: ${_imageFile!.path}'),
            ]
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ImageCopyExample(),
  ));
}
