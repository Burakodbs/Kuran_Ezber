import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../utils/storage_helper.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_info.dart';
import 'about_screen.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani>
    with TickerProviderStateMixin {

  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _storageInfo = {};
  Map<String, dynamic> _appStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStorageInfo();
    _loadAppStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageInfo() async {
    final info = await StorageHelper.getStorageInfo();
    if (mounted) {
      setState(() {
        _storageInfo = info;
      });
    }
  }

  Future<void> _loadAppStats() async {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final stats = await provider.getAppStatistics();
    if (mounted) {
      setState(() {
        _appStats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      resizeToAvoidBottomInset: false, // Keyboard overflow'u önler
      appBar: AppBar(
        title: Text(AppStrings.settings),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true, // Tab overflow'u önler
          tabs: const [
            Tab(icon: Icon(Icons.visibility), text: 'Görünüm'),
            Tab(icon: Icon(Icons.volume_up), text: 'Ses'),
            Tab(icon: Icon(Icons.storage), text: 'Veri'),
            Tab(icon: Icon(Icons.info), text: 'Hakkında'),
          ],
        ),
      ),
      body: SafeArea( // SafeArea ekledik
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppearanceTab(),
            _buildAudioTab(),
            _buildDataTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  // Görünüm Ayarları Sekmesi
  Widget _buildAppearanceTab() {
    return Consumer<KuranProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView( // ScrollView eklendi
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSectionCard(
                  title: AppStrings.appearanceSettings,
                  icon: Icons.palette,
                  children: [
                    SwitchListTile(
                      title: Text(AppStrings.showTranslation),
                      subtitle: const Text('Ayetlerin altında Türkçe çevirisini göster'),
                      value: provider.translationGoster,
                      onChanged: (_) => provider.toggleTranslation(),
                      activeColor: Theme.of(context).primaryColor,
                      secondary: const Icon(Icons.translate),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(AppStrings.darkMode),
                      subtitle: const Text('Uygulamayı koyu renklerde görüntüle'),
                      value: provider.darkMode,
                      onChanged: (_) => provider.toggleDarkMode(),
                      activeColor: Theme.of(context).primaryColor,
                      secondary: Icon(
                        provider.darkMode ? Icons.dark_mode : Icons.light_mode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSectionCard(
                  title: AppStrings.arabicFontSize,
                  icon: Icons.format_size,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.arabicFontSize,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${provider.arabicFontSize.round()}pt',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Slider(
                            value: provider.arabicFontSize,
                            min: AppConstants.minFontSize,
                            max: AppConstants.maxFontSize,
                            divisions: 8,
                            label: '${provider.arabicFontSize.round()}pt',
                            onChanged: provider.setArabicFontSize,
                            activeColor: Theme.of(context).primaryColor,
                          ),

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: provider.arabicFontSize,
                                fontFamily: 'Amiri',
                                color: Theme.of(context).primaryColor,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Alt boşluk
              ],
            ),
          ),
        );
      },
    );
  }

  // Ses Ayarları Sekmesi
  Widget _buildAudioTab() {
    return SingleChildScrollView( // ScrollView eklendi
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              title: AppStrings.audioSettings,
              icon: Icons.volume_up,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(AppStrings.audioReciter),
                  subtitle: Text(AppStrings.reciterAhmedTalebHameed),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQariDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.high_quality),
                  title: Text(AppStrings.audioQuality),
                  subtitle: Text(AppStrings.qualityHigh),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQualityDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Oynatma Hızı'),
                  subtitle: const Text('Normal (1.0x)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPlaybackSpeedDialog(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Çeviri Ayarları',
              icon: Icons.translate,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Çeviri Dili'),
                  subtitle: Text(AppStrings.translationDiyanet),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTranslationDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16), // Alt boşluk
          ],
        ),
      ),
    );
  }

  // Veri Yönetimi Sekmesi
  Widget _buildDataTab() {
    return Consumer<KuranProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView( // ScrollView eklendi
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSectionCard(
                  title: AppStrings.bookmarks,
                  icon: Icons.bookmark,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bookmark_border),
                      title: Text(AppStrings.bookmarks),
                      subtitle: Text('${provider.getBookmarkedAyahs().length} ayet işaretli'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _showBookmarksDialog(provider),
                            tooltip: 'Yer işaretlerini görüntüle',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: provider.getBookmarkedAyahs().isNotEmpty
                                ? () => _showClearBookmarksDialog(provider)
                                : null,
                            tooltip: 'Tüm yer işaretlerini sil',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildSectionCard(
                  title: AppStrings.dataManagement,
                  icon: Icons.storage,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: Text(AppStrings.clearCache),
                      subtitle: Text('${_storageInfo['cacheKeys'] ?? 0} önbellek dosyası'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showClearCacheDialog(provider),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Verileri Yenile'),
                      subtitle: const Text('Tüm sûre verilerini yeniden indir'),
                      trailing: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _refreshAllData(provider),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildStorageStatsCard(),
                const SizedBox(height: 16), // Alt boşluk
              ],
            ),
          ),
        );
      },
    );
  }

  // Hakkında Sekmesi
  Widget _buildAboutTab() {
    return SingleChildScrollView( // ScrollView eklendi
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard(
              title: AppStrings.about,
              icon: Icons.info,
              children: [
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: Text(AppStrings.appVersion),
                  subtitle: Text(AppConstants.appVersion),
                  trailing: const Icon(Icons.info_outline),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Geliştirici'),
                  subtitle: Text(AppConstants.developer),
                  trailing: const Icon(Icons.code),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Gizlilik Politikası'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Hakkında & Developer'),
                  subtitle: Text('${AppInfo.appName} v${AppInfo.appVersion}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_rate),
                  title: const Text('Uygulamayı Değerlendir'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showRatingDialog(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildAppStatsCard(),
            const SizedBox(height: 16), // Alt boşluk
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStorageStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Depolama İstatistikleri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Toplam Anahtar', '${_storageInfo['totalKeys'] ?? 0}'),
            _buildStatRow('Önbellek Dosyaları', '${_storageInfo['cacheKeys'] ?? 0}'),
            _buildStatRow('Yer İşaretleri', '${_storageInfo['bookmarksCount'] ?? 0}'),
            _buildStatRow('Son Okuma Konumu',
                _storageInfo['hasLastRead'] == true ? 'Kayıtlı' : 'Yok'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Uygulama İstatistikleri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Okuma Sayısı', '${_appStats['readCount'] ?? 0}'),
            _buildStatRow('Yüklü Sûreler', '${_appStats['totalSurahs'] ?? 0}'),
            _buildStatRow('Bağlantı Durumu',
                _appStats['isOnline'] == true ? 'Çevrimiçi' : 'Çevrimdışı'),
            if (_appStats['lastOpenDate'] != null)
              _buildStatRow('Son Açılış',
                  _formatDate(_appStats['lastOpenDate'])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Bugün';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  // Dialog Methods
  void _showTranslationDialog() {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çeviri Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppStrings.translationDiyanet),
              value: 'tr.diyanet',
              groupValue: provider.selectedTranslation,
              onChanged: (value) {
                if (value != null) {
                  provider.setTranslation(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(AppStrings.translationElmali),
              value: 'tr.elmali',
              groupValue: provider.selectedTranslation,
              onChanged: (value) {
                if (value != null) {
                  provider.setTranslation(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showQariDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qari Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppStrings.reciterAhmedTalebHameed),
              subtitle: const Text('Varsayılan'),
              trailing: const Icon(Icons.check, color: Colors.green),
              selected: true,
            ),
            ListTile(
              title: Text(AppStrings.reciterAlafasy),
              subtitle: const Text('Alternatif'),
              enabled: true,
              onTap: () {
                // Buraya reciter değiştirme kodunu ekleyebiliriz
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(AppStrings.reciterSudais),
              subtitle: const Text('Alternatif'),
              enabled: true,
              onTap: () {
                // Buraya reciter değiştirme kodunu ekleyebiliriz
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(AppStrings.reciterGhamdi),
              subtitle: const Text('Yakında'),
              enabled: false,
            ),
          ],
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

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.audioQuality),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(AppStrings.qualityHigh),
              subtitle: const Text('Önerilen'),
              value: '128',
              groupValue: '128',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: Text(AppStrings.qualityMedium),
              subtitle: const Text('Veri tasarrufu'),
              value: '64',
              groupValue: '128',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: Text(AppStrings.qualityLow),
              subtitle: const Text('Minimum veri'),
              value: '32',
              groupValue: '128',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oynatma Hızı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: const Text('Yavaş (0.75x)'),
              value: 0.75,
              groupValue: 1.0,
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<double>(
              title: const Text('Normal (1.0x)'),
              subtitle: const Text('Varsayılan'),
              value: 1.0,
              groupValue: 1.0,
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<double>(
              title: const Text('Hızlı (1.25x)'),
              value: 1.25,
              groupValue: 1.0,
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<double>(
              title: const Text('Çok Hızlı (1.5x)'),
              value: 1.5,
              groupValue: 1.0,
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showBookmarksDialog(KuranProvider provider) {
    final bookmarks = provider.getBookmarkedAyahs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.bookmarks),
        content: ConstrainedBox( // Boyut sınırlaması eklendi
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SizedBox(
            width: double.maxFinite,
            child: bookmarks.isEmpty
                ? SizedBox(
              height: 200, // Sabit yükseklik
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.noBookmarks,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true, // İçerik kadar yer kaplasın
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final parts = bookmarks[index].split('_');
                final surah = int.parse(parts[0]);
                final ayah = int.parse(parts[1]);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '$surah',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Sure $surah, Ayet $ayah'),
                  subtitle: Text('Yer işareti ${index + 1}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      provider.toggleYerIsareti(bookmarks[index]);
                      Navigator.pop(context);
                      _showBookmarksDialog(provider);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          if (bookmarks.isNotEmpty)
            TextButton(
              onPressed: () => _showClearBookmarksDialog(provider),
              child: Text(
                'Tümünü Sil',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  void _showClearBookmarksDialog(KuranProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yer İşaretlerini Temizle'),
        content: Text(AppStrings.confirmClearBookmarks),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await provider.clearAllBookmarks();
              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Tüm yer işaretleri silindi'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              AppStrings.delete,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(KuranProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.clearCache),
        content: Text(AppStrings.confirmClearCache),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final messenger = ScaffoldMessenger.of(context);

              await provider.clearCache();
              await _loadStorageInfo();

              if (mounted) {
                setState(() => _isLoading = false);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.cacheCleared),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              AppStrings.clearAll,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAllData(KuranProvider provider) async {
    setState(() => _isLoading = true);

    try {
      await provider.clearCache();
      await provider.sureleriYukle();
      await _loadStorageInfo();
      await _loadAppStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.dataDownloaded),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yenileme hatası: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gizlilik Politikası'),
        content: SingleChildScrollView(
          child: Text(
            AppStrings.privacyText,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulamayı Değerlendir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            const Text(
              'Uygulamamızı beğendiyseniz lütfen değerlendirin!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < 5 ? Colors.amber : Colors.grey[300],
                  ),
                  onPressed: () {
                    // Rating logic here
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Store'a yönlendir
            },
            child: const Text('Değerlendir'),
          ),
        ],
      ),
    );
  }
}