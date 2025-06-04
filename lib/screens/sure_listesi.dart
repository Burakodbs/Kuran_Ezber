import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/surah_model.dart';
import '../widgets/surah_card.dart';
import 'interactive_mushaf_ekrani.dart';
import 'ayarlar_ekrani.dart';

class SureListesi extends StatefulWidget {
  const SureListesi({super.key});

  @override
  _SureListesiState createState() => _SureListesiState();
}

class _SureListesiState extends State<SureListesi> {
  final TextEditingController _searchController = TextEditingController();
  List<SurahModel> _filtrelenmisSureler = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtreSureler);
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

  void _filtreSureler() {
    final query = _searchController.text.toLowerCase();
    final provider = Provider.of<KuranProvider>(context, listen: false);

    setState(() {
      if (query.isEmpty) {
        _filtrelenmisSureler = provider.sureler;
      } else {
        _filtrelenmisSureler = provider.sureler.where((sure) {
          return sure.englishName.toLowerCase().contains(query) ||
              sure.name.toLowerCase().contains(query) ||
              sure.number.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kuran Ezber - KSU Electronic Mushaf'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: KuranSearchDelegate(provider.sureler),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AyarlarEkrani()),
            ),
          ),
        ],
      ),
      body: provider.yukleniyor
          ? Center(child: CircularProgressIndicator(color: Color(0xFF1B4F3A)))
          : provider.hata.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              provider.hata,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: provider.sureleriYukle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B4F3A),
                foregroundColor: Colors.white,
              ),
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      )
          : _filtrelenmisSureler.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aradığınız kriterlere uygun sûre bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filtrelenmisSureler.length,
        itemBuilder: (context, index) {
          return SurahCard(
            sure: _filtrelenmisSureler[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InteractiveMushafEkrani(
                  surahModel: _filtrelenmisSureler[index],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class KuranSearchDelegate extends SearchDelegate<String> {
  final List<SurahModel> sureler;

  KuranSearchDelegate(this.sureler);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => query = '',
    )
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = query.isEmpty
        ? sureler
        : sureler.where((sure) {
      return sure.englishName.toLowerCase().contains(query.toLowerCase()) ||
          sure.name.toLowerCase().contains(query.toLowerCase()) ||
          sure.number.toString().contains(query);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aradığınız kriterlere uygun sûre bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) => SurahCard(
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
    );
  }
}