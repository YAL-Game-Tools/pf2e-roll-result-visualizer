import txr.Range;
import RollTable;

class RollConfig {
	public var rollMode:RollMode = RollOnce;
	public var rollTable = false;
	public var keenFlair = false;
	public var firstEfficiency:Range = null;
	public var formulas:StageArray<String> = null;
	public var efficiencies:StageArray<Range> = null;
	public var successUpgrade = false;
	public var nat1Downgrade = true;
	public var forcefulEfficiency = 0.;
	public var assurance:Null<Int> = null;
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