package txr;

/**
 * @author YellowAfterlife
 */
@:using(TxrToken.TxrTokenTools)
enum TxrToken {
	/** save ourselves a couple of != null checks */
	Eof(p:TxrPos);
	
	/** We don't know for sure if it's a binop or not - e.g. might be "-v" or "+v" */
	Op(p:TxrPos, op:TxrOp);
	
	/** Definitely an unary (-v) */
	UnOp(p:TxrPos, op:TxrUnOp);
	
	/** 1~6 */
	RangeOp(p:TxrPos);
	
	/** ( */
	ParOpen(p:TxrPos);
	
	/** ) */
	ParClose(p:TxrPos);
	
	/** numeric literal */
	Number(p:TxrPos, val:Float);
	
	/** dN **/
	Die(p:TxrPos, sides:Int);
	
	/**  */
	Ident(p:TxrPos, id:String);
}
class TxrTokenTools {
	public static function getPos(tk:TxrToken):TxrPos {
		return tk.getParameters()[0];
	}
}