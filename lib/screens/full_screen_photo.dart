import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';

class FullScreenPhoto extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;

  const FullScreenPhoto({super.key, required this.photos, required this.initialIndex});

  @override
  State<FullScreenPhoto> createState() => _FullScreenPhotoState();
}

class _FullScreenPhotoState extends State<FullScreenPhoto> {
  late PageController _pageController;
  late List<File> _currentPhotos;
  late int _currentIndex;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentPhotos = List.from(widget.photos);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _checkFavoriteStatus();
  }

  File get _currentPhoto => _currentPhotos[_currentIndex];

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_photos') ?? [];
    setState(() {
      _isFavorite = favorites.contains(_currentPhoto.path);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_photos') ?? [];
    
    setState(() {
      if (_isFavorite) {
        favorites.remove(_currentPhoto.path);
        _isFavorite = false;
      } else {
        favorites.add(_currentPhoto.path);
        _isFavorite = true;
      }
    });
    await prefs.setStringList('favorite_photos', favorites);
  }

  Future<void> _deletePhoto() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Fotoğrafı Sil', style: TextStyle(color: Colors.white)),
          content: const Text('Bu fotoğrafı silmek istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _currentPhoto.delete();
      
      setState(() {
        _currentPhotos.removeAt(_currentIndex);
        if (_currentIndex >= _currentPhotos.length) {
          _currentIndex = _currentPhotos.length - 1;
        }
      });

      if (_currentPhotos.isEmpty) {
        if (mounted) Navigator.pop(context, true); 
      } else {
        _checkFavoriteStatus();
      }
    }
  }

  Future<void> _saveToDeviceGallery() async {
    try {
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(_currentPhoto.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Film rulosuna kaydedildi! 📸'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _sharePhoto() {
    Share.shareXFiles([XFile(_currentPhoto.path)], text: 'Bu harika fotoğrafı incele!');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPhotos.isEmpty) return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _currentPhotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _checkFavoriteStatus();
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  child: Image.file(_currentPhotos[index]),
                ),
              );
            },
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white, size: 30),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white, size: 30),
                    onPressed: _saveToDeviceGallery,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 30),
                    onPressed: _sharePhoto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                    onPressed: _deletePhoto,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}