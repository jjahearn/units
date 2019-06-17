package;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.group.FlxGroup;

class Plant extends FlxSprite 
{
	private var maturity:Int = 0;
	public var matured:Bool = false;
	private var _gameData:GameData;
	private var harvesters:FlxTypedGroup<Unit> = new FlxTypedGroup<Unit>();
	private var harvestProgress:Int;

	public function new(gameData:GameData, ?X:Float=0, ?Y:Float=0, ?SimpleGraphic:FlxGraphicAsset) 
	{
		_gameData = gameData;
		harvestProgress = gameData.plantHarvestSpeed;
		super(X, Y, SimpleGraphic);
		
	}
	
	override public function update(elapsed:Float):Void
	{
		if (!matured) {
			maturity++;
			if (maturity == _gameData.plantMaturationRate) bloom();
		} else {
			for (harvester in harvesters){
				harvestProgress--;
				if (harvestProgress == 0) harvested();
			}
		}
		super.update(elapsed);
	}
	
	private function harvested():Void{
		for (harvester in harvesters){
			harvester.doneHarvesting(this);
		}
		_gameData.resourceCount++;
		kill();
	}
	
	private function bloom(){
		matured = true;
		loadGraphic("assets/plant2.png");
	}
	
	public function addHarvester(unit:Unit){
		harvesters.add(unit);
	}
}