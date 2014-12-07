package ent;

class Item extends Entity {

	override function init() {
		super.init();
		setBounds(2, 2);
		if( kind == ECave ) {
			game.level.root.add(anim, 0);
			setBounds(1, 1);
			bounds.offset(0, -4 / 7);
		}
	}

	override function update( dt : Float ) {
		super.update(dt);
		if( collide(game.hero) && !game.hero.lock ) {
			switch( kind ) {
			case EMemory:
				remove();
				game.getItem(Memory);
			case ECave:
				game.hero.lock = true;
				game.flash(function() {
					switch( x ) {
					case 6.5:
						game.hero.x = 23;
						game.hero.y = 11;
					case 24:
						game.hero.x = 32;
						game.hero.y = 18;
					case 32:
						game.hero.x = 5.5;
						game.hero.y = 10;
					default:
						trace(x);
					}
				}, function() {
					game.hero.lock = false;
				});
			default:
			}
		}
	}

}