// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saveAsPreview = true;
  bool _showPreview = true;
  bool _autoSaveGallery = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saveAsPreview = prefs.getBool('save_as_preview') ?? true;
      _showPreview = prefs.getBool('show_preview') ?? true;
      _autoSaveGallery = prefs.getBool('auto_save_gallery') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          SwitchListTile(
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[700],
            title: const Text('Ön Kamerayı Aynala', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Ön kamerada fotoğrafı ekranda göründüğü gibi kaydeder.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _saveAsPreview,
            onChanged: (bool value) {
              setState(() { _saveAsPreview = value; });
              _saveSetting('save_as_preview', value);
            },
            secondary: const Icon(Icons.flip, color: Colors.white),
          ),
          
          const Divider(color: Colors.white24),

          SwitchListTile(
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[700],
            title: const Text('Çekimden Sonra Önizle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Fotoğraf çekildikten sonra görüntüleme ekranını açar.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _showPreview,
            onChanged: (bool value) {
              setState(() { _showPreview = value; });
              _saveSetting('show_preview', value);
            },
            secondary: const Icon(Icons.preview, color: Colors.white),
          ),

          const Divider(color: Colors.white24),

          SwitchListTile(
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[700],
            title: const Text('Fotoğrafları Otomatik Galeriye Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Çekilen ve efektlenen fotoğraflar film rulosuna otomatik kopyalanır.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _autoSaveGallery, // Yeni değişkeni kullan
            onChanged: (bool value) {
              setState(() { _autoSaveGallery = value; });
              _saveSetting('auto_save_gallery', value); // Yeni anahtarı kaydet
            },
            secondary: const Icon(Icons.save_alt, color: Colors.white),
          ),
          
          const Divider(color: Colors.white24),
          // ------------------------------------------

          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.white),
            title: Text('Sürüm Bilgisi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('v1.0.0 (Geliştirici Sürümü)', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}