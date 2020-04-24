extends Spell


func effect():
  .effect()
  var caster = Spellcaster.Caster
  caster.position = caster.Weapon.global_position
