import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../models/ayet_model.dart';
import '../providers/kuran_provider.dart';
import '../models/surah_model.dart';
import '../widgets/ayet_item.dart';

class InteractiveMushafEkrani extends StatefulWidget {
  final SurahModel surahModel;

  const InteractiveMushafEkrani({super.key, required this.surahModel});

  @override
  _InteractiveMushafEkraniState createState() => _InteractiveMushafEkraniState();
}

class _InteractiveMushafEkraniState extends State<InteractiveMushafEkrani> {
  List<AyetModel> _ayetler = [];
  bool _yukleniyor = true;
  String _hata = '';
  late PageController _pageController;
  int _aktifAyetIndex = 0;
  bool _sesOynatiliyor = false;
  int? _seciliAyetIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _sureviYukle();
    Provider.of<KuranProvider>(context, listen: false).loadYerIsaretleri();
  }

  /// Sureyi ve ayetlerini yükle
  Future<void> _sureviYukle() async {
    try {
      setState(() {
        _yukleniyor = true;
        _hata = '';
      });

      final provider = Provider.of<KuranProvider>(context, listen: false);
      final ayetler = await provider.loadSurahDetails(widget.surahModel.number);

      setState(() {
        _ayetler = ayetler;
        _yukleniyor = false;
      });

      // Son okunan pozisyonu kontrol et
      _checkLastReadPosition();

    } catch (e) {
      setState(() {
        _hata = 'Sure yüklenirken hata: ${e.toString()}';
        _yukleniyor = false;
      });
    }
  }

  /// Son okunan pozisyonu kontrol et ve o konuma git
  Future<void> _checkLastReadPosition() async {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final lastPosition = await provider.getLastReadPosition();

    if (lastPosition != null &&
        lastPosition['surahNumber'] == widget.surahModel.number) {
      final ayahNumber = lastPosition['ayahNumber']!;
      final index = _ayetler.indexWhere((ayet) => ayet.number == ayahNumber);

      if (index != -1) {
        setState(() {
          _aktifAyetIndex = index;
        });

        // Biraz gecikme ile pozisyona git
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && _pageController.hasClients) {
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  /// Ayet sesini oynat
  Future<void> _playAyetAudio(AyetModel ayet) async {
    try {
      // Eğer aynı ses çalınıyorsa durdur
      if (_isPlaying && _currentAudioUrl == ayet.audioUrl) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
        });
        return;
      }

      // Önceki sesi durdur
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // Çalışan audio URL'sini bul
      String? workingUrl = ayet.audioUrl;

      // Ana URL çalışmıyorsa alternatif URL'leri dene
      bool isMainUrlWorking = await _testAudioUrl(ayet.audioUrl);
      if (!isMainUrlWorking) {
        workingUrl = await _findWorkingAudioUrl(ayet);
      }

      if (workingUrl == null) {
        throw Exception('Hiçbir ses kaynağı bulunamadı');
      }

      // Yeni sesi başlat
      await _audioPlayer.play(UrlSource(workingUrl));
      setState(() {
        _isPlaying = true;
        _currentAudioUrl = workingUrl;
      });

      // Ses bittiğinde state'i güncelle
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.completed) {
          setState(() {
            _isPlaying = false;
            _currentAudioUrl = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses yüklenemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Alternatif Dene',
              textColor: Colors.white,
              onPressed: () => _tryAlternativeAudio(ayet),
            ),
          ),
        );
      }
    }
  }

  /// Audio URL'sinin çalışıp çalışmadığını test et
  Future<bool> _testAudioUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Çalışan audio URL'sini bul
  Future<String?> _findWorkingAudioUrl(AyetModel ayet) async {
    for (final url in ayet.alternativeAudioUrls) {
      if (await _testAudioUrl(url)) {
        return url;
      }
    }
    return null;
  }

  /// Alternatif audio dene
  Future<void> _tryAlternativeAudio(AyetModel ayet) async {
    try {
      final workingUrl = await _findWorkingAudioUrl(ayet);
      if (workingUrl != null) {
        await _audioPlayer.play(UrlSource(workingUrl));
        setState(() {
          _isPlaying = true;
          _currentAudioUrl = workingUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alternatif ses kaynağı bulundu'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hiçbir ses kaynağı çalışmıyor'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alternatif ses de yüklenemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Tüm sureyi oynat
  Future<void> _playFullSurah() async {
    if (_ayetler.isEmpty) return;

    try {
      setState(() => _sesOynatiliyor = !_sesOynatiliyor);

      if (_sesOynatiliyor) {
        // İlk ayetten başla veya kaldığı yerden devam et
        for (int i = _aktifAyetIndex; i < _ayetler.length && _sesOynatiliyor; i++) {
          setState(() => _aktifAyetIndex = i);

          // Sayfayı ayet pozisyonuna kaydır
          if (_pageController.hasClients) {
            await _pageController.animateToPage(
              i,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          // Ayeti oynat ve bitmesini bekle
          await _playAyetAudio(_ayetler[i]);

          // Ses bitene kadar bekle
          while (_isPlaying && _sesOynatiliyor) {
            await Future.delayed(Duration(milliseconds: 100));
          }

          // Ayetler arası kısa bekleme
          if (_sesOynatiliyor) {
            await Future.delayed(Duration(milliseconds: 500));
          }
        }

        setState(() => _sesOynatiliyor = false);
      }
    } catch (e) {
      setState(() => _sesOynatiliyor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses oynatma hatası: $e')),
        );
      }
    }
  }

  /// Son okunan pozisyonu kaydet
  void _saveReadingPosition(int ayahIndex) {
    if (ayahIndex < _ayetler.length) {
      final provider = Provider.of<KuranProvider>(context, listen: false);
      provider.saveLastReadPosition(
          widget.surahModel.number,
          _ayetler[ayahIndex].number
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.surahModel.number}. ${widget.surahModel.englishName}'),
            Text(
              '${widget.surahModel.englishNameTranslation} • ${widget.surahModel.numberOfAyahs} Ayet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(provider.translationGoster
                ? Icons.translate
                : Icons.translate_outlined),
            onPressed: provider.toggleTranslation,
            tooltip: 'Çeviriyi Göster/Gizle',
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border),
            onPressed: () => _showBookmarkedAyahs(),
            tooltip: 'Yer İşaretleri',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'jump_to_ayah':
                  _showJumpToAyahDialog();
                  break;
                case 'last_read':
                  _checkLastReadPosition();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'jump_to_ayah',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Ayete Git'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'last_read',
                child: Row(
                  children: [
                    Icon(Icons.bookmark),
                    SizedBox(width: 8),
                    Text('Son Okuduğuma Git'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Ayarlar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Kontrol paneli
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _ayetler.isNotEmpty && _aktifAyetIndex < _ayetler.length
                      ? 'Ayet ${_ayetler[_aktifAyetIndex].number}/${widget.surahModel.numberOfAyahs}'
                      : 'Ayet 1/${widget.surahModel.numberOfAyahs}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: theme.primaryColor),
                      onPressed: _aktifAyetIndex > 0
                          ? () {
                        final newIndex = _aktifAyetIndex - 1;
                        _pageController.animateToPage(
                          newIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                      tooltip: 'Önceki Ayet',
                    ),
                    IconButton(
                      icon: Icon(
                        _sesOynatiliyor ? Icons.pause : Icons.play_arrow,
                        color: theme.primaryColor,
                      ),
                      onPressed: _playFullSurah,
                      tooltip: _sesOynatiliyor ? 'Durdur' : 'Sureyi Oynat',
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: theme.primaryColor),
                      onPressed: _aktifAyetIndex < _ayetler.length - 1
                          ? () {
                        final newIndex = _aktifAyetIndex + 1;
                        _pageController.animateToPage(
                          newIndex,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                          : null,
                      tooltip: 'Sonraki Ayet',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ana içerik
          Expanded(
            child: _buildMainContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_yukleniyor) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            SizedBox(height: 16),
            Text('Sure yükleniyor...', style: TextStyle(color: theme.primaryColor)),
          ],
        ),
      );
    }

    if (_hata.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(_hata, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sureviYukle,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_ayetler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bu surede ayet bulunamadı'),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _aktifAyetIndex = index);
        _saveReadingPosition(index);
      },
      itemCount: _ayetler.length,
      itemBuilder: (context, index) {
        final ayet = _ayetler[index];
        final isSelected = _seciliAyetIndex == index;
        final isCurrentAudio = _currentAudioUrl == ayet.audioUrl && _isPlaying;

        return Padding(
          padding: EdgeInsets.all(16),
          child: AyetItem(
            ayet: ayet,
            isPlaying: isCurrentAudio,
            isSelected: isSelected,
            onTap: () => setState(() {
              _seciliAyetIndex = isSelected ? null : index;
            }),
            onPlayPressed: () => _playAyetAudio(ayet),
          ),
        );
      },
    );
  }

  /// Yer işaretli ayetleri göster
  void _showBookmarkedAyahs() {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final bookmarkedKeys = provider.getBookmarkedAyahsForSurah(widget.surahModel.number);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Yer İşaretli Ayetler', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            if (bookmarkedKeys.isEmpty)
              Text('Bu surede yer işaretli ayet yok')
            else
              ...bookmarkedKeys.map((key) {
                final ayahNumber = int.parse(key.split('_')[1]);
                return ListTile(
                  title: Text('Ayet $ayahNumber'),
                  onTap: () {
                    Navigator.pop(context);
                    final index = _ayetler.indexWhere((a) => a.number == ayahNumber);
                    if (index != -1) {
                      _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Ayete git dialogu
  void _showJumpToAyahDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ayete Git'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Ayet Numarası (1-${widget.surahModel.numberOfAyahs})',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final ayahNumber = int.tryParse(controller.text);
              if (ayahNumber != null &&
                  ayahNumber >= 1 &&
                  ayahNumber <= widget.surahModel.numberOfAyahs) {
                Navigator.pop(context);
                final index = _ayetler.indexWhere((a) => a.number == ayahNumber);
                if (index != -1) {
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            },
            child: Text('Git'),
          ),
        ],
      ),
    );
  }

  /// Ayarlar dialogu
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Okuma Ayarları'),
        content: Consumer<KuranProvider>(
          builder: (context, provider, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Çeviriyi Göster'),
                value: provider.translationGoster,
                onChanged: (_) => provider.toggleTranslation(),
              ),
              ListTile(
                title: Text('Arapça Font Boyutu'),
                subtitle: Slider(
                  value: provider.arabicFontSize,
                  min: 16.0,
                  max: 32.0,
                  divisions: 8,
                  label: provider.arabicFontSize.round().toString(),
                  onChanged: provider.setArabicFontSize,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }
}