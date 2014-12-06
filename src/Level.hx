@:enum
abstract Collide(Int) {
	public var No = 0;
	public var Full = 1;
	public function new(v:Int) {
		this = v;
	}
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

	public var id : Int;
	public var root : h2d.Layers;
	public var width : Int;
	public var height : Int;
	var col : Array<Collide>;
	var data : Data.World;
	var game : Game;
	public var cellSize = 7;
	var parts : h2d.SpriteBatch;

	public function new(id) {
		this.id = id;
		game = Game.inst;
		root = new h2d.Layers(game.s2d);
		data = Data.world.all[id];
		width = data.width;
		height = data.height;
		col = [for( i in 0...width * height ) No];
	}

	public function collide(x:Float, y:Float) {
		var ix = Std.int(x), iy = Std.int(y);
		if( ix < 0 || iy < 0 || ix >= width || iy >= height ) return true;
		return col[ix + iy * width] != No;
	}

	public function init() {
		var tile = hxd.Res.world.toTile();
		var tl = tile.grid(cellSize);
		var tprops = data.props.getTileset(Data.world, "world.png");
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
				t.y += 2;
			}
		}
		var t = switch( id ) {
		case 2: h2d.Tile.fromColor(0x502904, 2, 1);
		default: h2d.Tile.fromColor(0xFFFFFF);
		}
		parts = new h2d.SpriteBatch(t, root);
		parts.hasUpdate = true;
		parts.hasRotationScale = id == 2;
		root.add(parts, 2);
	}

	function getPartCount() {
		return switch( id ) {
		case 2: 1;
		default: 4;
		}
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