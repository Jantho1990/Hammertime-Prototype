extends Spell


func effect():
  .effect()
  var caster = Spellcaster.Caster
  if caster.Weapon.throwing:
    GlobalSignal.dispatch('build_unit', { 'unit_name': 'PlatformConstruct' }) # hardcoding for now; should draw from construct build selector whenever that gets built
