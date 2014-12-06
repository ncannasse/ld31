package ent;

class HeroFire extends Entity {

	override function init() {
		super.init();
		bounds.set( -0.3, -0.1, 0.6, 0.2 );
		gravity = 0.02;
		vx = dir * 0.5;
		friction = 0;
	}

	override function onCollide() {
		destroy();
	}


	override function update(dt:Float) {
		anim.rotation = Math.atan2(vy, vx);
		super.update(dt);
		for( e in game.entities )
			if( e != game.hero && e.collide(this) ) {
				e.hit(this);
				this.destroy();
			}
	}

}