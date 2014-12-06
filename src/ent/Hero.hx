package ent;

import hxd.Key in K;

class Hero extends Entity {

	var jumpPower = 0.;

	public function new(mode, x,y) {
		super(mode, switch( mode ) { case Shooter: EHeroShoot; default: EHero; } , x, y);
		bounce = 0.2;
		friction = 0.7;
		switch( mode ) {
		case Platform:
			setBounds(3, 6);
		case Shooter:
			setBounds(3, 7);
		default:
		}
	}

	function fire() {
		switch( game.mode ) {
		case Platform:
			new HeroFire(game.mode, EHeroFire, x + dir * 0.3, y - 0.5, dir);
		case Shooter:
			new HeroFireShoot(game.mode, EHeroFireShoot, x, y - 0.5, dir);
		default:
		}
	}

	override function update(dt:Float) {
		switch( game.mode ) {
		default:
			if( K.isDown(K.LEFT) || K.isDown("Q".code) || K.isDown("A".code) ) {
				dir = -1;
				vx -= 0.07 * dt;
			}
			if( K.isDown(K.RIGHT) || K.isDown("D".code) ) {
				dir = 1;
				vx += 0.07 * dt;
			}
		}
		switch( game.mode ) {
		case Platform:
			if( K.isPressed(K.UP) && onFloor ) {
				vy = -0.3;
				jumpPower = 0.4;
			}
			if( jumpPower > 0 && K.isDown(K.UP) ) {
				var dj = dt * 0.07;
				if( dj > jumpPower ) dj = jumpPower;
				vy -= dj;
				jumpPower -= dj;
			} else
				jumpPower = 0;
		case Shooter:
			if( K.isDown(K.UP) )
				vy -= 0.07 * dt;
			if( K.isDown(K.DOWN) )
				vy += 0.07 * dt;
		default:
		}
		if( K.isPressed(K.SPACE) || K.isPressed("E".code) )
			fire();
		super.update(dt);
		if( vy >= 0 || onFloor ) jumpPower = 0;
	}

}