import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/surah_model.dart';
import '../widgets/surah_card.dart';
import '../widgets/custom_app_bar.dart';
import 'interactive_mushaf_ekrani.dart';
import 'ayarlar_ekrani.dart';
import 'search_screen.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

class SureListesi extends StatefulWidget {
  const SureListesi({super.key});

  @override
  State<SureListesi> createState() => _SureListesiState();
}

class _SureListesiState extends State<SureListesi> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<SurahModel> _filtrelenmisSureler = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'all'; // all, meccan, medinan
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtreSureler);

    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<KuranProvider>(context, listen: false);
    if (provider.sureler.isEmpty && !provider.yukleniyor) {
      provider.sureleriYukle();
    }
    _filtrelenmisSureler = provider.sureler;
  }

  /// Responsive cross axis count hesapla
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 2;
  }

  /// Responsive aspect ratio hesapla
  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 1.4;
    if (width > 800) return 1.35;
    return 1.3;
  }

  /// Sureleri filtrele - Türkçe isimlerle de arama yapabilir
  void _filtreSureler() {
    final query = _searchController.text.toLowerCase();
    final provider = Provider.of<KuranProvider>(context, listen: false);

    setState(() {
      List<SurahModel> baseSureler = provider.sureler;

      // Revelation type filter
      if (_selectedFilter == 'meccan') {
        baseSureler = baseSureler.where((sure) => sure.revelationType == 'meccan').toList();
      } else if (_selectedFilter == 'medinan') {
        baseSureler = baseSureler.where((sure) => sure.revelationType == 'medinan').toList();
      }

      // Favorites filter
      if (_showFavorites) {
        baseSureler = baseSureler.where((sure) {
          return AppConstants.popularSurahs.contains(sure.number);
        }).toList();
      }

      // Text search filter - Türkçe isimler de dahil
      if (query.isEmpty) {
        _filtrelenmisSureler = baseSureler;
      } else {
        _filtrelenmisSureler = baseSureler.where((sure) {
          return sure.englishName.toLowerCase().contains(query) ||
              sure.turkishName.toLowerCase().contains(query) ||  // Türkçe isim araması eklendi
              sure.name.toLowerCase().contains(query) ||
              sure.englishNameTranslation.toLowerCase().contains(query) ||
              sure.number.toString().contains(query);
        }).toList();
      }
    });
  }

  /// Filter değiştir
  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filtreSureler();
  }

  /// Favorites toggle
  void _toggleFavorites() {
    setState(() {
      _showFavorites = !_showFavorites;
    });
    _filtreSureler();
  }

  /// Filter chips widget'ı
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip(AppStrings.surahs, 'all'),
            const SizedBox(width: 8),
            _buildFilterChip(AppStrings.meccan, 'meccan'),
            const SizedBox(width: 8),
            _buildFilterChip(AppStrings.medinan, 'medinan'),
            const SizedBox(width: 8),
            _buildFavoriteChip(),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  /// Filter chip widget'ı
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _changeFilter(value),
      backgroundColor: theme.cardColor,
      selectedColor: theme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Favorite chip widget'ı
  Widget _buildFavoriteChip() {
    final theme = Theme.of(context);

    return FilterChip(
      label: const Text('Popüler'),
      selected: _showFavorites,
      onSelected: (_) => _toggleFavorites(),
      backgroundColor: theme.cardColor,
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      checkmarkColor: Colors.orange,
      avatar: Icon(
        _showFavorites ? Icons.star : Icons.star_border,
        color: _showFavorites ? Colors.orange : null,
        size: 18,
      ),
      labelStyle: TextStyle(
        color: _showFavorites ? Colors.orange : null,
        fontWeight: _showFavorites ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Hızlı erişim sectionı
  Widget _buildQuickAccess(KuranProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Erişim',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickAccessCard(
                    title: AppStrings.lastRead,
                    icon: Icons.bookmark,
                    onTap: () => _goToLastRead(provider),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAccessCard(
                    title: AppStrings.bookmarks,
                    icon: Icons.favorite,
                    onTap: () => _showBookmarksDialog(provider),
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAccessCard(
                    title: AppStrings.search,
                    icon: Icons.search,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SearchScreen()),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hızlı erişim kartı
  Widget _buildQuickAccessCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Son okunan yere git
  Future<void> _goToLastRead(KuranProvider provider) async {
    final lastRead = await provider.getLastReadPosition();
    if (lastRead != null && mounted) {
      final surahNumber = lastRead['surahNumber']!;
      final surah = provider.sureler.firstWhere(
            (s) => s.number == surahNumber,
        orElse: () => provider.sureler.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InteractiveMushafEkrani(surahModel: surah),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz okuma geçmişi bulunamadı'),
        ),
      );
    }
  }

  /// Bookmarks dialogunu göster
  void _showBookmarksDialog(KuranProvider provider) {
    final bookmarks = provider.getBookmarkedAyahs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.bookmarks),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: bookmarks.isEmpty
              ? Center(child: Text(AppStrings.noBookmarks))
              : ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final parts = bookmarks[index].split('_');
              final surahNumber = int.parse(parts[0]);
              final ayahNumber = int.parse(parts[1]);
              final surah = provider.sureler.firstWhere(
                    (s) => s.number == surahNumber,
                orElse: () => provider.sureler.first,
              );

              return ListTile(
                title: Text('${surah.turkishName} - ${AppStrings.ayah} $ayahNumber'),
                subtitle: Text('${surah.number}. Sûre • ${surah.numberOfAyahs} ${AppStrings.ayah}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InteractiveMushafEkrani(
                        surahModel: surah,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: IslamicAppBar(
        title: AppStrings.appTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
            tooltip: AppStrings.search,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AyarlarEkrani()),
            ),
            tooltip: AppStrings.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<KuranProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.sureleriYukle,
              color: Theme.of(context).primaryColor,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(provider, Theme.of(context)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(KuranProvider provider, ThemeData theme) {
    if (provider.yukleniyor && provider.sureler.isEmpty) {
      return _buildLoadingState(theme);
    }

    if (provider.hata.isNotEmpty && provider.sureler.isEmpty) {
      return _buildErrorState(provider, theme);
    }

    return Column(
      children: [
        // Hızlı erişim
        if (provider.sureler.isNotEmpty) _buildQuickAccess(provider),

        // Filter chips
        if (provider.sureler.isNotEmpty) _buildFilterChips(),

        // Ana içerik
        Expanded(
          child: _buildMainContent(provider, theme),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            AppStrings.loadingSurahs,
            style: TextStyle(color: theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(KuranProvider provider, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.isOnline ? Icons.error_outline : Icons.wifi_off,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.hata,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: provider.sureleriYukle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppStrings.retry),
                ),
                if (!provider.isOnline) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => provider.clearCacheAndReload(),
                    child: Text(AppStrings.clearCache),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(KuranProvider provider, ThemeData theme) {
    if (_filtrelenmisSureler.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: _getAspectRatio(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtrelenmisSureler.length,
      itemBuilder: (context, index) {
        final sure = _filtrelenmisSureler[index];

        return RepaintBoundary(
          child: Hero(
            tag: 'surah_${sure.number}',
            child: SurahCard(
              sure: sure,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InteractiveMushafEkrani(
                    surahModel: sure,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false, // RepaintBoundary'i manuel ekledik
      addSemanticIndexes: false,
      cacheExtent: 0, // Viewport dışındaki widget'ları cache'leme
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppStrings.noSearchResults,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _changeFilter('all');
              setState(() {
                _showFavorites = false;
              });
            },
            child: Text(AppStrings.clearSearch),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

/// Enhanced Search Delegate
class KuranSearchDelegate extends SearchDelegate<String> {
  final List<SurahModel> sureler;

  KuranSearchDelegate(this.sureler);

  @override
  String get searchFieldLabel => AppStrings.searchHint;

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    )
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final results = query.isEmpty
        ? sureler
        : sureler.where((sure) {
      return sure.englishName.toLowerCase().contains(query.toLowerCase()) ||
          sure.turkishName.toLowerCase().contains(query.toLowerCase()) ||  // Türkçe isim araması
          sure.name.toLowerCase().contains(query.toLowerCase()) ||
          sure.englishNameTranslation.toLowerCase().contains(query.toLowerCase()) ||
          sure.number.toString().contains(query);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppStrings.noSearchResults,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) => Hero(
        tag: 'search_surah_${results[index].number}',
        child: SurahCard(
          sure: results[index],
          onTap: () {
            close(context, '');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InteractiveMushafEkrani(
                  surahModel: results[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}