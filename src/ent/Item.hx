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
			game.getItem(this.kind);
		}
	}

}