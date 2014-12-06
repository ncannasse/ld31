import hxd.Key in K;

class Game extends hxd.App {

	static var _props = hxd.Save.load({
		x : 16.,
		y : 62.,
		fog : null,
	});

	var level : Level;
	var hero : ent.Hero;
	public var sprites : Array<h2d.Tile>;
	public var props = _props;

	var fogData : haxe.io.Bytes;
	var fog : h2d.Bitmap;

	override function init() {
		sprites = hxd.Res.sprites.toTile().grid(9,-5,-8);

		var tfog = h2d.Tile.fromTexture(new h3d.mat.Texture(146, 85));
		fogData = props.fog == null ? haxe.io.Bytes.alloc(tfog.width * tfog.height * 4) : haxe.Unserializer.run(props.fog);
		if( props.fog == null )
			for( i in 0...tfog.width * tfog.height )
				fogData.set(i * 4 + 3, 0xFF);
		tfog.getTexture().uploadPixels(new hxd.Pixels(tfog.width, tfog.height, fogData, BGRA));

		fog = new h2d.Bitmap(tfog);
		fog.scale(7);
		s2d.add(fog, 2);


		level = new Level();
		level.init();
		hero = new ent.Hero(props.x, props.y);
		clearFog(true);
	}

	override function update( dt : Float ) {
		var dx = 0., dy = 0.;
		if( K.isDown(K.LEFT) || K.isDown("Q".code) || K.isDown("A".code) )
			dx--;
		if( K.isDown(K.UP) || K.isDown("Z".code) || K.isDown("W".code) )
			dy--;
		if( K.isDown(K.DOWN) || K.isDown("S".code) )
			dy++;
		if( K.isDown(K.RIGHT) || K.isDown("D".code) )
			dx++;
		if( dx != 0 && dy != 0 ) {
			dx /= Math.sqrt(2);
			dy /= Math.sqrt(2);
		}
		hero.x += dx * dt * 0.2;
		hero.y += dy * dt * 0.2;

		clearFog();

		#if debug
		if( K.isDown(K.CTRL) && K.isPressed("S".code) )
			save();
		#end
	}

	function clearFog(force=false) {
		var ix = Std.int(hero.x);
		var iy = Std.int(hero.y);
		var changed = force;
		var D = 6;
		for( dx in -D...D+1 )
			for( dy in -D...D+1 ) {
				var x = ix + dx;
				var y = iy + dy;
				if( x < 0 || x >= level.width || y < 0 || y >= level.height ) continue;
				var ex = x + 0.5 - hero.x, ey = y + 0.5 - hero.y;
				var d = Math.sqrt(ex * ex + ey * ey);
				var k = Std.int(d < 5 ? 0 : (d - 5) * 128);
				if( k > 0xFF ) k = 0xFF;
				var p = (x + y * level.width) * 4 + 3;
				var f = fogData.get(p);
				if( f <= k ) continue;
				fogData.set(p, k);
				changed = true;
			}
		if( changed )
			fog.tile.getTexture().uploadPixels(new hxd.Pixels(fog.tile.width, fog.tile.height, fogData, BGRA));
	}

	function save() {
		props.x = hero.x;
		props.y = hero.y;
		hxd.Save.save(props);
	}

	public static var inst : Game;
	static function main() {
		hxd.Res.initEmbed();
		Data.load(hxd.Res.data.entry.getBytes().toString());
		inst = new Game();
	}

}