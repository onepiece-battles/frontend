import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../combat/combat_api.dart';
import '../../../combat/combat_labels.dart';
import '../../../constants/onepiece_colors.dart';
import '../../../l10n/app_localizations.dart';

class CharacterSkillsSection extends StatefulWidget {
  const CharacterSkillsSection({super.key, required this.characterId});
  final String characterId;
  @override
  State<CharacterSkillsSection> createState() => _CharacterSkillsSectionState();
}

class _CharacterSkillsSectionState extends State<CharacterSkillsSection> {
  Future<CombatProfile?>? _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CharacterSkillsSection old) {
    super.didUpdateWidget(old);
    if (old.characterId != widget.characterId) _load();
  }

  void _load() {
    if (GetIt.instance.isRegistered<CombatApi>()) {
      _future = GetIt.instance<CombatApi>().profile(widget.characterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    if (_future == null) return const SizedBox.shrink();
    return FutureBuilder<CombatProfile?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              snapshot.data == null) {
            return const SizedBox.shrink();
          }
          return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OnepieceColors.separator)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.combatSkills,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: OnepieceColors.primaryLabel)),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState != ConnectionState.done)
                      const LinearProgressIndicator(minHeight: 2)
                    else if (snapshot.hasError)
                      Row(children: [
                        Expanded(child: Text(l.combatSkillsUnavailable)),
                        TextButton(
                            onPressed: () => setState(_load),
                            child: Text(l.combatSkillsRetry))
                      ])
                    else if (snapshot.data case final p?) ...[
                      Text(l.combatSkillsVersion(p.version),
                          style: const TextStyle(
                              fontSize: 12,
                              color: OnepieceColors.secondaryLabel)),
                      if (p.coating > 0)
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(l.combatCoatingLevel(p.coating),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: OnepieceColors.fancyBlue))),
                      if ((p.data['immunities'] as List? ?? const [])
                          .contains('NEGATIVE_HOLLOW'))
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(l.combatNegativeImmunity,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: OnepieceColors.secondaryLabel))),
                      if (p.era != 'unspecified')
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(p.era,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: OnepieceColors.secondaryLabel))),
                      if (p.skills.isEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(l.combatSkillsEmpty))
                      else ...[
                        for (final skill in p.skills)
                          ExpansionTile(
                              key: ValueKey(skill.data['id']),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding:
                                  const EdgeInsets.only(bottom: 12),
                              shape: const Border(
                                  bottom: BorderSide(
                                      color: OnepieceColors.separator)),
                              collapsedShape: const Border(
                                  bottom: BorderSide(
                                      color: OnepieceColors.separator)),
                              title: Text(skill.name(zh),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${combatOriginLabel(l, skill.origin)} · ${l.combatSkillCost(skill.energy, skill.cooldown, skill.maxUses)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.5,
                                      color: OnepieceColors.secondaryLabel)),
                              children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              switch (skill.target) {
                                                'SELF' =>
                                                  l.combatSkillScopeSelf,
                                                'ALL_ENEMIES' =>
                                                  l.combatSkillScopeArea,
                                                _ => l.combatSkillScopeEnemy
                                              },
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          const SizedBox(height: 8),
                                          for (final effect in skill.effects)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 5),
                                                child: Text(
                                                    combatSkillEffect(
                                                        l, effect),
                                                    style: const TextStyle(
                                                        fontSize: 12))),
                                          if ((skill.data['healthBelow']
                                                      as num? ??
                                                  1) <
                                              1)
                                            Text(
                                                l.combatHealthCondition(
                                                    ((skill.data['healthBelow']
                                                                as num) *
                                                            100)
                                                        .round()),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: OnepieceColors
                                                        .secondaryLabel)),
                                          if (skill.effects.any(
                                              (e) => e['type'] == 'COATING'))
                                            Text(l.combatCoatingRequirement,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: OnepieceColors
                                                        .secondaryLabel)),
                                          if (skill.origin == 'FRUIT')
                                            Text(l.combatSkillRequirement,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: OnepieceColors
                                                        .secondaryLabel)),
                                        ]))
                              ]),
                        const SizedBox(height: 10),
                        Text(l.combatSkillGameRules,
                            style: const TextStyle(
                                fontSize: 11,
                                color: OnepieceColors.secondaryLabel)),
                      ],
                    ],
                  ]));
        });
  }
}
