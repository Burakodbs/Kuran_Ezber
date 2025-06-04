import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/ayet_model.dart';
import '../constants/app_strings.dart';
import '../utils/audio_manager.dart';

class AyetItem extends StatefulWidget {
  final AyetModel ayet;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlayPressed;

  const AyetItem({
    super.key,
    required this.ayet,
    this.isPlaying = false,
    this.isSelected = false,
    required this.onTap,
    required this.onPlayPressed,
  });

  @override
  State<AyetItem> createState() => _AyetItemState();
}

class _AyetItemState extends State<AyetItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isBookmarked = provider.isBookmarked(widget.ayet.bookmarkKey);

    return Directionality(
      textDirection: TextDirection.rtl, // Tüm widget RTL
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(theme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(theme),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Ayet numarası + Kontroller
                  _buildHeader(theme, isBookmarked),

                  const SizedBox(height: 8),

                  // Arapça metin (zaten RTL)
                  _buildArabicText(theme, provider),

                  // Çeviri (LTR)
                  if (provider.translationGoster && widget.ayet.turkish.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildTranslationText(theme),
                  ],

                  // Genişletilmiş eylemler
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    _buildActionButtons(theme, provider, isBookmarked),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isBookmarked) {
    return Directionality(
      textDirection: TextDirection.ltr, // Header kontrollerini LTR tut
      child: Row(
        children: [
          // Ayet numarası (sağ tarafta)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.isPlaying ? Colors.green : theme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.isPlaying ? Colors.green : theme.primaryColor)
                      .withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.ayet.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Yer işareti göstergesi
          if (isBookmarked) ...[
            Icon(
              Icons.bookmark,
              color: Colors.red.shade600,
              size: 18,
            ),
            const SizedBox(width: 4),
          ],

          const Spacer(),

          // Genişlet butonu
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.more_vert,
                  color: theme.primaryColor.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Oynat butonu (en sağda)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPlayPressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicText(ThemeData theme, KuranProvider provider) {
    return Text(
      widget.ayet.arabic,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontSize: _getResponsiveFontSize(provider.arabicFontSize),
        height: 1.6,
        color: widget.isPlaying
            ? theme.primaryColor
            : theme.textTheme.bodyLarge?.color ?? Colors.black87,
        fontWeight: widget.isPlaying ? FontWeight.w600 : FontWeight.w400,
        fontFamily: 'UthmanicHafs',
        wordSpacing: 2,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTranslationText(ThemeData theme) {
    return Directionality(
      textDirection: TextDirection.ltr, // Türkçe çeviri LTR
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          widget.ayet.turkish,
          style: TextStyle(
            fontSize: 12,
            color: theme.primaryColor.withOpacity(0.85),
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.ltr, // Türkçe LTR
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, KuranProvider provider, bool isBookmarked) {
    return Directionality(
      textDirection: TextDirection.ltr, // Butonlar LTR kalsın
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: isBookmarked ? 'Kaldır' : 'İşaretle',
              onPressed: () => provider.toggleYerIsareti(widget.ayet.bookmarkKey),
              color: isBookmarked ? Colors.red.shade600 : theme.primaryColor,
            ),
            _buildActionButton(
              icon: Icons.share_outlined,
              label: 'Paylaş',
              onPressed: _handleShare,
              color: theme.primaryColor,
            ),
            _buildActionButton(
              icon: Icons.copy_outlined,
              label: 'Kopyala',
              onPressed: _handleCopy,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive font size
  double _getResponsiveFontSize(double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 800) {
      return baseFontSize; // Desktop - normal boyut
    } else if (screenWidth > 600) {
      return baseFontSize * 0.9; // Tablet - biraz küçük
    } else {
      return baseFontSize * 0.85; // Mobile - daha küçük
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isPlaying) {
      return theme.primaryColor.withOpacity(0.12);
    } else if (widget.isSelected) {
      return theme.primaryColor.withOpacity(0.06);
    }
    return theme.cardColor;
  }

  Color _getBorderColor(ThemeData theme) {
    if (widget.isSelected) {
      return theme.primaryColor;
    } else if (widget.isPlaying) {
      return theme.primaryColor.withOpacity(0.6);
    }
    return theme.dividerColor.withOpacity(0.5);
  }

  void _handleShare() {
    final text = _formatAyahForSharing();
    _showSnackBar('Paylaş özelliği yakında', Colors.blue);
    Clipboard.setData(ClipboardData(text: text));
  }

  void _handleCopy() {
    final text = _formatAyahForSharing();
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    _showSnackBar('Panoya kopyalandı', Colors.green);
  }

  String _formatAyahForSharing() {
    return '''${widget.ayet.arabic}

${widget.ayet.turkish.isNotEmpty ? widget.ayet.turkish : ''}

(${widget.ayet.surahNumber}:${widget.ayet.number})''';
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}