import RollTable;

class RollConfig {
	public var rollMode:RollMode = RollOnce;
	public var rollTable = false;
	public var keenFlair = false;
	public var firstEfficiency = 0.0;
	public var efficiencies:StageArray<Float> = null;
	public var flatChecks = [];
	public function new() {
		
	}  
}
enum abstract RollMode(Int) {
	var RollOnce = 0;
	var KeepHigher = 1;
	var KeepLower = 2;
	var FollowUpStrike = 3;
	public function isPair() {
		return switch (abstract) {
			case KeepHigher, KeepLower: true;
			default: false;
		}
	}
}