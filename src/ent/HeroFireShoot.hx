package ent;

class HeroFireShoot extends Entity {

	override function init() {
		super.init();
		setBounds(5, 4);
		gravity = 0.;
		vy = -0.5;
		friction = 0;
		isBullet = true;
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