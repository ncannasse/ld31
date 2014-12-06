package ent;

import hxd.Key in K;

class Hero extends Entity {

	public function new(x,y) {
		super(EHero, x, y);
		bounce = 0.2;
		friction = 0.7;
		setBounds(3, 6);
	}

	override function update(dt:Float) {
		var s = 0.015 * dt;
		var dx = 0., dy = 0.;
		if( K.isDown(K.LEFT) || K.isDown("Q".code) || K.isDown("A".code) ) {
			dir = Left;
			dx--;
		}
		if( K.isDown(K.RIGHT) || K.isDown("D".code) ) {
			dir = Right;
			dx++;
		}
		if( K.isDown(K.UP) ) {
			dir = Up;
			dy--;
		}
		if( K.isDown(K.DOWN) ) {
			dir = Down;
			dy++;
		}
		if( dx != 0 && dy != 0 ) {
			dx /= Math.sqrt(2);
			dy /= Math.sqrt(2);
		}
		if( dx == 0 && dy == 0 )
			anim.currentFrame = 0;
		vx += dx * s;
		vy += dy * s;
		super.update(dt);
	}

}