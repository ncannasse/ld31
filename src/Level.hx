@:enum
abstract Collide(Int) {
	public var No = 0;
	public var Full = 1;
	public function new(v:Int) {
		this = v;
	}
}


class Level {

	public var id : Int;
	public var root : h2d.Layers;
	public var width : Int;
	public var height : Int;
	var col : Array<Collide>;
	var data : Data.World;
	var game : Game.GameData;
	public var cellSize = 7;

	public function new(id, gd) {
		this.id = id;
		game = gd;
	}

	public function collide(x:Float, y:Float) {
		var ix = Std.int(x), iy = Std.int(y);
		if( ix < 0 || iy < 0 || ix >= width || iy >= height ) return true;
		return col[ix + iy * width] != No;
	}

	public function init() {
		root = new h2d.Layers();
		data = Data.world.all[id];
		width = data.width;
		height = data.height;
		col = [for( i in 0...width * height ) No];
		var tile = hxd.Res.world.toTile();
		var tl = tile.grid(cellSize);
		var tprops = data.props.getTileset(Data.world, "world.png");
		for( l in data.layers ) {
			var ldat = l.data.data.decode();

			if( l.name == "monster" ) {
				var p = -1;
				for( y in 0...height )
					for( x in 0...width ) {
						var tid = ldat[++p] - 1;
						if( tid < 0 ) continue;
						switch( tid ) {
						case 26:
							new ent.Spider(game.mode, x + 0.5, y + 1);
						default:
							throw "Unknown entity #" + tid;
						}
					}
				continue;
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
	}

	public function update(dt:Float) {
		var g = Game.inst;
		var sx = game.hero.x * cellSize - g.s2d.width / 6;
		var sy = game.hero.y * cellSize - g.s2d.height / 6;
		if( sx < 0 ) sx = 0;
		if( sy < 0 ) sy = 0;
		if( sx + g.s2d.width / 3 > width * cellSize ) sx = width * cellSize - g.s2d.width / 3;
		if( sy + g.s2d.height / 3 > height * cellSize ) sy = height * cellSize - g.s2d.height / 3;
		root.x = -Std.int(sx);
		root.y = -Std.int(sy);
	}

}