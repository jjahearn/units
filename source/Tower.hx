package;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.util.FlxPath;
import flash.display.BitmapData;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxG;
import PlayState;
import flixel.system.FlxAssets;
import Unit;

class Tower extends FlxSprite
{
	public var _creator:Unit;
	public var buildTimeout:Int = 1;
	public var placed:Bool = false;
	public var built:Bool = false;
	public var buildTime:Int;
	public var disrupted:Bool = false;
	private var _gameData:GameData;
	
	override public function new(creator:Unit, gameData:GameData, ?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset) 
	{
		_gameData = gameData;
		_creator = creator;
		super(x, y, SimpleGraphic);
	}
	
	public function beginBuilding():Void{
		placed = true;
		buildTime = _gameData.towerBuildSpeed;
		loadGraphic("assets/temptower.png", true, PlayState.TILE_WIDTH, PlayState.TILE_HEIGHT);
		animation.add("beingBuilt", [0], 12, false);
		animation.add("built", [1], 12, false);
		animation.play("beingBuilt");
	}
	
	override public function update(elapsed:Float):Void
	{
		buildTimeout--;
		if (placed && !built){
			buildTime--;
			if (buildTime == 0){
				finishBuilding();
			}
		}
		super.update(elapsed);
	}
	
	private function finishBuilding():Void{
		built = true;
		_creator.doneBuilding();
		FlxG.sound.load(FlxAssets.getSound("assets/sounds/built")).play();
		animation.play("built");
	}
	
	override public function destroy():Void {
		super.destroy();
		_creator = null;
	}
}