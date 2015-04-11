@:enum
abstract Collide(Int) {
	public var No = 0;
	public var Full = 1;
	public function new(v:Int) {
		this = v;
	}
}

@:enum
abstract Season(Int) {
	public var Winter = 0;
	public var Autumn = 1;
	public var Summer = 2;
	public var Spring = 3;
	public var End = 4;
	public function new(v:Int) {
		this = v;
	}
	public function toInt() return this;
}

class SnowPart extends Part {
	var dir : Int;
	var spawn : Float;
	var vr = 0.;

	public function new(t) {
		super(t);
		dir = randDir();
		spawn = -1;
		update(0);
	}

	override function update(dt:Float) {
		dt *= 30;
		var s = Game.inst.level.s;
		var da = switch( s ) {
		case Winter: 0.01;
		default: 0.04;
		}
		if( spawn < 0 ) {
			a += da * dt * Game.inst.level.hasSnow;
			if( a > 1 ) {
				a = 1;
				switch( s ) {
				case Autumn:
					spawn = 5 + Math.random() * 3;
				default:
					spawn = 2 + Math.random() * 3;
				}
			}
		} else {
			spawn -= dt;
			if( spawn < 0 ) {
				spawn = 0;
				a -= da * dt;
				if( a < 0 )
					return false;
			}
		}
		vx += dir * 0.003 * dt;
		vr += vx * 0.1 * dt;
		rotation += vr * dt;
		vx -= vr * 0.01 * dt;
		if( Math.abs(vx) > 0.05 && Math.random() < 0.1 * dt )
			dir = -dir;
		if( y > 210 ) return false;
		return super.update(dt/60);
	}
}


class Level {

	public var s : Season;
	public var root : h2d.Layers;
	public var width : Int;
	public var height : Int;
	var col : Array<Collide>;
	var data : Data.World;
	var game : Game;
	public var cellSize = 7;
	public var parts : h2d.SpriteBatch;
	var tiles : Array<h2d.TileGroup>;
	var sky : h2d.TileGroup;

	public function new(s) {
		this.s = s;
		game = Game.inst;
		root = new h2d.Layers(game.s2d);
	}

	public function collide(x:Float, y:Float) {
		var ix = Std.int(x), iy = Std.int(y);
		if( ix < 0 || iy < 0 || ix >= width || iy >= height ) return true;
		return col[ix + iy * width] != No;
	}

	public function init() {

		data = Data.world.all[s.toInt() + 1];
		width = data.width;
		height = data.height;
		col = [for( i in 0...width * height ) No];

		var tile = hxd.Res.world.toTile();
		var tl = tile.grid(cellSize);
		var tprops = data.props.getTileset(Data.world, "world.png");
		tiles = [];
		for( l in data.layers ) {
			var ldat = l.data.data.decode();

			switch( l.name ) {
			case "ent":
				var p = -1;
				for( y in 0...height )
					for( x in 0...width ) {
						var tid = ldat[++p] - 1;
						if( tid < 0 ) continue;
						switch( tid ) {
						case 13:
							new ent.Item(EMemory, x + 0.5, y + 1);
						default:
							throw "Unknown entity #" + tid;
						}
					}
				continue;
			case "collide":
				var p = -1;
				for( y in 0...height )
					for( x in 0...width ) {
						var tid = ldat[++p] - 1;
						if( tid < 0 ) continue;
						col[p] = Full;
					}
				continue;
			default:
			}

			var isObjects = l.name == "objects", lastY = -1;
			var t = new h2d.TileGroup(tile, root);
			if( l.name == "sky" ) sky = t;
			tiles.push(t);
			var p = -1;
			for( y in 0...height )
				for( x in 0...width ) {
					var tid = ldat[++p] - 1;
					if( tid < 0 ) continue;

					if( isObjects ) {
						if( lastY >= 0 && lastY != y ) {
							t = new h2d.TileGroup(tile);
							tiles.push(t);
							root.add(t, 1);
						}
						lastY = y;
						t.y = y * cellSize + 4;
						t.add(x * cellSize, -4, tl[tid]);
					} else {
						t.add(x * cellSize, y * cellSize, tl[tid]);
						if( l.name == "sky" )
							t.add((x + 48) * cellSize, y * cellSize, tl[tid]);
					}
					var tp = tprops.props[tid];
					if( tp != null ) {
						if( x == 2 && y == 2 ) trace(l.name, tid,tp);
						col[p] = new Collide(tp.collide + 1);
					}
				}
			if( l.name == "bg" ) {
				var tbuild = new cdb.TileBuilder(tprops, Std.int(tile.width / cellSize), Std.int(tile.width / cellSize) * Std.int(tile.height / cellSize));
				var out = tbuild.buildGrounds(ldat, width);
				var i = 0;
				var max = out.length;
				while( i < max ) {
					var x = out[i++];
					var y = out[i++];
					var tid = out[i++];
					t.add(x * cellSize, y * cellSize, tl[tid]);
				}
			}
		}
		var t = switch( s ) {
		case Autumn: h2d.Tile.fromColor(0x502904, 2, 1);
		case Winter: h2d.Tile.fromColor(0xFFFFFF);
		case Summer: null;
		case Spring: h2d.Tile.fromColor(0x28AEF4, 1, 2);
		case End: h2d.Tile.fromColor(0x08050D);
		}
		parts = new h2d.SpriteBatch(t, root);
		parts.hasUpdate = true;
		parts.hasRotationScale = s == Autumn;
		root.add(parts, 2);
	}

