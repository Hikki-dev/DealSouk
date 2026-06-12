import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealsouk/features/tokens/domain/token_transaction.dart';
import 'package:dealsouk/features/tokens/domain/streak_data.dart';
import 'package:dealsouk/features/tokens/domain/user_badge.dart';
import 'package:dealsouk/features/tokens/domain/daily_challenge.dart';
import 'package:dealsouk/features/tokens/data/challenges_service.dart';
import 'package:dealsouk/features/profile/data/profile_service.dart';

class UserTokensNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void sync(int balance) => state = balance;

  void addTokens(int amount) => state = state + amount;

  void deductTokens(int amount) => state = state - amount;
}

final userTokensProvider = NotifierProvider<UserTokensNotifier, int>(
  UserTokensNotifier.new,
);

class UserTransactionsNotifier extends Notifier<List<TokenTransaction>> {
  @override
  List<TokenTransaction> build() => [];

  Future<void> fetch() async {
    try {
      final results = await profileService.getTransactions();
      state = results;
    } catch (_) {}
  }

  void addTransaction(int amount, String title) {
    final newTx = TokenTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      title: title,
      timestampLabel: 'Just now',
    );
    state = [newTx, ...state];
  }
}

final userTransactionsProvider =
    NotifierProvider<UserTransactionsNotifier, List<TokenTransaction>>(
      UserTransactionsNotifier.new,
    );

class StreakNotifier extends Notifier<StreakData> {
  @override
  StreakData build() => const StreakData(
    currentStreak: 0,
    longestStreak: 0,
    lastActivityLabel: '—',
  );

  void sync(int current, int longest) {
    state = StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActivityLabel: 'Today',
    );
  }

  void recordActivity() {
    final current = state;
    final newStreak = current.currentStreak + 1;
    final longest = newStreak > current.longestStreak
        ? newStreak
        : current.longestStreak;
    state = current.copyWith(
      currentStreak: newStreak,
      longestStreak: longest,
      lastActivityLabel: 'Just now',
    );
    ref.read(badgesProvider.notifier).checkAndUnlock('streak_$newStreak');
  }
}

final streakProvider = NotifierProvider<StreakNotifier, StreakData>(
  StreakNotifier.new,
);

class BadgesNotifier extends Notifier<List<UserBadge>> {
  @override
  List<UserBadge> build() => const [
    UserBadge(
      id: 'first_submission',
      name: 'First Price',
      emoji: '🏷️',
      description: 'Submit your first price',
      unlocked: false,
    ),
    UserBadge(
      id: 'streak_7',
      name: '7-Day Streak',
      emoji: '🔥',
      description: 'Submit 7 days in a row',
      unlocked: false,
    ),
    UserBadge(
      id: 'streak_30',
      name: 'Monthly Regular',
      emoji: '📅',
      description: '30-day submission streak',
      unlocked: false,
    ),
    UserBadge(
      id: 'first_request',
      name: 'Price Detective',
      emoji: '🔍',
      description: 'Fulfill your first price request',
      unlocked: false,
    ),
    UserBadge(
      id: 'accuracy_90',
      name: 'Trusted Shopper',
      emoji: '✅',
      description: 'Maintain 90%+ accuracy rating',
      unlocked: false,
    ),
    UserBadge(
      id: 'voucher_earned',
      name: 'Voucher Winner',
      emoji: '🎁',
      description: 'Earn your first voucher',
      unlocked: false,
    ),
  ];

  void checkAndUnlock(String event) {
    final updated = state.map((badge) {
      if (badge.unlocked) return badge;
      if (event == 'submission_approved' && badge.id == 'first_submission') {
        return badge.copyWith(unlocked: true);
      }
      if (event.startsWith('streak_')) {
        final streakCount = int.tryParse(event.split('_').last) ?? 0;
        if (badge.id == 'streak_7' && streakCount >= 7) {
          return badge.copyWith(unlocked: true);
        }
        if (badge.id == 'streak_30' && streakCount >= 30) {
          return badge.copyWith(unlocked: true);
        }
      }
      if (event == 'request_fulfilled' && badge.id == 'first_request') {
        return badge.copyWith(unlocked: true);
      }
      return badge;
    }).toList();
    state = updated;
  }
}

final badgesProvider = NotifierProvider<BadgesNotifier, List<UserBadge>>(
  BadgesNotifier.new,
);

class DailyChallengeNotifier extends Notifier<DailyChallenge> {
  @override
  DailyChallenge build() => const DailyChallenge(
    id: 'daily_1',
    description: 'Submit 3 fresh prices today',
    targetStore: 'Any',
    targetCount: 3,
    bonusTokens: 30,
  );

  Future<void> fetchToday() async {
    try {
      state = await challengesService.getToday();
    } catch (_) {}
  }

  void recordProgress() {
    if (state.completed) return;
    final newCount = state.progressCount + 1;
    final completed = newCount >= state.targetCount;
    state = state.copyWith(progressCount: newCount, completed: completed);

    if (completed) {
      ref.read(userTokensProvider.notifier).addTokens(state.bonusTokens);
      ref
          .read(userTransactionsProvider.notifier)
          .addTransaction(
            state.bonusTokens,
            'Daily challenge bonus: ${state.description}',
          );
    }
  }
}

final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallenge>(
      DailyChallengeNotifier.new,
    );

int tokensToLevel(int tokens) => (tokens ~/ 500).clamp(1, 20);
double levelMultiplier(int level) => 1.0 + (level - 1) * 0.05;
String levelTitle(int level) {
  if (level >= 15) return 'Souk Master';
  if (level >= 10) return 'Expert Sharer';
  if (level >= 5) return 'Active Sharer';
  if (level >= 3) return 'Regular Contributor';
  return 'New Contributor';
}
