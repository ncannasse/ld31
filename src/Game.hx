import hxd.Key in K;
import hxd.Res;

enum ItemKind {
	Memory;
	House;
	Mantle;
	Snow;
	Bone;
	Wood;
	Axe;
	Friend;
	Cave;
	Meet;
	Love;
	MantleGirl;
	GaveWood;
}

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
	var items : Array<ItemKind>;
	var memoryCount : Int;
	var end : Bool;
	public var hasAction : Bool;

	override function init() {

		entities = [];
		items = [];

		var grid = hxd.Res.sprites.toTile().grid(9, -5, -8);
		var line = 0;
		sprites = [for( frames in [3, 4, 4, 4, 8, 1, 6, 4, 6, 4, 6, 1, 6, 6] ) { var a = [for( i in 0...frames ) grid[line * 13 + i]]; line++; a; } ];

		parts = new h2d.SpriteBatch(hxd.Res.sprites.toTile(), s2d);
		parts.hasUpdate = true;

		s2d.zoom = 3;
		events = [];

		var time : Level.Season = Winter;
		#if debug
		time = Summer;
		#end

		level = new Level(time);
		level.init();

		playMusic();

		hero = new ent.Hero(4.5, 3.5);
		hero.lock = true;
		new ent.Item(EMemory, 13, 15);
		new ent.Npc(EOldTree, 2, 3);

		#if debug

		hero.lock = false;
		level.initSnow();

		autoGet(Friend);
		autoGet(Memory);
		autoGet(Memory);
		autoGet(Cave);

		#else

		blurIn(function() {
			wait(0, function() {
				talk("Here we are, back again...", function() {
					talk("How am I supposed to live with that?", function() {
						level.initSnow();
					});
				});
			});
		});

		#end
	}

	function autoGet( k ) {
		getItem(k, true);
		if( k == Memory ) {
			var e = get(EMemory);
			if( e != null ) e.remove();
		}
	}

	function playMusic() {
		var r = Res.music;
		r.loop = true;
		r.play();
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

	public function talk( text : String, ?onEnd : Void -> Void ) {
		if( colorMat == null ) {
			colorMat = new h2d.filter.ColorMatrix();
			level.root.filters.push(colorMat);
		}
		hero.lock = true;
		colorMatWay = 1;
		wait(1, function() {
			var t = getText(s2d);
			t.text = text;
			t.x = Std.int((s2d.width - t.textWidth * t.scaleX) * 0.5);
			t.y = 30;
			textAppear(t, function() {
				waitUntil(function(dt) {
					t.alpha -= 0.1 * dt;
					if( t.alpha < 0 ) {
						t.remove();
						colorMatWay = -1;
						hero.lock = false;
						if( onEnd != null ) onEnd();
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
			if( action() && !end ) {
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
								g.remove();
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


	var SEASONS = [];

	public function enterSeason() {

		if( SEASONS[level.s.toInt()] ) {
			level.startSnow();
			return;
		}
		SEASONS[level.s.toInt()] = true;

		switch( level.s ) {
		case Autumn:
			talk("The house is warm, but why do I feel so lonely?", level.startSnow);
		case Summer:
			talk("So hot...", function() talk("Feels like hell."));
		case Spring:
			talk("Rain theorem proved once more.", function() talk("\"It always rain when you forget your umbrella\"", level.startSnow));
		case Winter:
			talk("Here we are, back again...", function() talk("How am I supposed to live with that?", level.startSnow));
		}
	}

	public function talkTo( e : ent.Entity ) {
		switch( e.kind ) {
		case EOldWomen:
			switch( level.s ) {
			case Winter:
				talkNpc(e,[
					"It's freezing more than it used to be...",
					"I hope I had a warm mantle to cover my old bones..."
				]);
			case Autumn:
				talkNpc(e, [
					"At my age, I don't think I will live through the upcoming winter...",
					"What color was my mantle?",
					"Was it orange?",
					"Or blue?",
					"Or red as blood?",
				]);
			case Summer:
				if( hasItem(Mantle) ) {
					talkNpc(e, ["It's so hot I don't need a mantle!"]);
					return;
				}
				talkNpc(e, [
					"It's so hot!",
					"If someone could bring me something cold, I would give him a present...",
				],function() {
					if( hasItem(Snow) ) {
						askNpc(e, ["Oh !!!", "You have some snow, at this season?", "Would you give it me?", "I will exchange for something I don't need."], function(b) {
							if( !b ) {
								talkNpc(e, ["You stringy!"]);
								return;
							}
							talkNpc(e, ["Thank you!", "Here's for you!"], function() {
								wait(0.5, function() getItem(Mantle));
								hero.lock = true;
								wait(1.5, function() talk("To date I still wonder why she gave me her mantle.."));
							});
						});
					}
				});
			case Spring:
				talkNpc(e, [
					"Spring is the best season don't you think?",
					"Makes me feel young again, when I was in love.",
				]);
			}
		case EFisher:
			switch( level.s ) {
			case Winter:
				talkNpc(e, [
					"The clouds are strange these days...",
					"I don't seem to be able to catch any fish.",
					"What will happen if they is no more of them?"
				]);
			case Autumn:
				talkNpc(e, [
					"This new bridge is causing trouble with the fish...",
					"They can sense every small change in this world.",
					"And they are affected by it, as we are."
				]);
			case Summer:

				if( hasItem(Axe) ) {
					talkNpc(e, [
						"I like to fish so much, I can't help it...",
						"But cloud fishes, they like bones, and they eat a lot of them.",
						"But thanks to you I have a lot now!"
					]);
					return;
				}

				talkNpc(e, [
					"I like to fish so much, I can't help it...",
					"But cloud fishes, they like bones, and I'm running out of them.",
					"I have some idea to get more, but it's not a good thing to do..."
				],function() {
					if( hasItem(Bone) ) {
						askNpc(e, [
							"Oh!",
							"You got bones?",
							"Give them to me!",
							"Please!"
						], function(b) {
							if( !b ) {
								talkNpc(e, ["..."]);
								return;
							}
							talkNpc(e, ["Yeah!", "Here's for you!"], function() {
								getItem(Axe);
							});
						});
					}
				});
			case Spring:

				talkNpc(e, ["I wonder where I put my axe...","It could be useful, some day..."]);

			default:
			}
		case EMerchant:

			switch( level.s ) {
			case Winter:
				if( hasItem(House) ) {
					talkNpc(e, [
						"Now my debt is paid...",
						"Please don't come anymore to talk to me."
					]);
					return;
				}

				askNpc(e, [
					"So, you came back after all...",
					"And now you want me to build that house we talk about for you, right?"
				], function(b) {
					if( !b ) return;

					hero.lock = true;
					var count = 0;
					function play() {
						count++;
						if( count == 10 ) {
							getItem(House);
							return;
						}
						Res.sfx.tin.play();
						wait(0.7, play);
					}
					play();
				});
			case Autumn:
				talkNpc(e, [
					"Thank you for the wood!",
					"Thanks to you I could build this new bridge!",
					"Come to meet me another time and ask me anything in return!",
				]);

			case Summer:

				if( hasItem(GaveWood) ) {
					talkNpc(e, ["Thank you for the wood.", "Building this bridge will take me some time now."]);
					return;
				}

				talkNpc(e, [
					"I got this project, you see...",
					"It's to build a bridge to the next island.",
					"Wonderful dream, don't you think?",
					"But I need some wood to build it...",
				], function() {

					if( hasItem(Wood) ) {
						askNpc(e, ["You will give it to me, because you're the right person."], function(b) {
							if( !b ) {
								talkNpc(e,["That is your destiny from the very beginning..."]);
								return;
							}
							talkNpc(e, ["You were destinated from the very beginning...", "But thank you.", "Once I have finished the bridge, I will build you whatever you want.", "Come to see me another time..."], function() getItem(GaveWood));
						});
					} else
						talkNpc(e, ["You will help me, because you're the right person."]);

				});


			case Spring:

				if( hasItem(Love) ) {
					talkNpc(e, [
						"WHAT?",
						"That's what you're asking to me?",
						"You want me to build you a HOUSE?",
						"Like, a full HOUSE?",
						"I know I promised...",
						"But...",
						"I'll need time to prepare...",
					]);
				} else {
					talkNpc(e, [
						"Don't forget to ask me if you want to build something."
					]);
				}
			}
		case EDog:
			switch( level.s ) {
			case Spring:

				talk("I regret him...", function() talk("Or was it she?", function() {
					if( !hasItem(Bone) ) {
						talk("Oh!", function() talk("Some bones are showing...", function() talk("I'll get them as a souvenir...", function() {
							getItem(Bone);
						})));
					}
				}));

			default:
				talkNpc(e, ["Woof!"], function() {
					talk("I don't remember if I like dogs, but this one is cute...");
				});
			}
		case EChild:
			switch( level.s ) {
			case Autumn:

				if( hasItem(Friend) ) {
					talkNpc(e, ["Let's meet another time, my friend, and I'll teach you my secret."]);
					return;
				}

				askNpc(e, ["I'm bored...","Do you want to play with me?"], function(b) {
					if( !b ) {
						talkNpc(e, ["I hate you!"]);
						return;
					}
					hero.lock = true;
					waitUntil(function(dt) {
						hero.anim.alpha -= 0.003 * dt;
						e.anim.alpha -= 0.003 * dt;
						if( e.anim.alpha <= 0 ) {
							talk("We had a lot of fun, this day.", function() {
								talk("I wished it would never end.", function() {
									hero.lock = true;
									waitUntil(function(dt) {
										hero.anim.alpha += 0.01 * dt;
										e.anim.alpha += 0.01 * dt;
										if( hero.anim.alpha > 1 ) {
											hero.anim.alpha = e.anim.alpha = 1;
											askNpc(e, ["Thank you for playing with me, mister!", "Is it ok for someone like me to be your friend?"], function(b) {
												if( !b ) {
													talkNpc(e, ["I hate you!"]);
													return;
												}
												hero.lock = true;
												wait(0.5, function() { getItem(Friend); hero.lock = false;});
											});
											return true;
										}
										return false;
									});
								});
							});
							return true;
						}
						return false;
					});
				});

			case Summer:

				if( get(ECave) != null ) {
					talkNpc(e, ["Hope you like my little secret!"]);
					return;
				}

				askNpc(e, ["Since we have been friend for some time now...", "Do you want to learn about my secret?"], function(b) {
					if( !b ) {
						talkNpc(e, ["I hate you!"]);
						return;
					}
					talkNpc(e, ["Let me show you!", "This is a secret passage!"], function() {
						getItem(Cave);
					});
				});

			case Winter:

				if( hasItem(Snow) ) {
					talkNpc(e, ["You still have the snow from the other day with you?"]);
					return;
				}

				if( !hasItem(Friend) ) {
					talkNpc(e,["..."]);
					return;
				}

				askNpc(e, ["Hey, my friend!", "Let's play with snow!"], function(b) {
					if( !b ) {
						talkNpc(e, ["Did you kill someone?"]);
						return;
					}
					talk("Another day of fun!", function() {
						talkNpc(e, ["Hey, keep some snow with you, it's cold!"], function() getItem(Snow));
					});
				});

			case Spring:

				talkNpc(e, ["(crying)", "I MISS HIM!!!", "HE WAS MY FRIEND!!!"]);

			}

		case EWomen:

			switch( level.s ) {
			case Summer:
				talkNpc(e, ["I wanted to talk to you..."], function() {
					talk("It started like that, how could I say no?", function() {
						talkNpc(e, ["We've been together for some time now..."], function() {
							talk("Like I didn't know.", function() {
								talkNpc(e, ["I need my freedom back.", "I can't be your little bird anymore.", "Let's be friends, only friends."], function() {
									talk("It hurts...", function() talk("And what should I do now?"));
								});
							});
						});
					});
				});
			case Spring:
				if( !hasItem(Meet) ) {
					talk("I can't talk to her now, we have not met each other yet.");
					return;
				}
				if( hasItem(Love) ) {
					talkNpc(e, ["You will get us a home, right?", "And maybe we can have a dog too!"]);
					return;
				}
				askNpc(e, ["I've been thinking...", "We've been together for some time now...", "I think we should get a house, for us together."], function(b) {
					if( !b ) {
						talkNpc(e, ["Let's talk about it again later today."]);
						return;
					}
					talkNpc(e, ["Really?", "You would do that for me?", "A real home?", "I LOVE YOU!"], function() {
						getItem(Love);
						talk("Did she meant it, at least this time?", function() talkNpc(e, ["And maybe we can have a dog too!"]));
					});
				});
			case Winter:

				if( hasItem(Meet) ) {
					talkNpc(e, ["Hey!", "You're the funny guy from the other day?"]);
					return;
				}

				askNpc(e, ["Who are you?", "You want to talk we me?"], function(b) {
					if( !b ) {
						talkNpc(e, ["(weirdo)"]);
						return;
					}
					talk("You were beautiful, with your red dress.", function() {
						talkNpc(e, ["Ah ah ah!", "You're funny!"], function() {
							talk("Your laugh was worth all the stars in the sky.");
							getItem(Meet);
						});
					});
				});
			case Autumn:
				if( hasItem(MantleGirl) ) {
					talkNpc(e, ["It's weird.", "The mantle you gave me...", "I feel I have already weared it, before, or maybe after."]);
					return;
				}
				if( !hasItem(Mantle) ) {
					talkNpc(e, ["It will be winter soon.", "I'm still young, but it will be cold.", "Could you get a mantle for me?", "Please!"]);
					return;
				}
				askNpc(e, ["It will be winter soon.", "I'm still young, but it will be cold.", "Oh!", "You have a mantle for me?", "Thank you!"], function(b) {
					if( !b ) {
						talkNpc(e, ["...", "Who's mantle is that in the first place?"]);
						return;
					}
					talkNpc(e, ["Thank you!", "It fits me perfectly, like it was made for me!"], function() getItem(MantleGirl));
				});
			}

		case EOldTree:

			if( level.s != Autumn ) return;

			if( !hasItem(Axe) ) {
				talk("This old tree has died...", function() talk("I can't do anything for it anymore", function() talk("What have I done?")));
				return;
			}

			askNpc(e, ["Should I cut this tree?"], function(b) {
				if( !b ) {
					talk("When will this life finish?");
					return;
				}
				e.destroy();
				talk("At least I got some wood...", function() getItem(Wood));
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
		colorMat = null;
	}

	public function flash(onFlash,onEnd) {
		var c = new h2d.filter.ColorMatrix();
		s2d.filters = [c];
		var bright = 0., way = 1;
		waitUntil(function(dt) {
			bright += dt * 0.03 * way;
			c.matrix.identity();
			c.matrix.colorBrightness(bright);
			if( bright > 1 ) {
				bright = 1;
				way = -way;
				onFlash();
			}
			if( bright < 0 ) {
				bright = 0;
				s2d.filters = [];
				onEnd();
				return true;
			}
			return false;
		});
	}

	public function getItem( k : ItemKind, auto = false ) {
		Res.sfx.pick.play();
		items.push(k);
		switch( k ) {
		case Memory:
			hero.lock = !auto;
			switch( memoryCount++ ) {
			case 0:
				flash(function() {
					new ent.Npc(EOldWomen, 2, 11);
					new ent.Npc(EFisher, 11, 19);
					new ent.Npc(EMerchant, 9.6, 14);
					new ent.Item(EMemory, 26, 20);
				},function() {
					if( auto ) return;
					talk("Did I already meet them?");
				});
			case 1:
				flash(function() {
					new ent.Npc(EDog, 22, 14);
					new ent.Npc(EChild, 28, 16);
					new ent.Item(EMemory, 41, 16);
				},function() {
					if( auto ) return;
					talk("Maybe I will remember them better...");
				});
			case 2:
				flash(function() {
					new ent.Npc(EWomen, 44, 10);
				},function() {
					if( auto ) return;
					talk("My heart feels warm...", function() {
						talk("And it hurts too, deep inside...", function() {
							talk("What was that feeling named, again?");
						});
					});
				});
			default:
				hero.lock = false;
			}
		case House:
			hero.lock = !auto;
			flash(function() {
				new ent.House(EHouse, 18, 10);
			},function() {
				if( auto ) return;
				talkTo(get(EMerchant));
			});
		case Cave:
			Res.sfx.pick.play();
			hero.lock = !auto;
			flash(function() {
				new ent.Item(ECave, 6.5, 10);
				new ent.Item(ECave, 32, 16);
				new ent.Item(ECave, 24, 10);
			},function() {
				hero.lock = false;
			});
		case Axe:
			if( !auto ) talk("And that's how I came to acquire an axe...", function() talk("I was so frighten, it was smelling... blood.", function() talk("My blood?")));
		case MantleGirl, GaveWood:
			if( hasItem(MantleGirl) && hasItem(GaveWood) ) {
				hero.lock = true;
				blurIn();
				wait(5, function() talk("Thank you for playing.", function() {
					end = true;
					talk("The End...");
				}));
				blurWay *= -1;
				blur.sigma = 0;
			}
		default:
		}
	}

	public function get(k) {
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

		//#if debug
		if( K.isDown(K.SHIFT) ) dt *= 3;
		//#end

		hasAction = K.isPressed(K.SPACE) || K.isPressed("E".code);
		for( e in events.copy() )
			if( e(dt) )
				events.remove(e);
		for( e in entities.copy() )
			e.update(dt);
		level.update(dt);
		if( blur != null ) {
			blur.sigma += 0.005 * dt * blurWay;
			if( blur.sigma >= 5 ) blur.sigma = 5;
			if( blur.sigma <= 0.2 && blurWay < 0 ) {
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

		level.root.ysort(1);
	}

	public static var inst : Game;
	static function main() {
		hxd.Res.initEmbed({ compressSounds : true });
		Data.load(hxd.Res.data.entry.getBytes().toString());
		inst = new Game();
	}

}