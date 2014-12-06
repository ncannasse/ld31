
class Level {

	public var width : Int;
	public var height : Int;
	var data : Data.World;
	var game : Game;

	public function new() {
		game = Game.inst;
	}

	public function init() {
		data = Data.world.all[0];
		width = data.width;
		height = data.height;
		var tile = hxd.Res.world.toTile();
		var tl = tile.grid(7);
		for( l in data.layers ) {
			var ldat = l.data.data.decode();
			var t = new h2d.TileGroup(tile, game.s2d);
			var p = 0;
			for( y in 0...height )
				for( x in 0...width ) {
					var tid = ldat[p++] - 1;
					if( tid < 0 ) continue;
					t.add(x * 7, y * 7, tl[tid]);
				}
			if( l.name == "bg" ) {
				var tbuild = new cdb.TileBuilder(data.props.getTileset(Data.world, "world.png"), Std.int(tile.width / 7), Std.int(tile.width / 7) * Std.int(tile.height / 7));
				var out = tbuild.buildGrounds(ldat, width);
				var i = 0;
				var max = out.length;
				while( i < max ) {
					var x = out[i++];
					var y = out[i++];
					var tid = out[i++];
					t.add(x * 7, y * 7, tl[tid]);
				}
			}
		}
	}

}