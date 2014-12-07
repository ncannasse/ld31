package ent;

class Npc extends Entity {

	override function init() {
		super.init();
		setBounds(7, 7);
		anim.x = Std.int(anim.x);
		anim.y = Std.int(anim.y);
		anim.speed = 0;
		anim.onAnimEnd = function() { anim.speed = 0; };
		switch( kind ) {
		case EFisher:
			var fil = new h2d.Bitmap(h2d.Tile.fromColor(0xEDEEF1, 1, 5 * 7), anim);
			fil.x = 3;
		case EOldTree:
			if( game.level.s != Autumn ) anim.alpha = 0;
		default:
		}
	}

	var curSeason : Null<Level.Season>;

	override function update(dt:Float) {

		if( kind == EChild ) {
			if( game.level.s == Summer && game.hasItem(Friend) && game.get(ECave) == null ) {
				x = 6;
				y = 10;
			} else {
				x = 28;
				y = 16;
			}
		}

		if( curSeason != game.level.s ) {
			curSeason = game.level.s;
			var view : Entity.Kind = switch( kind ) {
			case EDog: curSeason == Spring ? ETomb : EDog;
			case EWomen: switch( curSeason ) {
				case Summer: EWomen;
				case Winter: EWomen3;
				default: EWomen2;
				}
			case EChild:
				if( curSeason != Spring ) anim.speed = 0;
				curSeason == Spring ? EChildCry : EChild;
			case EOldTree:
				EHouse; // remap
			default:
				kind;
			}
			anim.frames = game.sprites[view.getIndex()];
		}

		switch( kind ) {
		case EOldTree:
			if( curSeason == Autumn ) {
				anim.alpha += 0.003 * dt;
				if( anim.alpha > 1 ) anim.alpha = 1;
			} else {
				anim.alpha -= 0.003 * dt;
				if( anim.alpha < 0 ) anim.alpha = 0;
			}
			anim.speed = 6;
		default:
		}

		if( anim.speed == 0 )
			switch( kind ) {
			case EDog:
				anim.speed = 24;
			case EWomen:
				anim.speed = 10;
			case EChild:
				if( game.level.s == Spring ) {
					anim.speed = 7;
				} else if( trand(0.01) ) {
					var way = 1;
					anim.speed = 1;
					anim.onAnimEnd = function() { };
					game.waitUntil(function(dt) {
						if( game.level.s == Spring ) {
							anim.speed = 0;
							return true;
						}
						anim.speed += dt * 0.4 * way;
						if( anim.speed > 20 ) {
							anim.speed = 20;
							way = -1;
						}
						if( anim.speed < 0 ) {
							anim.speed = 0;
							anim.currentFrame = 0;
							return true;
						}
						return false;
					});
				}
			case EOldWomen:
				var k = switch( game.level.s ) {
				case Winter: 0.03;
				case Autumn: 0.01;
				default: 0;
				}
				if( trand(k) ) {
					var x = x, t = 0.;
					game.waitUntil(function(dt) {
						t += dt / 60;
						if( t > 0.5 ) {
							this.x = x;
							return true;
						}
						this.x = x + hxd.Math.srand(0.05);
						return false;
					});
				}
			case EFisher:
				if( anim.speed == 0 && trand(0.01) )
					anim.speed = 8;
			case EMerchant:
				if( anim.speed == 0 && trand(0.01) )
					anim.speed = 16;
			default:
			}
	}

}