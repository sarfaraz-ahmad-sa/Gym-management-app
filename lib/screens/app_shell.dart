import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/entities.dart';
import '../core/format.dart';
import '../core/gym_store.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';
import '../widgets/record_editor.dart';
import 'attendance_screen.dart';
import 'member_detail_screen.dart';
import 'messages_screen.dart';
import 'overview_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'fees_screen.dart';
import '../widgets/workspace_logo.dart';

const navigation = [
  ('overview', 'Overview', Icons.space_dashboard_outlined),
  ('members', 'Members', Icons.people_outline_rounded),
  ('attendance', 'Attendance', Icons.event_available_outlined),
  ('membership_plans', 'Memberships', Icons.workspace_premium_outlined),
  ('fees', 'Fees & dues', Icons.receipt_long_outlined),
  ('payments', 'Payments', Icons.account_balance_wallet_outlined),
  ('trainers', 'Trainers', Icons.sports_gymnastics_rounded),
  ('workout_plans', 'Workouts', Icons.auto_awesome_outlined),
  ('inventory_items', 'Equipment', Icons.fitness_center_rounded),
  ('messages', 'Messages', Icons.chat_bubble_outline_rounded),
  ('settings', 'Settings', Icons.settings_outlined),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final store = context.read<GymStore>();
      if (store.isCloud) store.load();
    }
  }

  String _selected = 'overview';
  final _scroll = ScrollController();
  final _scaffold = GlobalKey<ScaffoldState>();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  void _navigate(String key) {
    setState(() => _selected = key);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Widget _content() => switch (_selected) {
    'overview' => OverviewScreen(navigate: _navigate),
    'attendance' => const AttendanceScreen(),
    'messages' => const MessagesScreen(),
    'settings' => const SettingsScreen(),
    'fees' => const FeesScreen(),
    _ => RecordsScreen(key: ValueKey(_selected), table: _selected),
  };
  @override
  Widget build(BuildContext context) {
    final store = context.watch<GymStore>();
    final auth = context.watch<AuthService>();
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1100;
    final rail = width >= 760;
    final scheme = Theme.of(context).colorScheme;
    if (store.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (store.error != null) {
      return Scaffold(
        body: EmptyState(
          title: 'Let’s try that again',
          message: store.error!,
          action: FilledButton(
            onPressed: store.load,
            child: const Text('Retry'),
          ),
        ),
      );
    }
    return Scaffold(
      key: _scaffold,
      drawer: rail
          ? null
          : Drawer(
              child: SafeArea(child: _sidebar(store, auth, true, drawer: true)),
            ),
      bottomNavigationBar: rail
          ? null
          : NavigationBar(
              selectedIndex:
                  [
                            'overview',
                            'members',
                            'attendance',
                          ].indexOf(_selected).clamp(0, 2) ==
                          0 &&
                      _selected != 'overview'
                  ? 3
                  : [
                      'overview',
                      'members',
                      'attendance',
                    ].indexOf(_selected).clamp(0, 2),
              onDestinationSelected: (i) {
                if (i == 3) {
                  _scaffold.currentState!.openDrawer();
                } else {
                  _navigate(['overview', 'members', 'attendance'][i]);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Members',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_available_outlined),
                  label: 'Attendance',
                ),
                NavigationDestination(icon: Icon(Icons.menu), label: 'More'),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (rail)
              Container(
                width: desktop ? 238 : 86,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .5),
                    ),
                  ),
                ),
                child: _sidebar(store, auth, desktop),
              ),
            Expanded(
              child: Column(
                children: [
                  _topbar(store, auth, rail),
                  if (auth.demo)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 9,
                      ),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF392B10)
                          : const Color(0xFFFFF8E1),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 16,
                            color: AppTheme.amber,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Demo workspace • sample records, separate from your club.',
                              style: TextStyle(
                                fontSize: width < 600 ? 10 : 12,
                                color: AppTheme.amber,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: auth.logout,
                            child: const Text('Exit demo'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: store.load,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: Padding(
                              padding: EdgeInsets.all(width < 600 ? 18 : 30),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: KeyedSubtree(
                                  key: ValueKey(_selected),
                                  child: _content(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar(
    GymStore store,
    AuthService auth,
    bool expanded, {
    bool drawer = false,
  }) => Column(
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(
          expanded ? 22 : 20,
          28,
          expanded ? 12 : 20,
          30,
        ),
        child: Brand(compact: !expanded),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                WorkspaceLogo(data: store.setting('gym_logo'), size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.gymName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner workspace',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 22),
      Expanded(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 14),
          children: [
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 0, 12),
                child: Text(
                  'WORKSPACE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final item in navigation)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Tooltip(
                  message: expanded ? '' : item.$2,
                  child: Material(
                    color: _selected == item.$1
                        ? AppTheme.blue.withValues(alpha: .1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        if (drawer) Navigator.pop(context);
                        _navigate(item.$1);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: expanded ? 17 : 14,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: expanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.$3,
                              size: 21,
                              color: _selected == item.$1
                                  ? AppTheme.blue
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            if (expanded) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _selected == item.$1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selected == item.$1
                                        ? AppTheme.blue
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (item.$1 == 'members' &&
                                  store.rows('members').isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${store.rows('members').length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.blue,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const Divider(),
      Padding(
        padding: EdgeInsets.all(expanded ? 20 : 18),
        child: expanded
            ? Row(
                children: [
                  PersonAvatar(auth.ownerName, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.ownerName,
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Club owner',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout, size: 18),
                  ),
                ],
              )
            : IconButton(
                tooltip: 'Sign out',
                onPressed: auth.logout,
                icon: const Icon(Icons.logout, size: 20),
              ),
      ),
    ],
  );
  Widget _topbar(GymStore store, AuthService auth, bool rail) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: rail ? 30 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!rail) ...[
            WorkspaceLogo(data: store.setting('gym_logo'), size: 38),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              _selected == 'overview'
                  ? store.gymName
                  : navigation.firstWhere((n) => n.$1 == _selected).$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (width > 1000) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _search(store),
              child: Container(
                width: 250,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 19),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search your workspace',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),
          ] else
            IconButton(
              tooltip: 'Search workspace',
              onPressed: () => _search(store),
              icon: const Icon(Icons.search, size: 21),
            ),
          if (width >= 500)
            IconButton(
              tooltip: 'Refresh records',
              onPressed: store.load,
              icon: const Icon(Icons.refresh, size: 21),
            ),
          if (width >= 390)
            IconButton(
              tooltip: 'Toggle appearance',
              onPressed: context.read<ThemeController>().toggle,
              icon: Icon(
                context.watch<ThemeController>().dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 21,
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Workspace options',
              onSelected: (value) {
                if (value == 'theme') {
                  context.read<ThemeController>().toggle();
                } else {
                  store.load();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'theme', child: Text('Toggle appearance')),
                PopupMenuItem(value: 'refresh', child: Text('Refresh records')),
              ],
            ),
          IconButton(
            tooltip: 'Membership follow-ups',
            onPressed: () => _alerts(store),
            icon: Badge(
              isLabelVisible:
                  store.expiring.isNotEmpty || store.overdue.isNotEmpty,
              smallSize: 6,
              child: const Icon(Icons.notifications_none_rounded, size: 23),
            ),
          ),
          if (width >= 500) ...[
            const SizedBox(width: 12),
            PersonAvatar(auth.ownerName, size: 34),
          ],
        ],
      ),
    );
  }

  Future<void> _search(GymStore store) async {
    final hit = await showSearch<SearchHit?>(
      context: context,
      delegate: WorkspaceSearch(store),
    );
    if (hit == null || !mounted) return;
    if (hit.spec.table == 'members') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: store,
            child: MemberDetailScreen(memberId: hit.record['id'] as int),
          ),
        ),
      );
    } else {
      editRecord(context, store, hit.spec, record: hit.record);
    }
  }

  void _alerts(GymStore store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Membership follow-ups'),
        content: SizedBox(
          width: 420,
          child: [...store.overdue, ...store.expiring].isEmpty
              ? const Text('No renewals due in the next 7 days.')
              : ListView(
                  shrinkWrap: true,
                  children: [...store.overdue, ...store.expiring]
                      .map(
                        (m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PersonAvatar(m['name'] as String),
                          title: Text(m['name'] as String),
                          subtitle: Text(
                            '${titleCase(store.memberStatus(m))} • ${dateLabel(m['expiry_date'])}',
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: store,
                                  child: MemberDetailScreen(
                                    memberId: m['id'] as int,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class SearchHit {
  const SearchHit(this.spec, this.record);
  final EntitySpec spec;
  final RecordData record;
}

class WorkspaceSearch extends SearchDelegate<SearchHit?> {
  WorkspaceSearch(this.store)
    : super(searchFieldLabel: 'Search members, payments, trainers…');
  final GymStore store;
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: 'Clear search',
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final hits = <SearchHit>[];
    for (final spec in entities.values) {
      for (final row in store.rows(spec.table)) {
        final text = spec.fields
            .map((f) => recordValue(store, spec, row, f.key))
            .join(' ');
        if (text.toLowerCase().contains(query.toLowerCase().trim())) {
          hits.add(SearchHit(spec, row));
        }
      }
    }
    if (hits.isEmpty) {
      return const EmptyState(
        title: 'No matches',
        message: 'Try a member name, phone number or payment reference.',
      );
    }
    return ListView.builder(
      itemCount: hits.take(40).length,
      itemBuilder: (ctx, i) {
        final hit = hits[i];
        return ListTile(
          leading: Icon(hit.spec.icon, color: AppTheme.blue),
          title: Text(
            hit.record['name'] as String? ??
                store.label('members', hit.record['member_id']),
          ),
          subtitle: Text('${hit.spec.title} • #${hit.record['id']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => close(context, hit),
        );
      },
    );
  }
}
