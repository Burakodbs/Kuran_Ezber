import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';

class AyarlarEkrani extends StatelessWidget {
  const AyarlarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Görünüm Ayarları
          _buildSectionHeader('Görünüm Ayarları', theme),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Çevirileri Göster'),
                  subtitle: Text('Ayetlerin altında Türkçe çevirisini göster'),
                  value: provider.translationGoster,
                  onChanged: (_) => provider.toggleTranslation(),
                  activeColor: theme.primaryColor,
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Koyu Tema'),
                  subtitle: Text('Uygulamayı koyu renklerde görüntüle'),
                  value: provider.darkMode,
                  onChanged: (_) => provider.toggleDarkMode(),
                  activeColor: theme.primaryColor,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Yazı Boyutu Ayarları
          _buildSectionHeader('Yazı Boyutu', theme),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arapça Font Boyutu',
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${provider.arabicFontSize.round()}pt',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: provider.arabicFontSize,
                    min: 16.0,
                    max: 32.0,
                    divisions: 8,
                    label: '${provider.arabicFontSize.round()}pt',
                    onChanged: provider.setArabicFontSize,
                    activeColor: theme.primaryColor,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: provider.arabicFontSize,
                        fontFamily: 'UthmanicHafs',
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Çeviri Ayarları
          _buildSectionHeader('Çeviri Ayarları', theme),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text('Çeviri Dili'),
              subtitle: Text('Türkçe (Diyanet İşleri Başkanlığı)'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showTranslationDialog(context, provider),
            ),
          ),

          SizedBox(height: 24),

          // Ses Ayarları
          _buildSectionHeader('Ses Ayarları', theme),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Qari (Okuyucu)'),
                  subtitle: Text('Mishary Rashid Alafasy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQariDialog(context),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Ses Kalitesi'),
                  subtitle: Text('Yüksek (128 kbps)'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showQualityDialog(context),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Veri Yönetimi
          _buildSectionHeader('Veri Yönetimi', theme),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Yer İşaretleri'),
                  subtitle: Text('${provider.getBookmarkedAyahs().length} ayet işaretli'),
                  trailing: Icon(Icons.bookmark, color: theme.primaryColor),
                  onTap: () => _showBookmarksDialog(context, provider),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Önbelleği Temizle'),
                  subtitle: Text('İndirilen verileri sil'),
                  trailing: Icon(Icons.delete_outline, color: Colors.red),
                  onTap: () => _showClearCacheDialog(context),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Hakkında
          _buildSectionHeader('Hakkında', theme),
          SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Uygulama Versiyonu'),
                  subtitle: Text('v1.0.0'),
                  trailing: Icon(Icons.info_outline),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Geliştirici'),
                  subtitle: Text('KSU Elektronik Mushaf Ekibi'),
                  trailing: Icon(Icons.code),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Gizlilik Politikası'),
                  trailing: Icon(Icons.privacy_tip_outlined),
                  onTap: () => _showPrivacyDialog(context),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTranslationDialog(BuildContext context, KuranProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çeviri Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Türkçe (Diyanet)'),
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
              title: Text('Türkçe (Elmalı)'),
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
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showQariDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Qari Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Mishary Rashid Alafasy'),
              subtitle: Text('Varsayılan'),
              trailing: Icon(Icons.check, color: Colors.green),
            ),
            ListTile(
              title: Text('Abdul Rahman Al-Sudais'),
              subtitle: Text('Yakında'),
              enabled: false,
            ),
            ListTile(
              title: Text('Saad Al-Ghamdi'),
              subtitle: Text('Yakında'),
              enabled: false,
            ),
          ],
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

  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ses Kalitesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Yüksek (128 kbps)'),
              subtitle: Text('Önerilen'),
              value: '128',
              groupValue: '128',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: Text('Orta (64 kbps)'),
              subtitle: Text('Veri tasarrufu'),
              value: '64',
              groupValue: '128',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showBookmarksDialog(BuildContext context, KuranProvider provider) {
    final bookmarks = provider.getBookmarkedAyahs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Yer İşaretleri'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: bookmarks.isEmpty
              ? Center(child: Text('Henüz yer işareti eklenmemiş'))
              : ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final parts = bookmarks[index].split('_');
              final surah = int.parse(parts[0]);
              final ayah = int.parse(parts[1]);

              return ListTile(
                title: Text('Sure $surah, Ayet $ayah'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    provider.toggleYerIsareti(bookmarks[index]);
                    Navigator.pop(context);
                    _showBookmarksDialog(context, provider);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          if (bookmarks.isNotEmpty)
            TextButton(
              onPressed: () {
                // Tüm yer işaretlerini sil
                for (final bookmark in bookmarks) {
                  provider.toggleYerIsareti(bookmark);
                }
                Navigator.pop(context);
              },
              child: Text('Tümünü Sil', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Önbelleği Temizle'),
        content: Text('Bu işlem indirilen tüm verileri silecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // Cache temizleme işlemi burada yapılacak
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Önbellek temizlendi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Temizle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gizlilik Politikası'),
        content: SingleChildScrollView(
          child: Text(
            '''Bu uygulama kişisel verilerinizi korur:

• Okuma geçmişiniz sadece cihazınızda saklanır
• Yer işaretleriniz yerel olarak kaydedilir
• İnternet bağlantısı sadece Kuran verilerini indirmek için kullanılır
• Hiçbir kişisel bilgi üçüncü taraflarla paylaşılmaz
• Kullanım analitikleri toplanmaz

Sorularınız için iletişime geçebilirsiniz.''',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anladım'),
          ),
        ],
      ),
    );
  }
}