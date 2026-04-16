import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'full_screen_photo.dart';
import 'package:gal/gal.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File> _photos = [];
  
  final Set<String> _selectedPaths = {};
  bool get _isSelectionMode => _selectedPaths.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    
    List<File> imageFiles = files
        .where((file) => file.path.endsWith('.jpg'))
        .map((file) => File(file.path))
        .toList();

    imageFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() {
      _photos = imageFiles;
    });
  }

  Future<void> _deleteSelected() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('${_selectedPaths.length} Fotoğrafı Sil', style: const TextStyle(color: Colors.white)),
          content: const Text('Seçili fotoğrafları silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal', style: TextStyle(color: Colors.white))),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirm == true) {
      for (String path in _selectedPaths) {
        await File(path).delete();
      }
      setState(() {
        _selectedPaths.clear();
      });
      _loadPhotos();
    }
  }

  void _shareSelected() {
    List<XFile> filesToShare = _selectedPaths.map((path) => XFile(path)).toList();
    Share.shareXFiles(filesToShare, text: 'Bu harika fotoğrafları incele!');
    setState(() {
      _selectedPaths.clear();
    });
  }

  Future<void> _favoriteSelected() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_photos') ?? [];
    
    for (String path in _selectedPaths) {
      if (!favorites.contains(path)) {
        favorites.add(path);
      }
    }
    await prefs.setStringList('favorite_photos', favorites);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçili fotoğraflar favorilere eklendi! ❤️'), backgroundColor: Colors.green),
      );
    }
    setState(() {
      _selectedPaths.clear();
    });
  }

  Future<void> _saveSelectedToGallery() async {
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
        hasAccess = await Gal.hasAccess();
        if (!hasAccess) return;
      }

      for (String imagePath in _selectedPaths) {
        await Gal.putImage(imagePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPaths.length} fotoğraf başarıyla film rulosuna kaydedildi! 📥'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _selectedPaths.clear();
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydedilirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.grey[900],
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() { _selectedPaths.clear(); });
                },
              ),
              title: Text('${_selectedPaths.length} seçildi', style: const TextStyle(color: Colors.white)),
              actions: [
                IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: _favoriteSelected),
                IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareSelected),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white), onPressed: _deleteSelected),
                IconButton(icon: const Icon(Icons.download, color: Colors.white, size: 30), onPressed: _saveSelectedToGallery,),
              ],
            )
          : AppBar(
              title: const Text('Galerim', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            
      body: _photos.isEmpty
          ? const Center(child: Text('Henüz fotoğraf yok.', style: TextStyle(color: Colors.white)))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final file = _photos[index];
                final isSelected = _selectedPaths.contains(file.path);

                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _selectedPaths.add(file.path);
                    });
                  },
                  onTap: () async {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) _selectedPaths.remove(file.path);
                        else _selectedPaths.add(file.path);
                      });
                    } else {
                      final isChanged = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenPhoto(
                            photos: _photos,
                            initialIndex: index,
                          ),
                        ),
                      );
                      if (isChanged == true) {
                        _loadPhotos();
                      }
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Orijinal Fotoğraf
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                      
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 3),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle, color: Colors.blue, size: 32),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}