	function getPartCount() {
		return switch( s ) {
		case Autumn: 1;
		case Winter: 4;
		case Summer: 0;
		case Spring: 3;
		case End: 6;
		}
	}

	public function startSnow() {
		hasSnow = 0.01;
	}

	public function next(onEnd) {
		var oparts = parts, osky = sky;

		var b = new h2d.CachedBitmap(root);
		b.freezed = true;
		for( t in tiles )
			b.addChild(t);

		s = switch( s ) {
		case Winter: Autumn;
		case Autumn: Summer;
		case Summer: Spring;
		case Spring: Winter;
		case End: End;
		};

		if( game.hasItem(MantleGirl) && game.hasItem(GaveWood) )
			s = End;

		hasSnow = 0.;
		init();

		sky.x = osky.x;
		for( t in tiles )
			root.add(t, 0);

		root.addChild(b);
		b.alpha = 1;
		game.waitUntil(function(dt) {
			b.alpha -= 0.003 * dt;
			if( b.alpha < 0 ) {
				b.remove();

				for( t in tiles )
					root.add(t, 1);

				onEnd();
				return true;
			}
			return false;
		});
		game.waitUntil(function(dt) {
			var elts = oparts.getElements();
			if( !elts.hasNext() ) {
				oparts.remove();
				return true;
			}
			for( e in elts ) {
				e.a -= 0.003 * dt;
				if( e.a < 0 ) e.remove();
			}
			return false;
		});
	}

	public function initSnow() {
		var count = getPartCount();
		for( i in 0...Std.int(count * 100) ) {
			var p = new SnowPart(parts.tile);
			p.x = Math.random() * width * cellSize;
			p.y = Math.random() * height * cellSize;
			p.vy = 0.2 + Math.random() * 0.3;
			p.a = 0;
			parts.add(p);
		}
		hasSnow = 0.01;
	}

	public var hasSnow = 0.;

	public function update(dt:Float) {

		sky.x -= 0.1 * dt;
		if( sky.x < -336 ) sky.x += 336;

		if( hasSnow > 0 ) {
			hasSnow += dt / 60;
			if( hasSnow > 1 ) hasSnow = 1;
			for( i in 0...getPartCount() ) {
				var p = new SnowPart(parts.tile);
				p.x = Math.random() * width * cellSize;
				p.y = Math.random() * height * cellSize * 0.5;
				p.vy = 0.2 + Math.random() * 0.3;
				p.a = 0;
				switch( s ) {
				case Spring:
					p.vy = p.vy * 4 + 5;
					p.vx = p.vy * 0.25;
					p.a = 0.5;
				default:
				}
				parts.add(p);
			}
		}
	}

}