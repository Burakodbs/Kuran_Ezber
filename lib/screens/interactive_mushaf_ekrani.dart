import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ayet_model.dart';
import '../providers/kuran_provider.dart';
import '../models/surah_model.dart';
import '../widgets/ayet_item.dart';
import '../utils/audio_manager.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

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
  final ScrollController _scrollController = ScrollController();
  int _aktifAyetIndex = 0;
  bool _sesOynatiliyor = false;
  int? _seciliAyetIndex;

  @override
  void initState() {
    super.initState();
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

      if (mounted) {
        setState(() {
          _ayetler = ayetler;
          _yukleniyor = false;
        });

        // Son okunan pozisyonu kontrol et
        _checkLastReadPosition();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hata = _getErrorMessage(e);
          _yukleniyor = false;
        });
      }
    }
  }

  /// Hata tipine göre kullanıcı dostu mesaj döndür
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return AppStrings.timeoutError;
    } else if (errorString.contains('socket') || errorString.contains('network')) {
      return AppStrings.networkError;
    } else if (errorString.contains('404') || errorString.contains('not found')) {
      return AppStrings.notFoundError;
    } else if (errorString.contains('500') || errorString.contains('server')) {
      return AppStrings.serverError;
    } else {
      return AppStrings.unexpectedError;
    }
  }

  /// Son okunan pozisyonu kontrol et ve o konuma git
  Future<void> _checkLastReadPosition() async {
    try {
      final provider = Provider.of<KuranProvider>(context, listen: false);
      final lastPosition = await provider.getLastReadPosition();

      if (lastPosition != null &&
          lastPosition['surahNumber'] == widget.surahModel.number) {
        final ayahNumber = lastPosition['ayahNumber']!;
        final index = _ayetler.indexWhere((ayet) => ayet.number == ayahNumber);

        if (index != -1 && mounted) {
          setState(() {
            _aktifAyetIndex = index;
          });

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _scrollController.hasClients) {
              _scrollToAyah(index);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Last read position error: $e');
    }
  }

  /// Ayet sesini oynat
  Future<void> _playAyetAudio(AyetModel ayet) async {
    try {
      await AudioManager.playAudio(ayet.audioUrl, () {
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Audio play error: $e');
      _showErrorSnackBar(AppStrings.audioError);
      await _tryAlternativeAudio(ayet);
    }
  }

  /// Alternatif audio URL'lerini dene
  Future<void> _tryAlternativeAudio(AyetModel ayet) async {
    try {
      final workingUrl = await ayet.findWorkingAudioUrl();
      if (workingUrl != null) {
        await AudioManager.playAudio(workingUrl, () {
          if (mounted) {
            setState(() {});
          }
        });

        _showSuccessSnackBar('Alternatif ses kaynağı bulundu');
      } else {
        _showErrorSnackBar('Hiçbir ses kaynağı çalışmıyor');
      }
    } catch (e) {
      debugPrint('Alternative audio error: $e');
      _showErrorSnackBar('Alternatif ses de yüklenemedi');
    }
  }

  /// Tüm sureyi oynat
  Future<void> _playFullSurah() async {
    if (_ayetler.isEmpty) return;

    try {
      setState(() => _sesOynatiliyor = !_sesOynatiliyor);

      if (_sesOynatiliyor) {
        for (int i = _aktifAyetIndex; i < _ayetler.length && _sesOynatiliyor; i++) {
          if (!mounted) break;

          setState(() => _aktifAyetIndex = i);
          _scrollToAyah(i);
          await _playAyetAudio(_ayetler[i]);

          while (AudioManager.isPlaying && _sesOynatiliyor && mounted) {
            await Future.delayed(const Duration(milliseconds: 100));
          }

          if (_sesOynatiliyor && mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (mounted) {
          setState(() => _sesOynatiliyor = false);
        }
      } else {
        await AudioManager.stopAudio();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sesOynatiliyor = false);
        _showErrorSnackBar('Ses oynatma hatası: $e');
      }
    }
  }

  /// Belirli bir ayete scroll yap
  void _scrollToAyah(int index) {
    if (_scrollController.hasClients && index < _ayetler.length) {
      // Dinamik yükseklik hesaplama yerine tahmini yükseklik kullan
      final estimatedItemHeight = 150.0; // Daha gerçekçi tahmin
      final bismillahHeight = widget.surahModel.number != 9 ? 200.0 : 0.0;
      final targetOffset = bismillahHeight + (index * estimatedItemHeight);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300), // Sabit süre daha performanslı
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Bir sonraki ayete git
  void _nextAyah() {
    if (_aktifAyetIndex < _ayetler.length - 1) {
      setState(() {
        _aktifAyetIndex++;
      });
      _scrollToAyah(_aktifAyetIndex);
      _saveReadingPosition(_aktifAyetIndex);
    }
  }

  /// Bir önceki ayete git
  void _previousAyah() {
    if (_aktifAyetIndex > 0) {
      setState(() {
        _aktifAyetIndex--;
      });
      _scrollToAyah(_aktifAyetIndex);
      _saveReadingPosition(_aktifAyetIndex);
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

  /// Başarı mesajı göster
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Hata mesajı göster
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: AppStrings.retry,
            textColor: Colors.white,
            onPressed: () => _sureviYukle(),
          ),
        ),
      );
    }
  }

  /// Bismillah widget'ı oluştur
  Widget _buildBismillah() {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Süslü çerçeve
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: provider.arabicFontSize + 4,
                  fontFamily: 'UthmanicHafs',
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Türkçe çeviri (isteğe bağlı)
          if (provider.translationGoster)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rahman ve Rahim olan Allah\'ın adıyla',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.primaryColor.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    AudioManager.stopAudio();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.surahModel.number}. ${widget.surahModel.turkishName}'),
            Text(
              '${widget.surahModel.englishNameTranslation} • ${widget.surahModel.numberOfAyahs} ${AppStrings.ayah}',
              style: const TextStyle(
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
            tooltip: AppStrings.tooltipTranslation,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => _showBookmarkedAyahs(),
            tooltip: AppStrings.bookmarks,
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
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Text(AppStrings.goToAyah),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'last_read',
                child: Row(
                  children: [
                    const Icon(Icons.bookmark),
                    const SizedBox(width: 8),
                    Text(AppStrings.goToLastRead),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(AppStrings.settings),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Kontrol paneli
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _ayetler.isNotEmpty && _aktifAyetIndex < _ayetler.length
                              ? '${AppStrings.ayah} ${_ayetler[_aktifAyetIndex].number}/${widget.surahModel.numberOfAyahs}'
                              : '${AppStrings.ayah} 1/${widget.surahModel.numberOfAyahs}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous, color: theme.primaryColor),
                            onPressed: _aktifAyetIndex > 0 ? _previousAyah : null,
                            tooltip: AppStrings.previous,
                          ),
                          IconButton(
                            icon: Icon(
                              _sesOynatiliyor ? Icons.pause : Icons.play_arrow,
                              color: theme.primaryColor,
                            ),
                            onPressed: _playFullSurah,
                            tooltip: _sesOynatiliyor ? AppStrings.pause : AppStrings.playSurah,
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next, color: theme.primaryColor),
                            onPressed: _aktifAyetIndex < _ayetler.length - 1 ? _nextAyah : null,
                            tooltip: AppStrings.next,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Ana içerik
              Expanded(
                child: _buildMainContent(theme),
              ),
            ],
          ),
        ),
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
            const SizedBox(height: 16),
            Text(
              AppStrings.loadingAyahs,
              style: TextStyle(color: theme.primaryColor),
            ),
          ],
        ),
      );
    }

    if (_hata.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _hata,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sureviYukle,
              child: Text(AppStrings.retry),
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
            const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppStrings.noDataAvailable),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        cacheExtent: 100.0,
        slivers: [
          // Bismillah - Tevbe suresi hariç
          if (widget.surahModel.number != 9)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _buildBismillah(),
              ),
            ),

          // Ayetler - Performans optimizasyonu için ListView.builder kullan
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.builder(
              itemCount: _ayetler.length,
              itemBuilder: (context, index) {
                final ayet = _ayetler[index];
                final isCurrentAudio = AudioManager.currentAudioUrl == ayet.audioUrl && AudioManager.isPlaying;
                final isSelected = _seciliAyetIndex == index;

                return RepaintBoundary(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: AyetItem(
                      ayet: ayet,
                      isPlaying: isCurrentAudio,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _seciliAyetIndex = isSelected ? null : index;
                          _aktifAyetIndex = index;
                        });
                        _saveReadingPosition(index);
                      },
                      onPlayPressed: () => _playAyetAudio(ayet),
                    ),
                  ),
                );
              },
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false, // RepaintBoundary'i manuel ekledik
              addSemanticIndexes: false,
            ),
          ),
        ],
      ),
    );
  }

  /// Yer işaretli ayetleri göster
  void _showBookmarkedAyahs() {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final bookmarkedKeys = provider.getBookmarkedAyahsForSurah(widget.surahModel.number);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.bookmarks,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (bookmarkedKeys.isEmpty)
              Text(AppStrings.noBookmarks)
            else
              ...bookmarkedKeys.map((key) {
                final ayahNumber = int.parse(key.split('_')[1]);
                return ListTile(
                  title: Text('${AppStrings.ayah} $ayahNumber'),
                  onTap: () {
                    Navigator.pop(context);
                    final index = _ayetler.indexWhere((a) => a.number == ayahNumber);
                    if (index != -1) {
                      setState(() {
                        _aktifAyetIndex = index;
                      });
                      _scrollToAyah(index);
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
        title: Text(AppStrings.goToAyah),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${AppStrings.ayahNumber} (1-${widget.surahModel.numberOfAyahs})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
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
                  setState(() {
                    _aktifAyetIndex = index;
                  });
                  _scrollToAyah(index);
                }
              }
            },
            child: Text(AppStrings.ok),
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
        title: Text(AppStrings.settings),
        content: Consumer<KuranProvider>(
          builder: (context, provider, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(AppStrings.showTranslation),
                value: provider.translationGoster,
                onChanged: (_) => provider.toggleTranslation(),
              ),
              ListTile(
                title: Text(AppStrings.arabicFontSize),
                subtitle: Slider(
                  value: provider.arabicFontSize,
                  min: AppConstants.minFontSize,
                  max: AppConstants.maxFontSize,
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
            child: Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}