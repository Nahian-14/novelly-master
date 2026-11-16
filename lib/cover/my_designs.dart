import 'package:flutter/material.dart';

import '../chat/chat_list.dart';
import '../main_page/discover.dart';
import '../main_page/novelly_bottom_navigation.dart';
import '../main_page/writer_profile.dart';
import '../theme/theme_controller.dart';
import 'cover_design.dart';
import 'cover_design_form.dart';
import 'cover_artist_profile.dart';

const _ink = Color(0xFF173B43);
const _gold = Color(0xFFC89543);
const _muted = Color(0xFF6E787A);
const _line = Color(0x1F173B43);
const _paper = Color(0xFFFAF7F2);

class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({
    this.covers = const [],
    this.drafts = const [],
    super.key, 
  });

  final List<CoverDesign> covers;
  final List<CoverDesign> drafts;

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  int _selectedTab = 0;
  late final CoverArtistWorkspace _workspace;

  bool get _canManageDesigns => WriterProfileScreen.currentUser.isCoverArtist;
  List<CoverDesign> get _selectedDesigns =>
      _selectedTab == 0 ? _workspace.covers : _workspace.drafts;

  @override
  void initState() {
    super.initState();
    final account = WriterProfileScreen.currentUser;
    _workspace = CoverArtistWorkspace.forAccount(
      account.accountId,
      initialCovers: widget.covers,
      initialDrafts: widget.drafts,
    );
  }

  Future<void> _addCover() async {
    final design = await showCoverDesignForm(
      context,
      creator: WriterProfileScreen.currentUser.name,
    );
    if (design == null || !mounted) return;
    setState(() {
      (design.isDraft ? _workspace.drafts : _workspace.covers).insert(
        0,
        design,
      );
    });
  }

  Future<void> _editCover(CoverDesign current) async {
    final design = await showCoverDesignForm(
      context,
      creator: WriterProfileScreen.currentUser.name,
      design: current,
    );
    if (design == null || !mounted) return;
    setState(() {
      final previousList = current.isDraft
          ? _workspace.drafts
          : _workspace.covers;
      previousList.remove(current);
      (design.isDraft ? _workspace.drafts : _workspace.covers).insert(
        0,
        design,
      );
    });
  }

  void _navigate(NovellyNavigationDestination destination) {
    handleNovellyNavigation(
      context: context,
      currentDestination: NovellyNavigationDestination.library,
      targetDestination: destination,
      coverDesigns: List.unmodifiable(_workspace.covers),
      coverDrafts: List.unmodifiable(_workspace.drafts),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageDesigns) {
      return Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: _muted, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'My Designs is only available to cover artists.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiscoverScreen(),
                      ),
                    ),
                    child: const Text('Back to Discover'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<NovellyThemeData>(
      valueListenable: NovellyThemeController.instance,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.paperColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradientColors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 600;
                  final horizontalPadding = (constraints.maxWidth * .05).clamp(
                    compact ? 16.0 : 20.0,
                    38.0,
                  );
                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            10,
                            horizontalPadding,
                            0,
                          ),
                          child: Column(
                            children: [
                              _header(compact),
                              SizedBox(height: compact ? 24 : 30),
                              _tabs(compact),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _designGrid(
                                  compact,
                                  _selectedDesigns,
                                  _selectedTab == 0
                                      ? 'No covers yet'
                                      : 'No drafts yet',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 7 : 10,
                          horizontalPadding,
                          compact ? 8 : 10,
                        ),
                        child: NovellyBottomNavigation(
                          libraryLabel: 'My Designs',
                          libraryIcon: Icons.palette_outlined,
                          selectedDestination:
                              NovellyNavigationDestination.library,
                          compact: compact,
                          onDestinationSelected: _navigate,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _designGrid(
    bool compact,
    List<CoverDesign> designs,
    String emptyMessage,
  ) {
    if (designs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _selectedTab == 0
                  ? Icons.palette_outlined
                  : Icons.drafts_outlined,
              color: const Color(0xFFC9BDA8),
              size: compact ? 48 : 58,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: _muted, fontSize: compact ? 15 : 18),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      itemCount: designs.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 3,
        crossAxisSpacing: compact ? 10 : 15,
        mainAxisSpacing: compact ? 10 : 15,
        childAspectRatio: .72,
      ),
      itemBuilder: (context, index) {
        final design = designs[index];
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE9E1D4)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CoverDesignArtwork(
                        design: design,
                        compact: compact,
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: PopupMenuButton<String>(
                        tooltip: 'Cover options',
                        onSelected: (action) {
                          if (action == 'edit') _editCover(design);
                          if (action == 'delete') {
                            setState(() => designs.remove(design));
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: _ink,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                child: Column(
                  children: [
                    Text(
                      design.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${design.author}${design.year.isEmpty ? '' : ' · ${design.year}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(bool compact) => Row(
    children: [
      Text(
        'My Designs',
        style: TextStyle(
          color: _ink,
          fontFamily: 'Georgia',
          fontSize: compact ? 28 : 34,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
      ),
      const Spacer(),
      Material(
        color: _gold,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Add cover',
          onPressed: _canManageDesigns ? _addCover : null,
          color: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    ],
  );

  Widget _tabs(bool compact) => Column(
    children: [
      Row(
        children: [
          for (var index = 0; index < 2; index++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedTab = index),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 11 : 14),
                  child: Text(
                    index == 0 ? 'All Covers' : 'Drafts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTab == index ? _gold : _ink,
                      fontSize: compact ? 15 : 18,
                      fontWeight: _selectedTab == index
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      SizedBox(
        height: 2,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: _line)),
            Align(
              alignment: _selectedTab == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: .5,
                child: ColoredBox(
                  color: _selectedTab == 0 ? _gold : _ink,
                  child: const SizedBox(height: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
