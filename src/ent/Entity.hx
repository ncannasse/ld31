package ent;

enum Kind {
	EHero;
	EHeroFire;
	ESpider;
	EHeroShoot;
	EHeroFireShoot;
}

class Entity {

	public var kind : Kind;
	public var x(default,set) : Float;
	public var y(default,set) : Float;
	public var anim : h2d.Anim;
	public var vx : Float = 0.;
	public var vy : Float = 0.;
	public var gravity = 0.035;
	public var friction = 0.9;
	public var bounce = 0.2;
	public var dir(default, set) : Int;

	public var bounds : h2d.col.Bounds;
	public var isBullet = false;

	var onFloor : Bool;
	var game : Game.GameData;

	public function new(mode:Game.Mode, k:Kind, x, y, dir = 1) {
		game = Game.inst.modes[mode.getIndex()];
		if( game == null ) throw "Missing " + mode+" for "+k;
		bounds = new h2d.col.Bounds();
		bounds.set( -0.5, -1, 1, 1);
		game.entities.push(this);
		switch( mode ) {
		case Shooter:
			gravity = 0;
		default:
		}
		this.kind = k;
		this.x = x;
		this.y = y;
		this.dir = dir;
		init();
	}

	function set_dir(d:Int) {
		if( anim != null ) anim.scaleX = d;
		return dir = d;
	}

	function set_x(v:Float) {
		if( anim != null ) anim.x = Std.int(v * 7);
		return x = v;
	}

	function set_y(v:Float) {
		if( anim != null ) anim.y = Std.int(v * 7);
		return y = v;
	}

	function init() {
		anim = new h2d.Anim();
		game.level.root.add(anim, 1);
		anim.play([Game.inst.sprites[kind.getIndex() * 13]]);
		this.x = x;
		this.y = y;
		this.dir = dir;
	}

	function onCollide() {
	}

	public function isRemoved() {
		return anim == null || anim.parent == null;
	}

	public function remove() {
		anim.remove();
		game.entities.remove(this);
	}

	function randDir() {
		return Std.random(2) * 2 - 1;
	}

	function trand(f:Float) {
		return Math.random() < f * hxd.Timer.tmod;
	}

	public function destroy() {
		remove();
		var t = anim.getFrame();
		var seed = Std.random(1000);
		for( px in 0...t.width )
			for( py in 0...t.height )
				if( hxd.Rand.hash(px + py * t.width, seed) % 3 == 0 )
					game.addPart(t.sub(px, py, 1, 1), x, y, hxd.Math.srand(0.1), -(0.2 + Math.random() * 0.1));
	}

	function setBounds( pw, ph ) {
		var w = pw / game.level.cellSize;
		var h = ph / game.level.cellSize;
		bounds.set( -w * 0.5, -h, w, h);
	}

	public function hit( e : ent.Entity ) {
		destroy();
	}

	public function collide( e : ent.Entity ) {
		if( e == this ) return false;
		if( e.x + e.bounds.xMax < x + bounds.xMin ) return false;
		if( e.y + e.bounds.yMax < y + bounds.yMin ) return false;
		if( e.x + e.bounds.xMin > x + bounds.xMax ) return false;
		if( e.y + e.bounds.yMin > y + bounds.yMax ) return false;
		return true;
	}

	public function update(dt:Float) {
		switch( game.mode ) {
		case Shooter:

			x += vx * dt;
			y += vy * dt;
			if( isBullet ) {
				if( y < -1 && vy < 0 ) remove();
				if( y > 11 && vy > 0 ) remove();
			} else {
				if( y < 1 && vy < 0 )
					y = 1;
				if( x < 0.5 ) x = 0.5;
				if( y * game.level.cellSize > 66 ) y = 66 / game.level.cellSize;
				if( x > game.level.width - 0.5 ) x = game.level.width - 0.5;
			}
			if( friction > 0 ) {
				vx *= Math.pow(friction, dt);
				vy *= Math.pow(friction, dt);
			}

		default:
			y += vy * dt;
			vy += gravity * dt;
			if( vy > 0.9 ) vy = 0.9;

			// head
			if( game.level.collide(x + bounds.xMin, y + bounds.yMin) || game.level.collide(x + bounds.xMax, y + bounds.yMin) ) {
				y = Std.int(y + bounds.yMin + 1) - bounds.yMin;
				if( vy < 0 ) vy = -vy * bounce;
				onCollide();
			}
			// foot
			if( game.level.collide(x + bounds.xMin, y + bounds.yMax) || game.level.collide(x + bounds.xMax, y + bounds.yMax) ) {
				y = Std.int(y + bounds.yMax) - bounds.yMax;
				if( vy > 0 ) vy = 0;// -vy * bounce;
				onFloor = true;
				onCollide();
			} else
				onFloor = false;
			x += vx * dt;

			// left
			if( game.level.collide(x + bounds.xMin, y + bounds.yMin + 0.1) || game.level.collide(x + bounds.xMin, y + bounds.yMax - 0.1) ) {
				x = Std.int(x + bounds.xMin + 1) - bounds.xMin + 0.01;
				if( vx < 0 ) vx = -vx * bounce;
				onCollide();
			}

			// right
			if( game.level.collide(x + bounds.xMax, y + bounds.yMin + 0.1) || game.level.collide(x + bounds.xMax, y + bounds.yMax - 0.1) ) {
				x = Std.int(x + bounds.xMax) - bounds.xMax - 0.01;
				if( vx > 0 ) vx = -vx * bounce;
				onCollide();
			}

			if( friction > 0 ) vx *= Math.pow(friction, dt);
		}
	}

}