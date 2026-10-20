import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/rt_loader.dart';
import '../../data/models/models.dart';

/// Interactive modal bottom sheet for collecting and editing customer reviews.
/// Enforces all validation constraints:
/// - rates: 1 to 5
/// - comment: non-empty string
/// - bookingType: 'service' or 'product'
/// - Auto content label computed server/client side:
///   • 4 or 5 ➔ "Excellent"
///   • 3 ➔ "Good"
///   • 2 ➔ "Average"
///   • 1 ➔ "Below Average"
Future<bool?> showReviewBottomSheet(
  BuildContext context, {
  required String bookingId,
  required String serviceTitle,
  String? technicianName,
  String bookingType = 'service',
  int initialRating = 5,
  String initialComment = '',
  bool isEditing = false,
  required Future<bool> Function(int rates, String comment) onSubmit,
}) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _ReviewSheetContent(
      bookingId: bookingId,
      serviceTitle: serviceTitle,
      technicianName: technicianName,
      bookingType: bookingType,
      initialRating: initialRating.clamp(1, 5),
      initialComment: initialComment,
      isEditing: isEditing,
      onSubmit: onSubmit,
    ),
  );
}

class _ReviewSheetContent extends StatefulWidget {
  final String bookingId;
  final String serviceTitle;
  final String? technicianName;
  final String bookingType;
  final int initialRating;
  final String initialComment;
  final bool isEditing;
  final Future<bool> Function(int rates, String comment) onSubmit;

  const _ReviewSheetContent({
    required this.bookingId,
    required this.serviceTitle,
    this.technicianName,
    this.bookingType = 'service',
    this.initialRating = 5,
    this.initialComment = '',
    this.isEditing = false,
    required this.onSubmit,
  });

  @override
  State<_ReviewSheetContent> createState() => _ReviewSheetContentState();
}

class _ReviewSheetContentState extends State<_ReviewSheetContent> {
  late int _rating;
  late final TextEditingController _commentCtrl;
  final List<String> _selectedTags = [];
  bool _submitting = false;
  String? _commentError;

  final List<String> _serviceTags = const [
    'On Time',
    'Polite & Respectful',
    'Great Work Quality',
    'Cleaned Up Afterward',
    'Fair Pricing',
    'Quick Service',
  ];

  final List<String> _productTags = const [
    'Genuine Parts',
    'High Durability',
    'Perfect Fit',
    'Great Price',
    'Fast Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(1, 5);
    _commentCtrl = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
        // If comment is empty or short, suggest this tag in the comment box
        final cur = _commentCtrl.text.trim();
        if (cur.isEmpty) {
          _commentCtrl.text = tag;
        } else if (!cur.contains(tag)) {
          _commentCtrl.text = '$cur, $tag';
        }
        _commentError = null;
      }
    });
  }

  String get _contentLabel => RatingModel.computeContent(_rating);

  Color get _contentLabelColor {
    switch (_rating) {
      case 5:
      case 4:
        return const Color(0xFF16A34A); // Emerald
      case 3:
        return const Color(0xFFD97706); // Amber
      case 2:
        return const Color(0xFFEA580C); // Orange
      case 1:
      default:
        return const Color(0xFFDC2626); // Red
    }
  }

  Color get _contentLabelBg {
    switch (_rating) {
      case 5:
      case 4:
        return const Color(0xFFECFDF5);
      case 3:
        return const Color(0xFFFFFBEB);
      case 2:
        return const Color(0xFFFFF7ED);
      case 1:
      default:
        return const Color(0xFFFEF2F2);
    }
  }

  Future<void> _submit() async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      setState(() {
        _commentError = 'Please share a brief comment about your experience.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _commentError = null;
    });

    final success = await widget.onSubmit(_rating, comment);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Rating updated successfully!'
                : 'Thank you! Your rating has been submitted.',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isProduct = widget.bookingType == 'product';
    final availableTags = isProduct ? _productTags : _serviceTags;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title
            Text(
              widget.isEditing
                  ? 'Edit Your Review'
                  : (isProduct ? 'Rate Your Equipment / Product' : 'How was your service?'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.technicianName != null && widget.technicianName!.isNotEmpty
                  ? '${widget.serviceTitle} • ${widget.technicianName}'
                  : widget.serviceTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),

            // Interactive Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final filled = starIndex <= _rating;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = starIndex);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedScale(
                      scale: filled ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: filled ? const Color(0xFFF59E0B) : AppColors.grey300,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Auto Content Label Pill (Server matches: Excellent, Good, Average, Below Average)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _contentLabelBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _contentLabelColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$_contentLabel ($_rating of 5)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _contentLabelColor,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tag Pills for quick highlights
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag),
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.grey50,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.grey700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryBorder : AppColors.grey200,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Comments Box (Required per validation constraint)
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              onChanged: (_) {
                if (_commentError != null) {
                  setState(() => _commentError = null);
                }
              },
              decoration: InputDecoration(
                hintText: isProduct
                    ? 'Write your feedback on the product performance, delivery, quality...'
                    : 'Write your feedback on service quality, punctuality, satisfaction...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.grey400),
                contentPadding: const EdgeInsets.all(14),
                errorText: _commentError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Helpful note regarding 1 rating per booking rule
            Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.grey500),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '1 review per booking. You can edit or delete this review anytime in My Ratings.',
                    style: TextStyle(fontSize: 11, color: AppColors.grey500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit / Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const RtLoader.button(color: Colors.white)
                    : Text(
                        widget.isEditing ? 'Update Review' : 'Submit Review',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
