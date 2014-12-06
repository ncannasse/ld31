import hxd.Key in K;

enum Mode {
	Platform;
	Shooter;
	Mode3;
	Mode4;
	Mode5;
	Mode6;
	Mode7;
	Mode8;
	Mode9;
}

class MyPart extends h2d.SpriteBatch.BatchElement {
	public var vx : Float;
	public var vy : Float;
	public var hit : Int;
	public var game : GameData;

	override function update(dt:Float) {
		dt *= 60;
		x += vx * dt;
		y += vy * dt;
		switch( game.mode ) {
		case Platform:
			vy += 0.2 * dt;
			if( vy > 0 && game.level.collide(x/game.level.cellSize, y/game.level.cellSize) ) {
				vy *= -0.8;
				hit++;
			}
			if( hit > 3 ) {
				a -= 0.1 * dt;
				if( a < 0 ) return false;
			}
		case Shooter:
			if( y > 66 ) return false;
		default:
		}
		return true;
	}
}

class GameData {
	public var mode : Mode;
	public var entities : Array<ent.Entity>;
	public var hero : ent.Hero;
	public var level : Level;
	public var parts : h2d.SpriteBatch;
	public function new(m) {
		this.mode = m;
		entities = [];
	}

	public function addPart( t : h2d.Tile, x : Float, y : Float, vx : Float, vy : Float ) {
		var p = new MyPart(t);
		parts.add(p);
		p.x = x * level.cellSize;
		p.y = y * level.cellSize;
		p.game = this;
		p.vx = vx * level.cellSize;
		p.vy = vy * level.cellSize;
	}

	public function init() {
		parts = new h2d.SpriteBatch(hxd.Res.sprites.toTile());
		parts.hasUpdate = true;
		switch( mode ) {
		case Shooter:
			level.root.add(parts, 0);
		default:
			level.root.add(parts, 1);
		}
	}

}

class Game extends hxd.App {

	public var modes : Array<GameData>;
	public var sprites : Array<h2d.Tile>;

	override function init() {

		sprites = hxd.Res.sprites.toTile().grid(9, -5, -8);

		s2d.zoom = 3;

		//modes = [for( m in Mode.createAll() ) new GameData(m)];
		modes = [new GameData(Platform),new GameData(Shooter)];

		for( d in modes ) {
			if( d == null ) continue;
			switch( d.mode ) {
			case Platform:
				d.level = new Level(1,d);
				d.level.init();
				d.hero = new ent.Hero(d.mode, 1, 15);
			case Shooter:
				d.level = new ShooterLevel(2,d);
				d.level.init();
				d.hero = new ent.Hero(d.mode, d.level.width>>1, 4);
			default:
				// platform
				d.level = new Level(1,d);
				d.level.init();
				d.hero = new ent.Hero(d.mode, 1, 15);
			}
			var m = new h2d.Mask(Std.int(s2d.width / 3), Std.int(s2d.height / 3), s2d);
			var i = d.mode.getIndex();
			m.x = (i % 3) * 88;
			m.y = Std.int(i / 3) * 66;
			m.addChild(d.level.root);
			d.init();
		}
	}

	override function update( dt : Float ) {
		for( m in modes ) {
			if( m == null ) continue;
			for( e in m.entities.copy() )
				e.update(dt);
			m.level.update(dt);
		}
	}

	public static var inst : Game;
	static function main() {
		hxd.Res.initEmbed();
		Data.load(hxd.Res.data.entry.getBytes().toString());
		inst = new Game();
	}

}