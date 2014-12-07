import hxd.Key in K;
import hxd.Res;

class Game extends hxd.App {

	public var entities : Array<ent.Entity>;
	public var hero : ent.Hero;
	public var level : Level;
	public var sprites : Array<Array<h2d.Tile>>;
	var parts : h2d.SpriteBatch;
	var blur : h2d.filter.Blur;
	var blurWay : Float = 0.;
	var blurEnd : Void -> Void;
	var events : Array < Float -> Bool > ;
	var colorMat : h2d.filter.ColorMatrix;
	var colorMatValue : Float = 0;
	var colorMatWay : Float = 1;
	var answerResult : Bool;
	var items : Array<ent.Entity.Kind>;
	var debug : h2d.Text;
	var memoryCount : Int;
	public var hasAction : Bool;

	override function init() {

		entities = [];
		items = [];

		var grid = hxd.Res.sprites.toTile().grid(9, -5, -8);
		var line = 0;
		sprites = [for( frames in [3, 4, 4, 4, 8] ) { var a = [for( i in 0...frames ) grid[line * 13 + i]]; line++; a; } ];

		parts = new h2d.SpriteBatch(hxd.Res.sprites.toTile(), s2d);
		parts.hasUpdate = true;

		s2d.zoom = 3;
		events = [];

		level = new Level(Winter);
		level.init();
		hero = new ent.Hero(4.5, 3.5);
		hero.lock = true;
		new ent.Item(EMemory, 13, 15);

		/*
		blurIn(function() {
			wait(0, function() {
				talk("Here we are, back again...", function() {
					talk("Who am I supposed to be ?", function() {
						hero.lock = false;
						level.initSnow();
					});
				});
			});
		});
		*/
		hero.lock = false;
		level.initSnow();

		#if debug
		debug = getText(s2d);
		#end


		autoGet(EMemory);
		autoGet(EHouse);
	}

	function autoGet( k ) {
		getItem(k, true);
		var e = get(k);
		if( e != null ) e.remove();
	}

	function action() {
		if( hasAction ) {
			hasAction = false;
			return true;
		}
		return false;
	}

	public function askNpc( e : ent.Entity, texts : Array<String>, ?onEnd ) {
		function next() {
			var t = texts.shift();
			if( t == null ) {
				hero.lock = false;
				if( onEnd != null ) onEnd(answerResult);
			} else {
				talNpcSeq(e, t, next, texts.length == 0);
			}
		}
		hero.lock = true;
		next();
	}

	public function talk( text : String, onEnd : Void -> Void ) {
		if( colorMat == null ) {
			colorMat = new h2d.filter.ColorMatrix();
			level.root.filters = [colorMat];
		}
		hero.lock = true;
		colorMatWay = 1;
		wait(1, function() {
			var t = getText(s2d);
			t.text = text;
			t.x = Std.int((s2d.width - t.textWidth * t.scaleX) * 0.5);
			t.y = 36;
			textAppear(t, function() {
				waitUntil(function(dt) {
					t.alpha -= 0.1 * dt;
					if( t.alpha < 0 ) {
						t.remove();
						colorMatWay = -1;
						onEnd();
						return true;
					}
					return false;
				});
			}, 0.2);
		});
	}

	function textAppear( t : h2d.Text, onEnd : Void -> Void, speed = 0.5 ) {
		var text = t.splitText(t.text);
		t.text = "";
		var pos = 0., ipos = 0;
		waitUntil(function(dt) {
			pos += dt * speed;
			var p = Std.int(pos);
			if( p != ipos && ipos <= text.length ) {
				t.text = text.substr(0, p);
				ipos = p;
			}
			if( action() ) {
				if( p >= text.length ) {
					onEnd();
					return true;
				} else
					speed = 2;
			}
			return false;
		});
	}

	function talkNpc( e : ent.Entity, texts : Array<String>, ?onEnd ) {
		function next() {
			var t = texts.shift();
			if( t == null ) {
				hero.lock = false;
				if( onEnd != null ) onEnd();
			} else {
				talNpcSeq(e, t, next);
			}
		}
		hero.lock = true;
		next();
	}

