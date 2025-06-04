import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/kuran_provider.dart';
import '../models/ayet_model.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/audio_manager.dart';

class AyetItem extends StatefulWidget {
  final AyetModel ayet;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlayPressed;
  final bool showArabic;
  final bool showTranslation;
  final bool showAyahNumber;
  final EdgeInsets? margin;
  final bool enableAnimations;

  const AyetItem({
    super.key,
    required this.ayet,
    this.isPlaying = false,
    this.isSelected = false,
    required this.onTap,
    required this.onPlayPressed,
    this.showArabic = true,
    this.showTranslation = true,
    this.showAyahNumber = true,
    this.margin,
    this.enableAnimations = true,
  });

  @override
  State<AyetItem> createState() => _AyetItemState();
}

class _AyetItemState extends State<AyetItem>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  bool get wantKeepAlive => true; // ListView performansı için

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    if (!widget.enableAnimations) return;

    _animationController = AnimationController(
      duration: AppConstants.fastAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppColors.primary.withOpacity(0.1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    if (widget.enableAnimations) {
      _animationController.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enableAnimations) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enableAnimations) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    if (!widget.enableAnimations) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    if (!widget.enableAnimations) return;
    setState(() => _isHovered = true);
    _animationController.forward();
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (!widget.enableAnimations) return;
    setState(() => _isHovered = false);
    if (!_isPressed) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli

    final provider = Provider.of<KuranProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (!widget.enableAnimations) {
      return _buildStaticItem(context, provider, theme);
    }

    return _buildAnimatedItem(context, provider, theme);
  }

  Widget _buildStaticItem(BuildContext context, KuranProvider provider, ThemeData theme) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
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
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _buildContent(context, provider, theme),
      ),
    );
  }

  Widget _buildAnimatedItem(BuildContext context, KuranProvider provider, ThemeData theme) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: MouseRegion(
        onEnter: _handleMouseEnter,
        onExit: _handleMouseExit,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAnimatedBackgroundColor(theme),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBorderColor(theme),
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.2),
                      blurRadius: _elevationAnimation.value,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildContent(context, provider, theme),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, KuranProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showArabic) _buildArabicText(theme, provider),

        if (widget.showTranslation &&
            provider.translationGoster &&
            widget.ayet.turkish.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTranslationText(theme),
        ],

        if (widget.isSelected) ...[
          const SizedBox(height: 16),
          _buildActionButtons(theme, provider),
        ],
      ],
    );
  }

  Widget _buildArabicText(ThemeData theme, KuranProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            const TextSpan(text: '  '),
            if (widget.showAyahNumber) _buildAyahNumberSpan(theme),
          ],
        ),
      ),
    );
  }

  WidgetSpan _buildAyahNumberSpan(ThemeData theme) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isPlaying ? Colors.green : theme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${widget.ayet.number}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationText(ThemeData theme) {
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      padding: const EdgeInsets.all(12),
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
            : AppStrings.loading,
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

  Widget _buildActionButtons(ThemeData theme, KuranProvider provider) {
    final isBookmarked = provider.isBookmarked(widget.ayet.bookmarkKey);

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView( // Yatay scroll eklendi
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
              label: widget.isPlaying ? AppStrings.pause : AppStrings.play,
              onPressed: widget.onPlayPressed,
              color: theme.primaryColor,
              tooltip: widget.isPlaying ? AppStrings.tooltipPause : AppStrings.tooltipPlay,
            ),
            const SizedBox(width: 8), // Butonlar arası boşluk
            _buildActionButton(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: isBookmarked ? AppStrings.bookmarkRemove : AppStrings.bookmarkAdd,
              onPressed: () => _handleBookmarkToggle(provider, isBookmarked),
              color: isBookmarked ? Colors.red : theme.primaryColor,
              tooltip: AppStrings.tooltipBookmark,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.share,
              label: AppStrings.share,
              onPressed: _handleShare,
              color: theme.primaryColor,
              tooltip: AppStrings.tooltipShare,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.copy,
              label: AppStrings.copy,
              onPressed: _handleCopy,
              color: theme.primaryColor,
              tooltip: AppStrings.tooltipCopy,
            ),
            const SizedBox(width: 8), // Sağ boşluk
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
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
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
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.isPlaying) {
      return theme.primaryColor.withOpacity(0.15);
    } else if (widget.isSelected) {
      return theme.primaryColor.withOpacity(0.08);
    } else if (_isHovered) {
      return AppColors.hoveredAyah.withOpacity(0.1);
    }
    return AppColors.getCardColor(context);
  }

  Color _getAnimatedBackgroundColor(ThemeData theme) {
    Color baseColor = _getBackgroundColor(theme);
    if (widget.enableAnimations && _colorAnimation.value != null) {
      return Color.lerp(baseColor, _colorAnimation.value!, 0.3) ?? baseColor;
    }
    return baseColor;
  }

  Color _getBorderColor(ThemeData theme) {
    if (widget.isSelected || _isHovered) {
      return theme.primaryColor;
    }
    return theme.dividerColor;
  }

  void _handleBookmarkToggle(KuranProvider provider, bool isCurrentlyBookmarked) {
    provider.toggleYerIsareti(widget.ayet.bookmarkKey);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show snackbar
    final message = isCurrentlyBookmarked
        ? AppStrings.bookmarkRemoved
        : AppStrings.bookmarkAdded;
    _showSnackBar(message, isCurrentlyBookmarked ? Colors.orange : Colors.green);
  }

  void _handleShare() {
    final text = _formatAyahForSharing();

    // Share functionality burada implement edilebilir
    // share_plus paketi kullanılabilir
    _showSnackBar('${AppStrings.shareApp} - Yakında', Colors.blue);

    // Şimdilik clipboard'a kopyala
    Clipboard.setData(ClipboardData(text: text));
  }

  void _handleCopy() {
    final text = _formatAyahForSharing();
    Clipboard.setData(ClipboardData(text: text));

    // Haptic feedback
    HapticFeedback.selectionClick();

    _showSnackBar(AppStrings.copied, Colors.green);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

/// Optimized Ayah Item for ListView performance
class AyetItemOptimized extends StatelessWidget {
  final AyetModel ayet;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPlayPressed;
  final KuranProvider provider;

  const AyetItemOptimized({
    super.key,
    required this.ayet,
    required this.isPlaying,
    required this.isSelected,
    required this.onTap,
    required this.onPlayPressed,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withOpacity(0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: theme.primaryColor, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          ayet.arabic,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: provider.arabicFontSize,
            fontFamily: 'UthmanicHafs',
            color: isPlaying ? theme.primaryColor : null,
            fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: provider.translationGoster && ayet.turkish.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            ayet.turkish,
            style: TextStyle(
              fontSize: 14,
              color: theme.primaryColor.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isPlaying ? Colors.green : theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${ayet.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: theme.primaryColor,
              ),
              onPressed: onPlayPressed,
              tooltip: isPlaying ? AppStrings.pause : AppStrings.play,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}