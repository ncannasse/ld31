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
		if( spawn < 0 ) {
			a += 0.01 * dt * Game.inst.level.hasSnow;
			if( a > 1 ) {
				a = 1;
				spawn = 2 + Math.random() * 3;
			}
		} else {
			spawn -= dt;
			if( spawn < 0 ) {
				spawn = 0;
				a -= 0.01 * dt;
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
	var parts : h2d.SpriteBatch;
	var tiles : Array<h2d.TileGroup>;

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

		col = [for( i in 0...width * height ) No];
		data = Data.world.all[s.toInt() + 1];
		width = data.width;
		height = data.height;

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

			var t = new h2d.TileGroup(tile, root);
			tiles.push(t);
			var p = -1;
			for( y in 0...height )
				for( x in 0...width ) {
					var tid = ldat[++p] - 1;
					if( tid < 0 ) continue;
					t.add(x * cellSize, y * cellSize, tl[tid]);
					var tp = tprops.props[tid];
					if( tp != null )
						col[p] = new Collide(tp.collide + 1);
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
		}
	}

	public function next(onEnd) {
		var oparts = parts, otiles = tiles;
		s = switch( s ) {
		case Winter: Autumn;
		case Autumn: Winter;
		};
		hasSnow = 0.;
		init();
		for( t in tiles )
			t.alpha = 0;
		game.waitUntil(function(dt) {
			for( t in tiles )
				t.alpha += 0.003 * dt;
			if( tiles[0].alpha > 1 ) {
				for( t in tiles )
					t.alpha = 1;
				for( t in otiles )
					t.remove();
				hasSnow = 0.01;
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
		if( hasSnow > 0 ) {
			hasSnow += dt / 60;
			if( hasSnow > 1 ) hasSnow = 1;
			for( i in 0...getPartCount() ) {
				var p = new SnowPart(parts.tile);
				p.x = Math.random() * width * cellSize;
				p.y = Math.random() * height * cellSize * 0.5;
				p.vy = 0.2 + Math.random() * 0.3;
				p.a = 0;
				parts.add(p);
			}
		}
	}

}