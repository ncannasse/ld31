
class ShooterLevel extends Level {

	override function update( dt : Float ) {
		super.update(dt);
		root.y = 0;
		root.x = 0;
		while( Math.random() < 0.2 ) {
			var c = 0x80 + Std.random(0x80);
			game.addPart(hxd.Res.sprites.toTile().sub(116,Std.random(3),1,1), Math.random() * width, 0, 0, (0.1 + Math.random() * 0.4) * 0.3);
		}
	}

}