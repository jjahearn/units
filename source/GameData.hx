package;

/**
 * overarching singleton (1 per playstate) game data
 * feel like it makes sense to track things this way. 
 * essentially just pulling some variables out of playstate itself
 */
class GameData 
{
	public var resourceCount:Int = 0;
	public var unitDeaths:Int = 0;
	public var unitSpeedUpgrade:Int = 0;
	public var plantSpawnRate:Int = 50;//per 3600 frames
	public var towerBuildSpeed:Int = 100;
	public var plantMaturationRate:Int = 150;
	public var plantHarvestSpeed:Int = 100;
	
	public function new() 
	{
	}
	
}