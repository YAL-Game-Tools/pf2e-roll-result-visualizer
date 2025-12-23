import RollTable;

class RollConfig {
	public var sureStrike:SureStrike = Off;
	public var keenFlair = false;
	public var firstEfficiency = 0.0;
	public var efficiencies:StageArray<Float> = null;
	public var flatChecks = [];
	public function new() {
		
	}  
}
enum abstract SureStrike(Int) {
	var Off = 0;
	var On = 1;
	var Grid = 2;
}