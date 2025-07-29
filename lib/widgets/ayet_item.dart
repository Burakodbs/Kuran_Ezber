import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/ayet_model.dart';

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
  bool _showActions = false;
  DateTime? _lastPlayButtonPress;
  static const Duration _buttonDebounceDelay = Duration(milliseconds: 500);

  // Arapça rakamları
  static const Map<int, String> arabicNumbers = {
    0: '٠', 1: '١', 2: '٢', 3: '٣', 4: '٤',
    5: '٥', 6: '٦', 7: '٧', 8: '٨', 9: '٩'
  };

  String _convertToArabicNumber(int number) {
    return number.toString().split('').map((digit) {
      return arabicNumbers[int.parse(digit)] ?? digit;
    }).join('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RepaintBoundary(
      child: Selector<KuranProvider, bool>(
        selector: (context, provider) => provider.isBookmarked(widget.ayet.bookmarkKey),
        shouldRebuild: (previous, next) => previous != next,
        builder: (context, isBookmarked, _) {
          final provider = Provider.of<KuranProvider>(context, listen: false);
          return _buildAyetContent(theme, provider, isBookmarked);
        },
      ),
    );
  }

  Widget _buildAyetContent(ThemeData theme, KuranProvider provider, bool isBookmarked) {

    return Container(
      width: double.infinity, // Tam genişlik
      margin: const EdgeInsets.only(bottom: 6), // Satırlar arası minimal boşluk
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => setState(() => _showActions = !_showActions),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _getBackgroundColor(theme),
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected ? Border.all(
              color: theme.primaryColor,
              width: 1,
            ) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ana Arapça metin + Ayet numarası (tek satır)
              _buildArabicTextWithNumber(theme, provider),

              // Çeviri (varsa)
              if (provider.translationGoster && widget.ayet.turkish.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildTranslationText(theme),
              ],

              // Quick actions (sadece seçiliyse)
              if (_showActions) ...[
                const SizedBox(height: 6),
                _buildQuickActions(theme, provider, isBookmarked),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArabicTextWithNumber(ThemeData theme, KuranProvider provider) {
    return RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          maxLines: null,
          text: TextSpan(
            children: [
              // Arapça ayet metni
              TextSpan(
                text: widget.ayet.arabic,
                style: TextStyle(
                  fontSize: provider.arabicFontSize,
                  height: 1.8,
                  color: widget.isPlaying
                      ? theme.primaryColor
                      : theme.textTheme.bodyLarge?.color ?? Colors.black87,
                  fontWeight: widget.isPlaying ? FontWeight.w600 : FontWeight.w400,
                  fontFamily: 'UthmanicHafs',
                  wordSpacing: 3,
                  letterSpacing: 0.5,
                ),
              ),

              // Küçük boşluk
              const TextSpan(text: ' '),

              // Arapça ayet numarası - yuvarlak işaret
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildAyahNumberCircle(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahNumberCircle(ThemeData theme) {
    // Performans için static değerler cache'le
    final arabicNumber = _convertToArabicNumber(widget.ayet.number);
    final isPlaying = widget.isPlaying;
    
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
            // Ana çember
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPlaying
                      ? Colors.green.withValues(alpha: 0.7)
                      : theme.primaryColor.withValues(alpha: 0.6),
                  width: 1,
                ),
                color: isPlaying
                    ? Colors.green.withValues(alpha: 0.1)
                    : theme.primaryColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  arabicNumber,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPlaying
                        ? Colors.green.shade700
                        : theme.primaryColor,
                    fontFamily: 'UthmanicHafs',
                  ),
                ),
              ),
            ),

            // Oynatma göstergesi - küçük yeşil nokta
            if (isPlaying)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      );
  }

  Widget _buildTranslationText(ThemeData theme) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.ayet.turkish,
          style: TextStyle(
            fontSize: 11,
            color: theme.primaryColor.withValues(alpha: 0.8),
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, KuranProvider provider, bool isBookmarked) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickAction(
            icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: _handlePlayButtonPress,
            color: widget.isPlaying ? Colors.green : theme.primaryColor,
          ),
          _buildQuickAction(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            onPressed: () => provider.toggleYerIsareti(widget.ayet.bookmarkKey),
            color: isBookmarked ? Colors.red : theme.primaryColor,
          ),
          _buildQuickAction(
            icon: Icons.share_outlined,
            onPressed: _handleShare,
            color: theme.primaryColor,
          ),
          _buildQuickAction(
            icon: Icons.copy_outlined,
            onPressed: _handleCopy,
            color: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isPlaying) {
      return theme.primaryColor.withValues(alpha: 0.08);
    } else if (widget.isSelected) {
      return theme.primaryColor.withValues(alpha: 0.04);
    } else if (_showActions) {
      return theme.primaryColor.withValues(alpha: 0.02);
    }
    return Colors.transparent;
  }

  void _handleShare() {
    final text = _formatAyahForSharing();
    _showSnackBar('Paylaş özelliği yakında', Colors.blue);
    Clipboard.setData(ClipboardData(text: text));
  }

  void _handlePlayButtonPress() {
    final now = DateTime.now();
    if (_lastPlayButtonPress != null && 
        now.difference(_lastPlayButtonPress!) < _buttonDebounceDelay) {
      debugPrint('AyetItem: Debouncing rapid play button press');
      return;
    }
    
    _lastPlayButtonPress = now;
    widget.onPlayPressed();
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
        ),
      );
    }
  }
}