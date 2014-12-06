import hxd.Key in K;

class Game extends hxd.App {

	public var entities : Array<ent.Entity>;
	public var hero : ent.Hero;
	public var level : Level;
	public var sprites : Array<Array<h2d.Tile>>;
	var parts : h2d.SpriteBatch;
	var blur : h2d.filter.Blur;
	var blurWay : Float = 0.;
	var blurEnd : Void -> Void;

	override function init() {

		entities = [];

		var grid = hxd.Res.sprites.toTile().grid(9, -5, -8);
		var line = 0;
		sprites = [for( frames in [3,4] ) { var a = [for( i in 0...frames ) grid[line * 13 + i]]; line++; a; } ];

		parts = new h2d.SpriteBatch(hxd.Res.sprites.toTile(), s2d);
		parts.hasUpdate = true;

		s2d.zoom = 3;

		level = new Level(2);
		level.init();
		hero = new ent.Hero(4.5, 3.5);

		blurIn(function() {
			level.initSnow();
		});
	}

	function blurIn(?onEnd) {
		blur = new h2d.filter.Blur(2, 3);
		level.root.filters = [blur];
		blurWay = -1;
		blurEnd = onEnd;
	}

	public function addPart( t : h2d.Tile, x : Float, y : Float, vx : Float, vy : Float ) {
		var p = new Part(t);
		parts.add(p);
		p.x = x * level.cellSize;
		p.y = y * level.cellSize;
		p.vx = vx * level.cellSize;
		p.vy = vy * level.cellSize;
	}


	override function update( dt : Float ) {
		for( e in entities.copy() )
			e.update(dt);
		level.update(dt);
		if( blur != null ) {
			blur.sigma -= 0.003 * dt;
			if( blur.sigma <= 0 ) {
				blur = null;
				level.root.filters = [];
				if( blurEnd != null ) blurEnd();
			}
		}
	}

	public static var inst : Game;
	static function main() {
		hxd.Res.initEmbed();
		Data.load(hxd.Res.data.entry.getBytes().toString());
		hxd.Res.music.loop = true;
		hxd.Res.music.play();
		inst = new Game();
	}

}