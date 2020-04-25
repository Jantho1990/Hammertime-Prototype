extends Spell


func effect():
  .effect()
  var caster = Spellcaster.Caster
  if caster.Weapon.throwing:
    caster.position = caster.Weapon.global_position
    GlobalSignal.dispatch('teleport')
