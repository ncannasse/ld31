package ent;

class Spider extends Entity {

	var jumpWait = 0.;

	public function new(mode, x, y) {
		super(mode, ESpider, x, y, randDir());
		setBounds(7, 5);
	}

	override function update( dt : Float ) {
		if( onFloor ) {
			jumpWait -= dt / 60;
			if( jumpWait < 0 ) {
				var pow = Math.random();
				vx = (0.2 + pow * 0.3) * dir;
				vy = -(0.2 + pow * 0.2);
				jumpWait = 1 + Math.random();
			}
		} else {
			vx += dir * 0.03 * dt;
			if( trand(0.01) ) dir = -dir;
		}
		super.update(dt);
		if( !game.hero.isRemoved() && game.hero.collide(this) )
			game.hero.hit(this);
	}

}