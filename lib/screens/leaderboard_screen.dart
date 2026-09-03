import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_choice_screen.dart';
import 'parents_screen.dart';

/// Couleur d'accent du classement — celle des pièces, pour l'associer aux
/// récompenses gagnées en jouant.
const _gold = AppColors.coin;

/// Classement des enfants ayant un compte, trié par points, avec un podium
/// pour le top 3. Les invités (progression locale uniquement) voient une
/// invitation à créer un compte.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<RemoteProfile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RemoteProfile>> _load() =>
      context.read<AuthService>().fetchLeaderboard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final progress = context.watch<ProgressService>();

    return Scaffold(
      backgroundColor: pastelOf(_gold),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _gold,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(dims.radiusLg)),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 8),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + dims.gapXs,
              left: dims.gapSm,
              right: dims.gapSm,
              bottom: dims.gapSm,
            ),
            child: Row(
              children: [
                const BackBubble(),
                Expanded(
                  child: Text(
                    'Classement 🏆',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Bouncy(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ParentsScreen()),
                  ),
                  child: Container(
                    width: dims.backBubble,
                    height: dims.backBubble,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_rounded,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: progress.isGuest ? const _GuestInvite() : _buildLeaderboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final myId = context.read<AuthService>().currentUser?.id;

    return RefreshIndicator(
      onRefresh: () async {
        final future = _load();
        setState(() => _future = future);
        await future;
      },
      child: FutureBuilder<List<RemoteProfile>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Message(
              emoji: '😅',
              text: 'Impossible de charger le classement.\nTire vers le bas pour réessayer.',
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const _Message(
              emoji: '🌱',
              text: 'Personne pour le moment.\nSois le premier du classement !',
            );
          }

          final podium = entries.take(3).toList();
          final rest = entries.skip(3).toList();
          final dims = context.dims;

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppDims.maxContentWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    dims.gapMd, dims.gapMd, dims.gapMd, dims.gapXl),
                children: [
                  _Podium(entries: podium, myId: myId),
                  if (rest.isNotEmpty) SizedBox(height: dims.gapLg),
                  for (var i = 0; i < rest.length; i++)
                    _RankRow(
                      entry: rest[i],
                      rank: i + 4,
                      isMe: rest[i].id == myId,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String emoji;
  final String text;

  const _Message({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dims.gapLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: dims.emojiLg)),
            SizedBox(height: dims.gapSm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.ink.withValues(alpha: .6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Podium du top 3 : 2ᵉ à gauche, 1ᵉʳ au centre (plus haut), 3ᵉ à droite —
/// comme un vrai podium de jeu.
class _Podium extends StatelessWidget {
  final List<RemoteProfile> entries;
  final String? myId;

  const _Podium({required this.entries, required this.myId});

  RemoteProfile? _at(int rank) =>
      entries.length >= rank ? entries[rank - 1] : null;

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final order = [2, 1, 3];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final rank in order)
          if (_at(rank) != null)
            Expanded(
              child: _PodiumStep(
                entry: _at(rank)!,
                rank: rank,
                isMe: _at(rank)!.id == myId,
              ),
            )
          else
            const Spacer(),
        SizedBox(width: dims.gapXs),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final RemoteProfile entry;
  final int rank;
  final bool isMe;

  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.isMe,
  });

  static const _colors = {
    1: Color(0xFFFFC94D),
    2: Color(0xFFC7CDD6),
    3: Color(0xFFE0A468),
  };
  static const _trophies = {1: '🥇', 2: '🥈', 3: '🥉'};
  static const _pedestalBaseHeights = {1: 92.0, 2: 66.0, 3: 50.0};

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final color = _colors[rank]!;
    final avatarSize = rank == 1 ? dims.s(64) : dims.s(52);
    final pedestalHeight = dims.s(_pedestalBaseHeights[rank]!);

    return Pop(
      delay: Duration(milliseconds: rank == 1 ? 0 : 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_trophies[rank]!, style: TextStyle(fontSize: dims.emojiMd)),
          SizedBox(height: dims.gapXxs),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: .5), blurRadius: 10),
              ],
            ),
            child: ProfileAvatar(avatar: entry.avatarUrl ?? '', size: avatarSize),
          ),
          SizedBox(height: dims.gapXxs),
          Text(
            entry.firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isMe ? darken(AppColors.coin) : AppColors.ink,
                ),
          ),
          Text(
            '${entry.points} pts',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: .55),
                ),
          ),
          SizedBox(height: dims.gapXs),
          Container(
            width: double.infinity,
            height: pedestalHeight,
            margin: EdgeInsets.symmetric(horizontal: dims.gapXxs),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(dims.radiusSm)),
              border: isMe ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 6),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RemoteProfile entry;
  final int rank;
  final bool isMe;

  const _RankRow({required this.entry, required this.rank, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return Container(
      margin: EdgeInsets.only(bottom: dims.gapSm),
      padding:
          EdgeInsets.symmetric(horizontal: dims.gapMd, vertical: dims.gapSm),
      decoration: BoxDecoration(
        color: isMe ? _gold.withValues(alpha: .18) : Colors.white,
        borderRadius: BorderRadius.circular(dims.radiusMd),
        border: isMe ? Border.all(color: _gold, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: dims.s(28),
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink.withValues(alpha: .5),
                  ),
            ),
          ),
          SizedBox(width: dims.gapSm),
          ProfileAvatar(avatar: entry.avatarUrl ?? '', size: dims.s(42)),
          SizedBox(width: dims.gapSm),
          Expanded(
            child: Text(
              entry.firstName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatChip(
            emoji: '⭐',
            value: '${entry.points}',
            background: AppColors.sand,
          ),
        ],
      ),
    );
  }
}

class _GuestInvite extends StatelessWidget {
  const _GuestInvite();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dims.gapLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: dims.emojiLg * 1.4)),
            SizedBox(height: dims.gapSm),
            Text(
              'Crée un compte pour rejoindre\nle classement et jouer avec tes amis !',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: dims.gapLg),
            PrimaryButton(
              label: 'CRÉER UN COMPTE',
              icon: Icons.rocket_launch_rounded,
              color: AppColors.correct,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
