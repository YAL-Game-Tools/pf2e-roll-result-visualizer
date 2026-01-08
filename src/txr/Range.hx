package txr;

@:forward @:forward.new
abstract Range(RangeImpl) from RangeImpl {
	public var avg(get, never):Float;
	inline function get_avg() {
		return (this.min + this.max) / 2;
	}
	
	@:op(-A) function invert() {
		return new Range(-this.min, -this.max);
	}
	
	@:op(A + B) function addNumber(n:Float) {
		return new Range(this.min + n, this.max + n);
	}
	
	@:op(A + B) function addRange(r:Range) {
		return new Range(this.min + r.min, this.max + r.max);
	}
	
	@:op(A - B) function subRange(r:Range) {
		return new Range(this.min - r.min, this.max - r.max);
	}
	
	@:op(A * B) function multiplyByNumber(n:Float) {
		return new Range(this.min * n, this.max * n);
	}
	@:op(A * B) function multiplyByRange(r:Range) {
		return new Range(this.min * r.min, this.max * r.max);
	}
	
	@:op(A / B) function divideByNumber(n:Float) {
		return new Range(this.min / n, this.max / n);
	}
	@:op(A / B) function divideByRange(r:Range) {
		return new Range(this.min / r.min, this.max / r.max);
	}
	
	public function intDivideByNumber(n:Float) {
		return new Range(Std.int(this.min / n), Std.int(this.max / n));
	}
	public function intDivideByRange(r:Range) {
		return intDivideByNumber(r.avg);
	}
	
	public function isNegative() {
		if (this.min < this.max) {
			return this.max < 0;
		} else {
			return this.min < 0;
		}
	}
	
	public function isPositive() {
		if (this.min < this.max) {
			return this.min > 0;
		} else {
			return this.max > 0;
		}
	}
	
	@:from public static inline function fromNumber(n:Float):Range {
		return new Range(n, n);
	}
}
class RangeImpl {
	public var min:Float;
	public var max:Float;
	public function new(min:Float, max:Float) {
		this.min = min;
		this.max = max;
	}
	public inline function isPoint() {
		return Math.abs(max - min) < 0.01;
	}
	@:keep public function toString() {
		if (isPoint()) return HtmlTools.toFixed2(min);
		return HtmlTools.toFixed2(min) + "~" + HtmlTools.toFixed2(max);
	}
	public function toStringAvg() {
		if (isPoint()) return HtmlTools.toFixed2(min);
		return HtmlTools.toFixed2(min) + "~" + HtmlTools.toFixed2(max)
			+ " / " + HtmlTools.toFixed2((min + max) / 2) + " avg";
	}
	public function toStringFull() {
		if (isPoint()) return Std.string(min);
		return Std.string(min) + "~" + Std.string(max);
	}
}