	function makeDialog( text : String, e : ent.Entity ) {
		var t = getText();
		t.maxWidth = 50;
		t.text = text;
		t.x = 5;
		t.y = 4;
		t.textColor = 0x404040;
		t.dropShadow.alpha = 0.1;
		while( t.textWidth / t.textHeight < 4 / 3 && t.maxWidth < 150 ) {
			t.maxWidth += 10;
			t.text = text;
		}
		var g = new h2d.ScaleGrid(Res.dialog.toTile(), 5, 5);
		g.width = Std.int(t.textWidth * t.scaleX + 10);
		g.height = Std.int(t.textHeight * t.scaleX + 6);
		g.x = Std.int(e.anim.x) - (g.width >> 1);
		g.y = Std.int(e.anim.y) - g.height - 12;
		g.addChild(t);

		var ti = new h2d.Bitmap(Res.dialogTick.toTile(), g);
		ti.x = (g.width >> 1) - 6;
		ti.y = g.height - 1;
		s2d.add(g, 2);

		if( g.x < 5 ) {
			ti.x -= 5 - g.x;
			g.x = 5;
		}

		if( g.x + g.width > 330 ) {
			ti.x += g.x + g.width - 330;
			g.x = 330 - g.width;
		}
		return { g : g, t : t, ti : ti };
	}

	function talNpcSeq( e : ent.Entity, text : String, onEnd : Void -> Void, ask = false ) {
		var d = makeDialog(text, e);
		var g = d.g, t = d.t, ti = d.ti;

		g.alpha = ti.alpha = 0;
		t.visible = false;

		function hide() {
			waitUntil(function(dt) {
				g.alpha -= 0.1 * dt;
				t.alpha -= 0.1 * dt;
				ti.alpha -= 0.1 * dt;
				if( g.alpha < 0 ) {
					g.remove();
					return true;
				}
				return false;
			});
		}

		waitUntil(function(dt) {
			g.alpha = ti.alpha += 0.1 * dt;
			if( g.alpha > 1 ) {
				g.alpha = ti.alpha = 1;
				t.visible = true;
				textAppear(t, function() {
					hide();
					if( ask ) {
						var d = makeDialog("Yes\nNo", hero);
						var cursor = new h2d.Bitmap(Res.cursor.toTile(), d.g);
						var choice = true;
						var time = 0.;
						cursor.y = 2;
						waitUntil(function(dt) {
							time += dt;
							cursor.x = Math.sin(time * 0.3) - 4;
							if( K.isPressed(K.UP) || K.isPressed(K.DOWN) || K.isPressed("Z".code) || K.isPressed("W".code) || K.isPressed("S".code) ) {
								choice = !choice;
								Res.sfx.cursor.play();
								cursor.y = choice ? 2 : 12;
							}
							if( action() ) {
								answerResult = choice;
								if( choice ) Res.sfx.valid.play() else Res.sfx.cancel.play();
								cursor.remove();
								g = d.g;
								t = d.t;
								ti = d.ti;
								hide();
								onEnd();
								return true;
							}
							return false;
						});
					} else {
						onEnd();
					}
				});
				return true;
			}
			return false;
		});
	}

	public function hasItem(k) {
		return items.indexOf(k) >= 0;
	}

	public function enterSeason() {
	}

	public function talkTo( e : ent.Entity ) {
		switch( [e.kind, level.s] ) {
		case [EOldWomen, Winter]:
			talkNpc(e,[
				"It's freezing more than it used to be...",
				"I hope I had a warm mantle to cover my old bones..."
			]);
		case [EFisher, _]:
			talkNpc(e, [
				"The clouds are strange these days...",
				"I don't seem to be able to catch any fish.",
				"What will happen if they is no more of them ?"
			]);
		case [EMerchant, Winter]:

			if( hasItem(EHouse) ) {
				talkNpc(e, [
					"Now my debt is paid...",
					"Please don't come anymore to talk to me."
				]);
				return;
			}

			askNpc(e, [
				"So, you came back after all...",
				"And now you want me to build that house we talk about for you, right ?"
			], function(b) {
				if( !b ) return;

				hero.lock = true;
				var count = 0;
				function play() {
					count++;
					if( count == 10 ) {
						getItem(EHouse);
						return;
					}
					Res.sfx.tin.play();
					wait(0.7, play);
				}
				play();
			});
		default:
		}
	}

