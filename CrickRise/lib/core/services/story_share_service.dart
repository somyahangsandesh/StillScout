import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sunday_story.dart';
import '../theme/app_theme.dart';

enum SharePlatform { whatsapp, instagram, facebook, copyLink, more }

class StoryShareService {
  StoryShareService._();

  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  static Future<void> shareStory({
    required SundayStory story,
    required SharePlatform platform,
    Uint8List? imageBytes,
  }) async {
    final caption = switch (platform) {
      SharePlatform.whatsapp => story.whatsappCaption(),
      SharePlatform.instagram => story.instagramCaption(),
      SharePlatform.facebook => story.facebookCaption(),
      SharePlatform.copyLink => '${story.shareUrl}\n\n${story.whatsappCaption()}',
      SharePlatform.more => story.whatsappCaption(),
    };

    if (platform == SharePlatform.copyLink) {
      await Clipboard.setData(ClipboardData(text: caption));
      return;
    }

    if (imageBytes != null) {
      final file = XFile.fromData(
        imageBytes,
        name: 'sunday-story-${story.storyNumber}.png',
        mimeType: 'image/png',
      );
      await Share.shareXFiles(
        [file],
        text: caption,
        subject: 'Sunday Story · ${story.squadName}',
      );
      return;
    }

    await Share.share(caption, subject: 'Sunday Story · ${story.squadName}');
  }

  static void showShareSheet(
    BuildContext context, {
    required SundayStory story,
    required GlobalKey cardKey,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CR.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => _ShareSheet(story: story, cardKey: cardKey),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  final SundayStory story;
  final GlobalKey cardKey;

  const _ShareSheet({required this.story, required this.cardKey});

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  bool _busy = false;

  Future<void> _share(SharePlatform platform) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await StoryShareService.captureWidget(widget.cardKey);
      await StoryShareService.shareStory(
        story: widget.story,
        platform: platform,
        imageBytes: bytes,
      );
      if (!mounted) return;
      if (platform == SharePlatform.copyLink) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link & caption copied', style: CRType.body(size: 14)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: CR.cardHigh,
          ),
        );
      }
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: CR.chalk.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Share Sunday Story', style: CRType.headline(size: 20)),
          const SizedBox(height: 6),
          Text(
            'WhatsApp · Instagram · Facebook & more',
            style: CRType.caption(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Target(
                emoji: '💬',
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _share(SharePlatform.whatsapp),
              ),
              _Target(
                emoji: '📸',
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => _share(SharePlatform.instagram),
              ),
              _Target(
                emoji: '👥',
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => _share(SharePlatform.facebook),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _share(SharePlatform.copyLink),
                  child: const Text('COPY LINK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : () => _share(SharePlatform.more),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: Text(_busy ? '...' : 'MORE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Target extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Target({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 8),
          Text(label, style: CRType.overline(size: 8, color: CR.ink)),
        ],
      ),
    );
  }
}
