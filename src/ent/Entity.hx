package ent;

enum Kind {
	EHero;
}

class Entity {

	public var kind : Kind;
	public var x(default,set) : Float;
	public var y(default,set) : Float;
	public var anim : h2d.Anim;
	var game : Game;

	public function new(k, x, y) {
		game = Game.inst;
		this.kind = k;
		init();
		this.x = x;
		this.y = y;
	}

	function set_x(v:Float) {
		anim.x = Std.int(v * 7);
		return x = v;
	}

	function set_y(v:Float) {
		anim.y = Std.int(v * 7);
		return y = v;
	}

	function init() {
		anim = new h2d.Anim(game.s2d);
		anim.play([game.sprites[0]]);
	}

}