import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _selectedFilePath;
  String _outputMessage = "Waiting for output...";
  String outputFilePath = "/data/data/com.example.cpp_runner/files/output.txt";
  Timer? _timer;

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path!.endsWith('.so')) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _outputMessage = "File selected successfully!";
      });
    } else {
      setState(() {
        _outputMessage = "Invalid file type. Please select a .so file.";
      });
    }
  }

  Future<void> _executeFile() async {
    if (_selectedFilePath == null) {
      setState(() {
        _outputMessage = "No file selected";
      });
      return;
    }

    try {
      final lib = ffi.DynamicLibrary.open(_selectedFilePath!);
      final execute = lib.lookupFunction<ffi.Void Function(), void Function()>('generate_random_numbers');
      execute();


      setState(() {
        _outputMessage = "Execution started. Reading output file...";
      });
      
      _startReadingLoop();
    } catch (e) {
      setState(() {
        _outputMessage = "Error executing file: $e";
      });
    }
  }

  void _startReadingLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _readOutputFile();
    });
  }

  Future<void> _readOutputFile() async {
    try {
      File outputFile = File(outputFilePath);
      if (await outputFile.exists()) {
        String output = await outputFile.readAsString();
        setState(() {
          _outputMessage = output;
        });
      } else {
        setState(() {
          _outputMessage = "Execution complete, but no output file found.";
        });
      }
    } catch (e) {
      setState(() {
        _outputMessage = "Error reading output file: $e";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("FFI Random Number Generator")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickFile,
                child: Text("Pick .so File"),
              ),
              SizedBox(height: 10),
              Text(_selectedFilePath ?? "No file selected"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _executeFile,
                child: Text("Execute File"),
              ),
              SizedBox(height: 20),
              Text(_outputMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}