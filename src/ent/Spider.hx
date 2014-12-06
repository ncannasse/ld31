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
				vx = (0.2 + pow * 0.1) * dir;
				vy = -(0.2 + pow * 0.1);
				jumpWait = 0.5 + Math.random() * 0.5;
			} else {
				vx += dir * 0.005 * dt;
				if( trand(0.01) ) dir = -dir;
			}
		}
		super.update(dt);
		if( !game.hero.isRemoved() && game.hero.collide(this) )
			game.hero.hit(this);
	}

}