package ent;

class Item extends Entity {

	override function init() {
		super.init();
		setBounds(2, 2);
	}

	override function update( dt : Float ) {
		super.update(dt);
		if( collide(game.hero) ) {
			remove();
			game.getItem(switch( kind ) {
			case EMemory: Memory;
			default: throw "No item for " + kind;
			});
		}
	}

}