	function getText(?parent) {
		var t = new h2d.Text(hxd.Res.font.toFont(), parent);
		t.scale(2 / 3);
		t.textColor = 0xF0F0F0;
		t.dropShadow = { dx : 1, dy : 1, color : 0, alpha : 0.4 };
		return t;
	}

	public function wait( t : Float, onEnd : Void -> Void ) {
		waitUntil(function(dt) {
			t -= dt / 60;
			if( t < 0 ) {
				onEnd();
				return true;
			}
			return false;
		});
	}

	public function waitUntil( callb : Float -> Bool ) {
		events.push(callb);
	}

	function blurIn(?onEnd) {
		blur = new h2d.filter.Blur(2, 3);
		level.root.filters = [blur];
		blurWay = -1;
		blurEnd = onEnd;
	}

	function flash(onFlash,onEnd) {
		var c = new h2d.filter.ColorMatrix();
		colorMat = null;
		blur = null;
		level.root.filters = [c];
		var bright = 0., way = 1;
		waitUntil(function(dt) {
			bright += dt * 0.1 * way;
			c.matrix.identity();
			c.matrix.colorBrightness(bright);
			if( bright > 1 ) {
				bright = 1;
				way = -way;
				onFlash();
			}
			if( bright < 0 ) {
				bright = 0;
				level.root.filters = [];
				onEnd();
				return true;
			}
			return false;
		});
	}

	public function getItem( k : ent.Entity.Kind, auto = false ) {
		Res.sfx.pick.play();
		items.push(k);
		switch( k ) {
		case EMemory:
			hero.lock = !auto;
			switch( memoryCount++ ) {
			case 0:
				flash(function() {
					new ent.Npc(EOldWomen, 2, 11);
					new ent.Npc(EFisher, 11, 19);
					new ent.Npc(EMerchant, 9.6, 14);
					new ent.Item(EMemory, 23, 12);
				},function() {
					if( auto ) return;
					talk("Did I already meet them ?", function() {
						hero.lock = false;
					});
				});
			case 1:
				trace("TODO");
			}
		case EHouse:
			hero.lock = !auto;
			flash(function() {
				new ent.House(EHouse, 18, 10);
			},function() {
				if( auto ) return;
				talkTo(get(EMerchant));
			});
		default:
		}
	}

	function get(k) {
		for( e in entities )
			if( e.kind == k ) return e;
		return null;
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

		#if debug
		if( K.isDown(K.SHIFT) ) dt *= 3;
		#end

		hasAction = K.isPressed(K.SPACE) || K.isPressed("E".code);
		for( e in events.copy() )
			if( e(dt) )
				events.remove(e);
		for( e in entities.copy() )
			e.update(dt);
		level.update(dt);
		if( blur != null ) {
			blur.sigma -= 0.005 * dt;
			if( blur.sigma <= 0.2 ) {
				blur = null;
				level.root.filters = [];
				if( blurEnd != null ) blurEnd();
			}
		}
		if( colorMat != null ) {
			colorMatValue += colorMatWay * 0.01 * dt;
			if( colorMatValue > 1 ) colorMatValue = 1;
			if( colorMatValue < 0 ) colorMatValue = 0;
			colorMat.matrix.identity();
			colorMat.matrix.colorSaturation(1 - colorMatValue * 0.5);
			colorMat.matrix.colorHue( -colorMatValue * 0.1);
			colorMat.matrix.colorBrightness( -colorMatValue * 0.2 );
			colorMat.matrix.colorContrast( -colorMatValue * 0.2 );
			if( colorMatValue == 0 ) {
				colorMat = null;
				level.root.filters = [];
			}
		}
		if( debug != null ) debug.text = hero.lock ? "LOCK" : "";

		level.root.ysort(1);
	}

	public static var inst : Game;
	static function main() {
		hxd.Res.initEmbed({ compressSounds : true });
		Data.load(hxd.Res.data.entry.getBytes().toString());
		hxd.Res.music.loop = true;
		hxd.Res.music.play();
		inst = new Game();
	}

}