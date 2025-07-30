import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/surah_model.dart';
import '../widgets/surah_card.dart';
import 'interactive_mushaf_ekrani.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<SurahModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    final provider = Provider.of<KuranProvider>(context, listen: false);

    setState(() {
      _isSearching = query.isNotEmpty;
      _hasSearched = query.isNotEmpty;

      if (query.isEmpty) {
        _searchResults = [];
        _animationController.reverse();
      } else {
        _searchResults = provider.sureler.where((sure) {
          return sure.englishName.toLowerCase().contains(query.toLowerCase()) ||
              sure.turkishName.toLowerCase().contains(query.toLowerCase()) ||  // Türkçe isim araması eklendi
              sure.name.toLowerCase().contains(query.toLowerCase()) ||
              sure.englishNameTranslation.toLowerCase().contains(query.toLowerCase()) ||
              sure.number.toString().contains(query) ||
              sure.revelationType.toLowerCase().contains(query.toLowerCase());
        }).toList();
        _animationController.forward();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Sûre Ara'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSearchBar(theme),
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Sûre adı (Türkçe/Arapça), numarası veya özelliği arayın...',
          prefixIcon: Icon(
            Icons.search,
            color: theme.primaryColor,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: theme.primaryColor,
            ),
            onPressed: _clearSearch,
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (!_hasSearched) {
      return _buildInitialState(theme);
    }

    if (_isSearching && _searchResults.isEmpty) {
      return _buildNoResults(theme);
    }

    if (_searchResults.isEmpty) {
      return _buildInitialState(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildSearchResults(theme),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 60,
              color: theme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sûre Arama',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Yukarıdaki arama kutusuna sûre adı, numarası veya özelliği yazarak arama yapabilirsiniz',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 32),
          _buildSearchTips(theme),
        ],
      ),
    );
  }

  Widget _buildSearchTips(ThemeData theme) {
    final tips = [
      {'icon': Icons.numbers, 'text': 'Sûre numarası (ör: 1, 2, 114)'},
      {'icon': Icons.text_fields, 'text': 'Türkçe sûre adı (ör: Fatiha, Bakara, Nisa)'},
      {'icon': Icons.translate, 'text': 'Arapça sûre adı (ör: الفاتحة، البقرة)'},
      {'icon': Icons.location_on, 'text': 'Nüzul yeri (ör: Mekki, Medeni)'},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arama İpuçları:',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  tip['icon'] as IconData,
                  size: 16,
                  color: theme.primaryColor.withValues(alpha: 0.7),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip['text'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 50,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Sonuç Bulunamadı',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '"${_searchController.text}" araması için sonuç bulunamadı.\nFarklı anahtar kelimeler deneyebilirsiniz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearSearch,
            icon: Icon(Icons.refresh),
            label: Text('Yeni Arama'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} sûre bulundu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: 'surah_${_searchResults[index].number}',
                child: SurahCard(
                  sure: _searchResults[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InteractiveMushafEkrani(
                          surahModel: _searchResults[index],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}