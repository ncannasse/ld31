package ent;

class Npc extends Entity {

	override function init() {
		super.init();
		switch( kind ) {
		default:
			setBounds(7, 7);
		}
		anim.x = Std.int(anim.x);
		anim.y = Std.int(anim.y);
		anim.speed = 0;
		anim.onAnimEnd = function() { anim.speed = 0; };
	}

	override function update(dt:Float) {
		if( anim.speed == 0 )
			switch( kind ) {
			case EOldWomen:
				if( trand(0.05) )
					anim.speed = 32;
			case EFisher:
				if( anim.speed == 0 && trand(0.01) )
					anim.speed = 8;
			case EMerchant:
				if( anim.speed == 0 && trand(0.01) )
					anim.speed = 16;
			default:
			}
	}

}