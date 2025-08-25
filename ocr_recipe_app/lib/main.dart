import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Recipe App',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String? _ocrText;
  String? _ocrId;
  String? _title;
  bool _busy = false;

  // Kohanda vastavalt: Android emulaator → 10.0.2.2, iOS sim → localhost
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<void> _pickImage() async {
    final img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 95);
    if (img != null) {
      setState(() {
        _image = img;
        _ocrText = null;
        _ocrId = null;
        _title = null;
      });
    }
  }

  Future<void> _runOcr() async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      final uri = Uri.parse('$baseUrl/ocr');
      final req = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', _image!.path));
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _ocrText = data['text'] as String?;
          _ocrId = data['id'] as String?;
          _title = data['title'] as String?;
        });
      } else {
        _showSnack('OCR ebaõnnestus: ${resp.statusCode}');
      }
    } catch (e) {
      _showSnack('Viga: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _generateTechCard() async {
    final id = _ocrId;
    final text = _ocrText;
    if (id == null && (text == null || text.isEmpty)) {
      _showSnack('Pole OCR-i tulemust');
      return;
    }
    setState(() => _busy = true);
    try {
      final uri = Uri.parse('$baseUrl/generate-tech-card');
      final payload = id != null ? {'id': id} : {'text': text};
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final outId = data['id'] as String;
        await _downloadTechCard(outId);
      } else {
        _showSnack('Kaardi genereerimine ebaõnnestus: ${resp.statusCode}');
      }
    } catch (e) {
      _showSnack('Viga: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _downloadTechCard(String id) async {
    final uri = Uri.parse('$baseUrl/download-tech-card/$id');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final bytes = resp.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/tech_card_$id.xlsx');
      await f.writeAsBytes(bytes);
      _showSnack('Salvestatud: ${f.path}');
      await OpenFilex.open(f.path);
    } else {
      _showSnack('Allalaadimine ebaõnnestus: ${resp.statusCode}');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Recipe App')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _busy ? null : _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Pildista retsept'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _busy ? null : _runOcr,
                icon: const Icon(Icons.text_snippet),
                label: const Text('Tee OCR'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _busy ? null : _generateTechCard,
                icon: const Icon(Icons.table_view),
                label: const Text('Genereeri tehnoloogiline kaart'),
              ),
              const SizedBox(height: 16),
              if (_image != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilt: ${_image!.name}'),
                      const SizedBox(height: 8),
                      if (_title != null) Text('Pealkiri: $_title'),
                      const SizedBox(height: 8),
                      const Text('OCR tekst:'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(_ocrText ?? '—'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
