
class Part extends h2d.SpriteBatch.BatchElement {
	public var vx : Float;
	public var vy : Float;

	public function new(t) {
		super(t);
		vx = vy = 0;
	}

	function randDir() {
		return Std.random(2) * 2 - 1;
	}

	override function update(dt:Float) {
		dt *= 60;
		x += vx * dt;
		y += vy * dt;
		if( x < 0 || y > 600 || x > 800 || y < 0 ) return true;
		return true;
	}
}
