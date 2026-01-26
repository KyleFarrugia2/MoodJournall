import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import 'add_edit_journal_screen.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _chartTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadEntries();
      AnalyticsService.instance.logScreenView('home_screen');
      AnalyticsService.instance.logSessionStart();
      AnalyticsService.instance.testAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<JournalProvider>(
            builder: (context, journalProvider, child) {
              if (journalProvider.isLoading) {
                return Semantics(
                  label: 'Loading journal entries',
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final entries = journalProvider.entries;
              final todayEntries = journalProvider.todayEntries;
              final weekEntries = journalProvider.weekEntries;
              final averageMood = journalProvider.averageMoodThisWeek;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Semantics(
                        label: 'MoodJournal - Daily Journal and Mood Tracker',
                        header: true,
                        child: const Text(
                          'MoodJournal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      Semantics(
                        label: 'Firebase connection status',
                        child: Builder(
                          builder: (context) {
                            final isConnected =
                                AnalyticsService.instance.isConnected;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isConnected
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: isConnected ? Colors.green : Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      Semantics(
                        label: 'Test notification button',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.notifications_active),
                          onPressed: _testNotification,
                          tooltip: 'Test notification',
                        ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildMoodSummaryCard(
                          context, averageMood, todayEntries.length),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        debugPrint(
                            'Rendering weekly chart section with ${weekEntries.length} entries');
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: _buildWeeklyMoodChart(context, weekEntries),
                        );
                      },
                    ),
                  ),
                  if (todayEntries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Semantics(
                          label: 'Today\'s entries section',
                          header: true,
                          hint: 'List of journal entries created today',
                          child: Text(
                            "Today's Entries",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                  if (todayEntries.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: _buildJournalCard(
                              context,
                              todayEntries[index],
                              journalProvider,
                            ),
                          );
                        },
                        childCount: todayEntries.length,
                      ),
                    ),
                  if (entries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Semantics(
                          label: 'All entries section',
                          header: true,
                          hint: 'Complete list of all journal entries',
                          child: Text(
                            'All Entries',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    ),
                  if (entries.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = entries[index];
                          if (todayEntries.contains(entry)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: _buildJournalCard(
                              context,
                              entry,
                              journalProvider,
                            ),
                          );
                        },
                        childCount: entries.length,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Semantics(
        label: 'Create new journal entry',
        button: true,
        hint: 'Double tap to add a new journal entry',
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddEntry(context),
          icon: const Icon(Icons.add),
          label: const Text('New Entry'),
        ),
      ),
    );
  }

  Widget _buildMoodSummaryCard(
    BuildContext context,
    double averageMood,
    int todayEntryCount,
  ) {
    final moodEmoji = _getMoodEmoji(averageMood);
    final moodLabel = _getMoodLabel(averageMood);

    return Semantics(
      label:
          'Weekly mood summary: $moodLabel. $todayEntryCount ${todayEntryCount == 1 ? 'entry' : 'entries'} today',
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    moodEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Average',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      moodLabel,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$todayEntryCount ${todayEntryCount == 1 ? 'entry' : 'entries'} today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
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

  Widget _buildWeeklyMoodChart(
    BuildContext context,
    List<JournalEntry> weekEntries,
  ) {
    if (!_chartTracked && weekEntries.isNotEmpty) {
      AnalyticsService.instance.logChartViewed('weekly_mood_trend');
      _chartTracked = true;
    }

    debugPrint(
        'Building weekly mood chart with ${weekEntries.length} week entries');

    final Map<int, double?> dailyMoods = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dayEntries = weekEntries.where((e) {
        final entryDate = DateTime(
          e.entryDate.year,
          e.entryDate.month,
          e.entryDate.day,
        );
        return entryDate.year == date.year &&
            entryDate.month == date.month &&
            entryDate.day == date.day;
      }).toList();

      if (dayEntries.isNotEmpty) {
        final avg = dayEntries.fold<double>(
              0.0,
              (sum, e) => sum + e.mood.value,
            ) /
            dayEntries.length;
        dailyMoods[6 - i] = avg;
      } else {
        dailyMoods[6 - i] = null;
      }
    }

    final hasAnyData = dailyMoods.values.any((value) => value != null);
    debugPrint(
        'Weekly chart - hasAnyData: $hasAnyData, dailyMoods: $dailyMoods');

    return Semantics(
      label: hasAnyData
          ? 'Weekly mood trend chart showing mood over the past 7 days'
          : 'Weekly mood trend chart - no data available',
      child: Card(
        key: const ValueKey('weekly_mood_chart'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Weekly Mood Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (!hasAnyData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No entries in the last 7 days',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chartSpots = dailyMoods.entries
                        .where((e) => e.value != null)
                        .map((e) => FlSpot(e.key.toDouble(), e.value!))
                        .toList();

                    if (chartSpots.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return RepaintBoundary(
                      child: Container(
                        height: 200,
                        width: constraints.maxWidth > 0
                            ? constraints.maxWidth
                            : double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 200,
                        ),
                        child: LineChart(
                          LineChartData(
                            gridData:
                                FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final daysAgo = 6 - value.toInt();
                                    if (daysAgo < 0 || daysAgo > 6) {
                                      return const SizedBox.shrink();
                                    }
                                    final date =
                                        today.subtract(Duration(days: daysAgo));
                                    return Text(
                                      DateFormat('E').format(date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartSpots,
                                isCurved: true,
                                color: Theme.of(context).colorScheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                            minY: 0,
                            maxY: 4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCard(
    BuildContext context,
    JournalEntry entry,
    JournalProvider provider,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        label:
            'Journal entry: ${entry.title}. Mood: ${entry.mood.label}. Content: ${entry.content.length > 50 ? '${entry.content.substring(0, 50)}...' : entry.content}. Tap to edit',
        button: true,
        hint: 'Double tap to edit this journal entry',
        child: InkWell(
          onTap: () => _navigateToEditEntry(context, entry),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: entry.mood.colorValue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.mood.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(entry.entryDate),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Delete journal entry ${entry.title}',
                      button: true,
                      hint: 'Double tap to delete this entry',
                      child: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () =>
                            _showDeleteDialog(context, entry, provider),
                        tooltip: 'Delete entry',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.locationName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.locationName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue[600],
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: 'Journal icon',
            child: Icon(
              Icons.book,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'No entries yet message',
            child: Text(
              'No entries yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Instructions to start journaling',
            child: Text(
              'Start your journaling journey today!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(double value) {
    if (value < 0.5) return '😢';
    if (value < 1.5) return '😞';
    if (value < 2.5) return '😐';
    if (value < 3.5) return '🙂';
    return '😄';
  }

  String _getMoodLabel(double value) {
    if (value < 0.5) return 'Terrible';
    if (value < 1.5) return 'Bad';
    if (value < 2.5) return 'Okay';
    if (value < 3.5) return 'Good';
    return 'Excellent';
  }

  void _navigateToAddEntry(BuildContext context) {
    final provider = context.read<JournalProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditJournalScreen(),
      ),
    ).then((_) {
      if (mounted) {
        provider.loadEntries();
      }
    });
  }

  void _navigateToEditEntry(BuildContext context, JournalEntry entry) {
    if (entry.id != null) {
      AnalyticsService.instance.logJournalEntryViewed(entry.id!);
    }
    final provider = context.read<JournalProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJournalScreen(entry: entry),
      ),
    ).then((_) {
      if (mounted) {
        provider.loadEntries();
      }
    });
  }

  void _showDeleteDialog(
    BuildContext context,
    JournalEntry entry,
    JournalProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id!);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _testNotification() async {
    try {
      await AnalyticsService.instance.logNotificationTested();
      await NotificationService.instance.showInstantNotification(
        title: 'Daily Journal Reminder',
        body: 'Don\'t forget to write in your journal today!',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification not available: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
