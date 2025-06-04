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
    required this.isPlaying,
    required this.isSelected,
    required this.onTap,
    required this.onPlayPressed,
  });

  @override
  _AyetItemState createState() => _AyetItemState();
}

class _AyetItemState extends State<AyetItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KuranProvider>(context);
    final isBookmarked = provider.isBookmarked(widget.ayet.bookmarkKey);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _animationController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _animationController.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(theme),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(theme),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: _isHovered || widget.isSelected
                  ? [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildArabicText(theme, provider),
                if (provider.translationGoster &&
                    widget.ayet.turkish.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildTranslationText(theme),
                ],
                if (widget.isSelected) ...[
                  SizedBox(height: 16),
                  _buildActionButtons(theme, provider, isBookmarked),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isPlaying) {
      return theme.primaryColor.withOpacity(0.15);
    } else if (widget.isSelected) {
      return theme.primaryColor.withOpacity(0.08);
    } else if (_isHovered) {
      return Colors.amber.withOpacity(0.1);
    }
    return theme.cardColor;
  }

  Color _getBorderColor(ThemeData theme) {
    if (widget.isSelected || _isHovered) {
      return theme.primaryColor;
    }
    return theme.dividerColor;
  }

  Widget _buildArabicText(ThemeData theme, KuranProvider provider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.ayet.arabic,
              style: TextStyle(
                fontSize: provider.arabicFontSize,
                height: 2.0,
                color: widget.isPlaying
                    ? theme.primaryColor
                    : theme.textTheme.bodyLarge?.color ?? Colors.black87,
                fontWeight: widget.isPlaying
                    ? FontWeight.w600
                    : FontWeight.w400,
                fontFamily: 'UthmanicHafs',
                wordSpacing: 4,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(text: '  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? Colors.green
                      : theme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.ayet.number}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationText(ThemeData theme) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Text(
        widget.ayet.turkish.isNotEmpty
            ? widget.ayet.turkish
            : 'Çeviri yükleniyor...',
        style: TextStyle(
          fontSize: 15,
          color: theme.primaryColor.withOpacity(0.9),
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, KuranProvider provider, bool isBookmarked) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
            label: widget.isPlaying ? 'Durdur' : 'Oynat',
            onPressed: widget.onPlayPressed,
            color: theme.primaryColor,
          ),
          _buildActionButton(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: isBookmarked ? 'Kaldır' : 'İşaretle',
            onPressed: () => provider.toggleYerIsareti(widget.ayet.bookmarkKey),
            color: isBookmarked ? Colors.red : theme.primaryColor,
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onPressed: () => _shareAyah(),
            color: theme.primaryColor,
          ),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Kopyala',
            onPressed: () => _copyAyah(),
            color: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAyah() {
    final text = '''
${widget.ayet.arabic}

${widget.ayet.turkish.isNotEmpty ? widget.ayet.turkish : ''}

(${widget.ayet.surahNumber}:${widget.ayet.number})
''';

    // Share functionality burada implement edilebilir
    // share_plus paketi kullanılabilir
    _showSnackBar('Paylaşım özelliği yakında eklenecek');
  }

  void _copyAyah() {
    final text = '''${widget.ayet.arabic}

${widget.ayet.turkish.isNotEmpty ? widget.ayet.turkish : ''}

(${widget.ayet.surahNumber}:${widget.ayet.number})''';

    // Clipboard'a kopyalama
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Ayet panoya kopyalandı');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}