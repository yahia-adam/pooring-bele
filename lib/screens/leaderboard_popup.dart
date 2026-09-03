import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_choice_screen.dart';

/// Ouvre le classement par-dessus l'écran courant, façon jeu : panneau de
/// verre translucide, le jeu reste visible (flouté) derrière.
///
/// [coinsEarned] et [pointsEarned] déclenchent la séquence de fin de partie :
/// les pièces récoltées volent une à une vers le compteur du panneau, puis
/// l'enfant est propulsé de son ancien rang jusqu'au nouveau.
Future<void> showLeaderboardPopup(
  BuildContext context, {
  int coinsEarned = 0,
  int pointsEarned = 0,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Classement',
    barrierColor: const Color(0x59101B26),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, _, _) => LeaderboardPopup(
      coinsEarned: coinsEarned,
      pointsEarned: pointsEarned,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .78, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Bouton des écrans de fin de partie : rouvre le classement en rejouant la
/// séquence (pièces qui s'accumulent, puis montée au nouveau rang).
class LeaderboardButton extends StatelessWidget {
  final int coinsEarned;
  final int pointsEarned;

  const LeaderboardButton({
    super.key,
    this.coinsEarned = 0,
    this.pointsEarned = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return Bouncy(
      onTap: () => showLeaderboardPopup(
        context,
        coinsEarned: coinsEarned,
        pointsEarned: pointsEarned,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dims.gapMd,
          vertical: dims.gapXs,
        ),
        decoration: BoxDecoration(
          color: AppColors.coin.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(dims.radiusLg),
          border: Border.all(
            color: AppColors.coin.withValues(alpha: .55),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: dims.emojiSm + 2)),
            SizedBox(width: dims.gapXs),
            Text(
              'VOIR LE CLASSEMENT',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: darken(AppColors.coin),
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Couleurs du panneau de verre : bleu nuit translucide, pour que le texte
/// blanc reste lisible quel que soit l'écran flouté derrière.
const _glassTop = Color(0xC22B3A4A);
const _glassBottom = Color(0xD216232F);

const _medalColors = {
  1: Color(0xFFFFC94D),
  2: Color(0xFFD7DEE7),
  3: Color(0xFFE0A468),
};
const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

enum _Status { loading, error, ready }

class LeaderboardPopup extends StatefulWidget {
  final int coinsEarned;
  final int pointsEarned;

  const LeaderboardPopup({
    super.key,
    this.coinsEarned = 0,
    this.pointsEarned = 0,
  });

  @override
  State<LeaderboardPopup> createState() => _LeaderboardPopupState();
}

class _LeaderboardPopupState extends State<LeaderboardPopup>
    with TickerProviderStateMixin {
  /// Part du contrôleur des pièces occupée par le vol d'une pièce : le
  /// reste sert à décaler les départs (les pièces s'égrènent).
  static const _flight = .5;

  final _scroll = ScrollController();
  final _panelKey = GlobalKey();
  final _chipKey = GlobalKey();

  late final AnimationController _coinsCtrl = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 420 + _coinCount * 90),
  );
  late final AnimationController _riseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );

  _Status _status = _Status.loading;
  List<RemoteProfile> _entries = const [];
  Map<String, int> _startIndex = const {};
  Map<String, int> _endIndex = const {};

  String? _myId;
  int _walletBefore = 0;
  int _landed = 0;
  Offset? _coinTarget;

  /// Déviation horizontale de chaque pièce, tirée une fois pour toutes :
  /// les trajectoires doivent rester identiques d'une frame à l'autre.
  late final List<double> _coinDrift;

  // Géométrie de la liste, fixée à chaque build et lue par les animations.
  double _rowH = 0;
  double _listH = 0;

  int get _coinCount => widget.coinsEarned <= 0
      ? 0
      : math.min(12, math.max(4, widget.coinsEarned));

  bool get _hasRise => widget.pointsEarned > 0;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _coinDrift = List.generate(12, (_) => rng.nextDouble() * 2 - 1);
    _myId = context.read<AuthService>().currentUser?.id;
    _walletBefore = context.read<ProgressService>().coins - widget.coinsEarned;
    _coinsCtrl.addListener(_onCoinTick);
    if (!_hasRise) _riseCtrl.value = 1;
    if (_myId == null) {
      _status = _Status.ready;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _coinsCtrl.dispose();
    _riseCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final progress = context.read<ProgressService>();
    final myId = _myId!;
    setState(() => _status = _Status.loading);
    try {
      final rows = await auth.fetchLeaderboard();
      if (!mounted) return;

      // Le score vient d'être poussé sans attendre (`unawaited`) : on force
      // la valeur locale, sinon le classement affiche l'ancien score juste
      // après une partie.
      final myPoints = progress.leaderboardPoints;
      final mine = rows.indexWhere((e) => e.id == myId);
      if (mine >= 0) {
        rows[mine] = rows[mine].copyWith(points: myPoints);
      } else {
        rows.add(RemoteProfile(
          id: myId,
          firstName: progress.name.isEmpty ? 'Moi' : progress.name,
          lastName: '',
          avatarUrl: progress.avatar,
          points: myPoints,
        ));
      }
      rows.sort((a, b) => b.points.compareTo(a.points));

      final endIndex = {for (var i = 0; i < rows.length; i++) rows[i].id: i};
      // Classement d'avant la partie : même liste, mais avec l'ancien score
      // de l'enfant — c'est de là que part l'animation de propulsion.
      final before = [...rows]..sort((a, b) {
          final pa = a.id == myId ? myPoints - widget.pointsEarned : a.points;
          final pb = b.id == myId ? myPoints - widget.pointsEarned : b.points;
          final byPoints = pb.compareTo(pa);
          return byPoints != 0
              ? byPoints
              : endIndex[a.id]!.compareTo(endIndex[b.id]!);
        });

      setState(() {
        _entries = rows;
        _endIndex = endIndex;
        _startIndex = {for (var i = 0; i < before.length; i++) before[i].id: i};
        _status = _Status.ready;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSequence());
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  // --- Séquence d'ouverture ------------------------------------------------

  void _startSequence() {
    if (!mounted || _entries.isEmpty) return;
    final myId = _myId;
    final from = myId == null ? null : _startIndex[myId];
    if (from != null && _scroll.hasClients) {
      _scroll.jumpTo(_offsetFor(from.toDouble()));
    }
    _measureCoinTarget();
    if (_coinCount > 0) {
      _coinsCtrl.forward().whenComplete(_propel);
    } else {
      _propel();
    }
  }

  void _propel() {
    if (!mounted || !_hasRise) return;
    final myId = _myId;
    final from = myId == null ? null : _startIndex[myId];
    final to = myId == null ? null : _endIndex[myId];
    if (from == null || to == null) return;
    if (from == to) {
      _riseCtrl.value = 1;
      return;
    }
    HapticFeedback.mediumImpact();
    _riseCtrl.addListener(_syncScroll);
    _riseCtrl.forward().whenComplete(() {
      if (mounted) HapticFeedback.lightImpact();
    });
  }

  /// La vue suit l'enfant pendant qu'il grimpe : on voit défiler les rangs
  /// qu'on double, comme dans les jeux de score.
  void _syncScroll() {
    if (!mounted || !_scroll.hasClients) return;
    final myId = _myId;
    final from = myId == null ? null : _startIndex[myId];
    final to = myId == null ? null : _endIndex[myId];
    if (from == null || to == null) return;
    final t = Curves.easeInOutCubic.transform(_riseCtrl.value);
    _scroll.jumpTo(_offsetFor(lerpDouble(from.toDouble(), to.toDouble(), t)!));
  }

  double _offsetFor(double index) {
    final max = math.max(0.0, _rowH * _entries.length - _listH);
    return (index * _rowH - (_listH - _rowH) / 2).clamp(0.0, max);
  }

  void _measureCoinTarget() {
    final panel = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    final chip = _chipKey.currentContext?.findRenderObject() as RenderBox?;
    if (panel == null || chip == null) return;
    final center =
        panel.globalToLocal(chip.localToGlobal(chip.size.center(Offset.zero)));
    setState(() => _coinTarget = center);
  }

  /// Avancement du vol de la pièce [i] (0 = pas partie, 1 = arrivée).
  double _coinT(int i, double t) {
    if (_coinCount <= 1) return (t / _flight).clamp(0.0, 1.0);
    final delay = (1 - _flight) * i / (_coinCount - 1);
    return ((t - delay) / _flight).clamp(0.0, 1.0);
  }

  void _onCoinTick() {
    var landed = 0;
    for (var i = 0; i < _coinCount; i++) {
      if (_coinT(i, _coinsCtrl.value) >= 1) landed++;
    }
    if (landed != _landed) {
      setState(() => _landed = landed);
      HapticFeedback.selectionClick();
    }
  }

  int get _displayedCoins {
    if (_coinCount == 0) return context.read<ProgressService>().coins;
    return _walletBefore + (widget.coinsEarned * _landed / _coinCount).round();
  }

  // --- Rendu ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    final size = MediaQuery.sizeOf(context);
    final panelWidth = math.min(400.0, size.width - dims.gapMd * 2);

    _rowH = dims.s(62);
    _listH = _entries.isEmpty
        ? 0
        : math.min(_rowH * _entries.length, size.height * .46);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Le jeu reste visible derrière, simplement flouté.
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: SizedBox(width: panelWidth, child: _panel(context)),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final dims = context.dims;
    return ClipRRect(
      borderRadius: BorderRadius.circular(dims.radiusXl + 6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          key: _panelKey,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_glassTop, _glassBottom],
            ),
            borderRadius: BorderRadius.circular(dims.radiusXl + 6),
            border: Border.all(
              color: AppColors.starGold.withValues(alpha: .85),
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(context),
                  Flexible(child: _body(context)),
                  SizedBox(height: dims.gapSm),
                ],
              ),
              // Pièces en vol : au-dessus de tout, sans bloquer les taps.
              Positioned.fill(
                child: IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, c) =>
                        _coinFlight(Size(c.maxWidth, c.maxHeight)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(dims.gapMd, dims.gapSm, dims.gapSm, dims.gapXs),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text('🏆', style: TextStyle(fontSize: dims.emojiMd)),
                SizedBox(width: dims.gapXs),
                Flexible(
                  child: Text(
                    'CLASSEMENT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(color: Color(0x99000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _CoinCounter(
            chipKey: _chipKey,
            animation: _coinsCtrl,
            bump: _chipBump,
            value: () => _displayedCoins,
          ),
          SizedBox(width: dims.gapXxs),
          Bouncy(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: dims.backBubble * .82,
              height: dims.backBubble * .82,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: dims.iconMd * .9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bosse du compteur quand une pièce vient d'y atterrir.
  double _chipBump(double t) {
    var bump = 0.0;
    for (var i = 0; i < _coinCount; i++) {
      final arrival = _coinCount <= 1
          ? _flight
          : (1 - _flight) * i / (_coinCount - 1) + _flight;
      final since = t - arrival;
      if (since >= 0 && since < .12) {
        bump = math.max(bump, math.sin(math.pi * since / .12));
      }
    }
    return bump;
  }

  Widget _body(BuildContext context) {
    final progress = context.watch<ProgressService>();
    if (progress.isGuest || _myId == null) return const _GuestInvite();
    return switch (_status) {
      _Status.loading => const _PanelMessage(
          emoji: '⏳',
          text: 'Chargement du classement…',
        ),
      _Status.error => _PanelMessage(
          emoji: '😅',
          text: 'Classement indisponible.',
          action: PrimaryButton(
            label: 'RÉESSAYER',
            icon: Icons.refresh_rounded,
            color: AppColors.sky,
            onTap: _load,
          ),
        ),
      _Status.ready => _entries.isEmpty
          ? const _PanelMessage(
              emoji: '🌱',
              text: 'Personne pour le moment.\nSois le premier !',
            )
          : _list(context),
    };
  }

  Widget _list(BuildContext context) {
    final dims = context.dims;
    return SizedBox(
      height: _listH,
      // Les lignes se fondent en haut et en bas plutôt que d'être coupées
      // net par le bord du panneau.
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, .06, .94, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: EdgeInsets.symmetric(horizontal: dims.gapSm),
          child: SizedBox(
            height: _rowH * _entries.length,
            child: AnimatedBuilder(
              animation: _riseCtrl,
              builder: (context, _) => Stack(children: _tiles(context)),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _tiles(BuildContext context) {
    final tiles = <Widget>[];
    Widget? mine;
    final riseT = _riseCtrl.value;

    for (final entry in _entries) {
      final isMe = entry.id == _myId;
      final to = (_endIndex[entry.id] ?? 0).toDouble();
      final from =
          (_startIndex[entry.id] ?? _endIndex[entry.id] ?? 0).toDouble();
      // L'enfant est « propulsé » (dépassement élastique en fin de course),
      // les autres se décalent souplement autour de lui.
      final curve = isMe ? Curves.easeOutBack : Curves.easeInOutCubic;
      final position = lerpDouble(from, to, curve.transform(riseT))!;

      final tile = Positioned(
        key: ValueKey(entry.id),
        top: position * _rowH,
        left: 0,
        right: 0,
        height: _rowH,
        child: _RankTile(
          entry: entry,
          rank: position.round() + 1,
          isMe: isMe,
          rowHeight: _rowH,
          rise: isMe && _hasRise ? riseT : 1,
          points: isMe && _hasRise
              ? (entry.points - widget.pointsEarned * (1 - riseT)).round()
              : entry.points,
        ),
      );
      if (isMe) {
        mine = tile;
      } else {
        tiles.add(tile);
      }
    }
    // La ligne de l'enfant passe par-dessus les autres pendant qu'il grimpe.
    if (mine != null) tiles.add(mine);
    return tiles;
  }

  Widget _coinFlight(Size size) {
    final target = _coinTarget;
    if (target == null || _coinCount == 0) return const SizedBox.shrink();
    final dims = context.dims;
    final start = Offset(size.width / 2, size.height - _rowH * .5);

    return AnimatedBuilder(
      animation: _coinsCtrl,
      builder: (context, _) {
        final coins = <Widget>[];
        for (var i = 0; i < _coinCount; i++) {
          final raw = _coinT(i, _coinsCtrl.value);
          if (raw <= 0 || raw >= 1) continue;
          final t = Curves.easeInOut.transform(raw);
          final control = Offset(
            (start.dx + target.dx) / 2 + _coinDrift[i] * size.width * .38,
            math.min(start.dy, target.dy) - size.height * .12,
          );
          final p = start * ((1 - t) * (1 - t)) +
              control * (2 * (1 - t) * t) +
              target * (t * t);
          final coinSize = dims.emojiSm + 8;
          final opacity = raw < .12
              ? raw / .12
              : raw > .88
                  ? (1 - raw) / .12
                  : 1.0;
          coins.add(Positioned(
            left: p.dx - coinSize / 2,
            top: p.dy - coinSize / 2,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1.25 - .5 * t,
                child: Text('🪙', style: TextStyle(fontSize: coinSize)),
              ),
            ),
          ));
        }
        return Stack(children: coins);
      },
    );
  }
}

/// Compteur de pièces du panneau : c'est la cible des pièces qui volent, et
/// il s'incrémente (avec une bosse) à chaque arrivée.
class _CoinCounter extends StatelessWidget {
  final Key chipKey;
  final Animation<double> animation;
  final double Function(double) bump;
  final int Function() value;

  const _CoinCounter({
    required this.chipKey,
    required this.animation,
    required this.bump,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.scale(
        scale: 1 + .22 * bump(animation.value),
        child: Container(
          key: chipKey,
          padding: EdgeInsets.symmetric(
            horizontal: dims.gapSm,
            vertical: dims.gapXxs + 1,
          ),
          decoration: BoxDecoration(
            color: AppColors.coin.withValues(alpha: .28),
            borderRadius: BorderRadius.circular(dims.radiusXl),
            border: Border.all(
              color: AppColors.starGold.withValues(alpha: .9),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🪙', style: TextStyle(fontSize: dims.emojiSm)),
              SizedBox(width: dims.gapXxs),
              Text(
                '${value()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une ligne du classement. [rise] (0→1) pilote la mise en avant de la ligne
/// de l'enfant pendant la propulsion : léger grossissement et halo doré.
class _RankTile extends StatelessWidget {
  final RemoteProfile entry;
  final int rank;
  final bool isMe;
  final double rowHeight;
  final double rise;
  final int points;

  const _RankTile({
    required this.entry,
    required this.rank,
    required this.isMe,
    required this.rowHeight,
    required this.rise,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final medal = _medalColors[rank];
    final flying = isMe && rise < 1;
    final ink = isMe ? AppColors.ink : Colors.white;

    final tile = Container(
      margin: EdgeInsets.only(bottom: dims.gapXs),
      padding: EdgeInsets.symmetric(horizontal: dims.gapSm),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.starGold, AppColors.coin],
              )
            : null,
        color: isMe
            ? null
            : Colors.white.withValues(alpha: medal != null ? .2 : .11),
        borderRadius: BorderRadius.circular(dims.radiusMd),
        border: Border.all(
          color: isMe
              ? Colors.white
              : (medal ?? Colors.white)
                  .withValues(alpha: medal != null ? .9 : .18),
          width: isMe ? 2.5 : 1.5,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.starGold
                      .withValues(alpha: .3 + .45 * math.sin(math.pi * rise)),
                  blurRadius: 14 + 16 * math.sin(math.pi * rise),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: dims.s(30),
            child: _medals[rank] != null
                ? Text(
                    _medals[rank]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: dims.emojiMd),
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ink.withValues(alpha: .75),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          SizedBox(width: dims.gapXs),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (medal ?? Colors.white).withValues(alpha: .6),
            ),
            child: ProfileAvatar(
              avatar: entry.avatarUrl ?? '',
              size: rowHeight * .52,
            ),
          ),
          SizedBox(width: dims.gapXs),
          Expanded(
            child: Text(
              entry.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: dims.gapXs,
              vertical: dims.gapXxs * .5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isMe ? .55 : .13),
              borderRadius: BorderRadius.circular(dims.radiusLg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⭐', style: TextStyle(fontSize: dims.emojiSm * .9)),
                SizedBox(width: dims.gapXxs),
                Text(
                  '$points',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!flying) return tile;
    return Transform.scale(
      scale: 1 + .08 * math.sin(math.pi * rise),
      child: tile,
    );
  }
}

class _PanelMessage extends StatelessWidget {
  final String emoji;
  final String text;
  final Widget? action;

  const _PanelMessage({required this.emoji, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final dims = context.dims;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dims.gapLg, vertical: dims.gapLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: dims.emojiLg)),
          SizedBox(height: dims.gapXs),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .9),
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (action != null) ...[
            SizedBox(height: dims.gapMd),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Invités : la progression reste sur l'appareil, il n'y a donc pas de rang
/// à afficher — on propose de créer un compte.
class _GuestInvite extends StatelessWidget {
  const _GuestInvite();

  @override
  Widget build(BuildContext context) {
    return _PanelMessage(
      emoji: '🏆',
      text:
          'Crée un compte pour rejoindre\nle classement et jouer avec tes amis !',
      action: PrimaryButton(
        label: 'CRÉER UN COMPTE',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.correct,
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
          );
        },
      ),
    );
  }
}
