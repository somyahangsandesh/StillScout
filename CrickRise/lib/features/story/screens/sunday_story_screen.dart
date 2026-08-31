import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/sunday_story.dart';
import '../../../core/providers/app_context_provider.dart';
import '../../../core/services/story_share_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';
import '../../../core/widgets/sunday_story_card.dart';

class SundayStoryScreen extends ConsumerStatefulWidget {
  final SundayStory? story;

  const SundayStoryScreen({super.key, this.story});

  @override
  ConsumerState<SundayStoryScreen> createState() => _SundayStoryScreenState();
}

class _SundayStoryScreenState extends ConsumerState<SundayStoryScreen> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(appContextProvider);
    final story = widget.story ?? SundayStory.sample(squad: ctx.squad);

    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                      icon: const Icon(Icons.arrow_back, color: CR.ink, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Sunday Story', style: CRType.headline(size: 20)),
                          Text('Ready to share', style: CRType.caption(size: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: SundayStoryCard(story: story, width: 300),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    CRProgrammeButton(
                      label: 'Share to WhatsApp, Instagram & more',
                      onTap: () => StoryShareService.showShareSheet(
                        context,
                        story: story,
                        cardKey: _cardKey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CRProgrammeButton(
                      label: 'Back to home',
                      primary: false,
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
