package tools;

class ArrayTools {
	public static inline function find<T>(arr:Array<T>, fun:T->Bool):T {
		return (cast arr).find(fun);
	}
}
