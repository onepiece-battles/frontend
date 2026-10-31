import '../l10n/app_localizations.dart';

String combatEffectLabel(AppLocalizations l, String type) => switch (type) {
      'DAMAGE' => l.combatDamage,
      'HEAL' => l.combatHeal,
      'SHIELD' => l.combatShield,
      'GUARD' => l.combatGuard,
      'EVASION' => l.combatEvasion,
      'ATTACK_UP' => l.combatAttackUp,
      'ATTACK_DOWN' => l.combatAttackDown,
      'IMMUNE' => l.combatImmune,
      'DEFENSE_DOWN' => l.combatDefenseDown,
      'POISON' => l.combatPoison,
      'STUN' => l.combatStun,
      'ENERGY' => l.combatEnergy,
      'COATING' => l.combatCoating,
      'CONTROL_SKIP' => l.combatControlSkip,
      _ => type,
    };
String combatOriginLabel(AppLocalizations l, String origin) => switch (origin) {
      'FRUIT' => l.combatFruit,
      'HAKI' => l.combatHaki,
      'EQUIPMENT' => l.combatEquipment,
      'RACIAL' => l.combatRacial,
      _ => l.combatTechnical
    };

String combatSkillEffect(AppLocalizations l, Map<String, dynamic> effect) {
  final type = '${effect['type']}';
  final power = (effect['power'] as num?) ?? 0;
  final percent =
      (power * 100).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  final basis = switch (type) {
    'DAMAGE' => l.combatBasedAttack,
    'HEAL' || 'SHIELD' || 'POISON' => l.combatBasedHealth,
    'ENERGY' => l.combatBasedEnergy,
    _ => ''
  };
  final duration = (effect['duration'] as num?)?.toInt() ?? 0;
  return '${combatEffectLabel(l, type)}${power > 0 ? ' $percent% $basis' : ''}${duration > 0 ? ' · ${l.combatEffectDuration(duration)}' : ''}';
}

String combatOutcomeLabel(AppLocalizations l, Map<String, dynamic> effect) {
  final label = combatEffectLabel(l, '${effect['type']}');
  final amount = (effect['amount'] as num?) ?? 0;
  final value = switch (effect['unit']) {
    'NONE' => '',
    'BASIS_POINTS' =>
      '${(amount / 100).toString().replaceFirst(RegExp(r'\.0$'), '')}%',
    _ => '$amount'
  };
  final duration = (effect['duration'] as num?)?.toInt() ?? 0;
  return '$label${value.isEmpty ? '' : ' $value'}${duration > 0 ? ' · ${l.combatEffectDuration(duration)}' : ''}';
}
