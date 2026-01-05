package txr;
import haxe.ds.GenericStack;

/**
 * ...
 * @author YellowAfterlife
 */
class TxrProgram {
	public var actions:Array<TxrAction>;
	public function new() {
		
	}
	public static var evalError:String;
	public static function eval(snip:String):Range {
		try {
			var pg = new TxrProgram();
			pg.compile(snip);
			return pg.exec({});
		} catch (x:Dynamic) {
			evalError = Std.string(x);
			return null;
		}
	}
	public function compile(src:String) {
		var tokens = TxrParser.parse(src);
		var node = TxrBuilder.build(tokens);
		actions = TxrCompiler.compile(node);
	}
	public function exec(vars:Dynamic):Range {
		var stack = new GenericStack<Range>();
		for (act in actions) {
			inline function error(text:String) {
				return text + " at position " + act.getPos();
			}
			switch (act) {
				case Number(p, value): stack.add(value);
				case NumberRange(p, min, max): stack.add(new Range(min, max));
				case Dice(p, count, sides): stack.add(new Range(1, sides) * count);
				case Ident(p, name): {
					var val = Reflect.field(vars, name);
					if (Std.is(val, Float)) {
						stack.add(val);
					} else if (Reflect.hasField(vars, name)) {
						throw error('Variable $name is not a number');
					} else throw error('Variable $name does not exist');
				};
				case BinOp(p, op): {
					var b:Range = stack.pop();
					var a:Range = stack.pop();
					switch (op) {
						case TxrOp.Add: a += b;
						case TxrOp.Sub: a -= b;
						case TxrOp.Mul: a *= b;
						case TxrOp.FDiv: a /= b;
						case TxrOp.IDiv: a = a.intDivideByRange(b);
						//case TxrOp.FMod: a %= b;
						default: throw error("Can't apply " + op.toString());
					}
					stack.add(a);
				};
				case UnOp(p, op): {
					var v = stack.pop();
					switch (op) {
						case TxrUnOp.Not: v = v != 0 ? 0 : 1;
						case TxrUnOp.Negate: v = -v;
					}
				};
			}
		}
		return stack.pop();
	}
}