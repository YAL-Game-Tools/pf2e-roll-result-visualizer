package txr;

/**
 * @author YellowAfterlife
 */
enum TxrNode {
	Number(p:TxrPos, f:Float);
	Dice(p:TxrPos, count:Float, sides:Int);
	NumberRange(p:TxrPos, min:Float, max:Float);
	Ident(p:TxrPos, s:String);
	UnOp(p:TxrPos, op:TxrUnOp, q:TxrNode);
	BinOp(p:TxrPos, op:TxrOp, a:TxrNode, b:TxrNode);
}