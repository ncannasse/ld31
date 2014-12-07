package ent;

enum Kind {
	EHero;
	EMemory;
	EOldWomen;
	EFisher;
	EMerchant;
	EHouse;
}

class Entity {

	public var kind : Kind;
	public var x(default,set) : Float;
	public var y(default,set) : Float;
	public var anim : h2d.Anim;
	public var vx : Float = 0.;
	public var vy : Float = 0.;
	public var friction = 0.9;
	public var bounce = 0.2;
	public var dir(default, set) : hxd.Direction;

	public var bounds : h2d.col.Bounds;

	var game : Game;
	var events : Array< Float -> Bool >;

	public function new(k:Kind, x, y, dir : hxd.Direction = Down) {
		game = Game.inst;
		bounds = new h2d.col.Bounds();
		bounds.set( -0.5, -1, 1, 1);
		game.entities.push(this);
		this.kind = k;
		this.x = x;
		this.y = y;
		this.dir = dir;
		init();
	}

	function set_dir(d:hxd.Direction) {
		if( anim != null && d.x != 0 ) anim.scaleX = d.x;
		return dir = d;
	}

	function set_x(v:Float) {
		if( anim != null ) anim.x = v * 7;
		return x = v;
	}

	function set_y(v:Float) {
		if( anim != null ) anim.y = v * 7;
		return y = v;
	}

	function init() {
		anim = new h2d.Anim();
		anim.speed = 5;
		anim.colorKey = 0xCEA0D2;
		game.level.root.add(anim, 1);
		anim.play(game.sprites[kind.getIndex()]);
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

	public function hit( px : Float, py : Float ) {
		return px >= bounds.xMin + x  && py >= bounds.yMin + y && px < bounds.xMax + x && py < bounds.yMax + y;
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
		y += vy * dt;

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
			onCollide();
		}

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

		if( friction > 0 ) {
			vx *= Math.pow(friction, dt);
			vy *= Math.pow(friction, dt);
		}
	}

}