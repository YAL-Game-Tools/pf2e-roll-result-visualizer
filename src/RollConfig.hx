class RollConfig {
	public var sureStrike:SureStrike = Off;
	public var firstEfficiency = 0.0;
	public var efficiencies:Array<Float> = null;
	public function new() {
		
	}  
}
enum abstract SureStrike(Int) {
	var Off = 0;
	var On = 1;
	var Grid = 2;
}