package ent;

class House extends Entity {

	override function init() {
		super.init();
		var t = hxd.Res.house.toTile().split(5)[0];
		t.dx = -8;
		t.dy = -13;
		anim.frames = [t];
		setBounds(14, 10);
	}

	override function update(dt:Float) {
		if( !game.hero.lock && game.hero.collide(this) && game.hero.y < y ) {
			if( game.level.s == End ) return;
			game.hero.anim.visible = false;
			game.askNpc(game.hero, ["Maybe I can rest here a little..."], function(b) {
				if( !b ) {
					game.hero.anim.visible = true;
					game.hero.y = y + 0.01;
					return;
				} else {
					game.hero.lock = true;
					game.level.next(function() {
						game.hero.y = y + 0.01;
						game.hero.anim.visible = true;
						game.hero.lock = false;
						game.enterSeason();
					});
					var t = new h2d.Bitmap(hxd.Res.house.toTile().split(5)[game.level.s.toInt()], anim);
					t.tile.dx = -8;
					t.tile.dy = -13;
					t.alpha = 0;
					game.waitUntil(function(dt) {
						t.alpha += 0.003 * dt;
						if( t.alpha > 1 ) {
							t.remove();
							anim.play([t.tile]);
							return true;
						}
						return false;
					});
				}
			});
		}
	}

}