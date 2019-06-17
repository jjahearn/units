package;

import flash.display.StageScaleMode;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.graphics.frames.FlxImageFrame;
import flixel.system.FlxAssets;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouse;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxPath;
import flixel.math.FlxPoint;
import haxe.Log;
import haxe.unit.TestCase;
import Unit;
import openfl.Assets;
using flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{
	/**
	 * Tile width
	 */
	public static inline var TILE_WIDTH:Int = 24;
	/**
	 * Tile height
	 */
	public static inline var TILE_HEIGHT:Int = 24;
	
	private var newPlantThreshold:Int = 1;
	private var plantRateTimer:Float = 0.0;
	
	/**
	 * Map
	 */
	private var _gameMap:GameMap;

	private var _unitGroup:FlxTypedGroup<Unit>;
	
	private var _towerGroup:FlxTypedGroup<Tower>;
	
	private var _plantGroup:FlxTypedGroup<Plant>;
	
	private var _summonUnitsButton:FlxButton;
	
	private var unitsButtonPressed:Bool;
	
	private var background:FlxSprite;
	
	private var _debugUnit:Unit;
	
	private var _gameData:GameData;
	
	private var spawnPointX:Float = 0;
	
	private var spawnPointY:Float = 0;
	
	private var sidebarText:String = "yee ha";
	private var testNum:Int = 0;
	private var legends:FlxText;

	override public function create():Void
	{	 
		setupCameraSettings();
		
		makeBackground();
		
		makeTileMap();
		
		makeSidebar();
	
		//set tower grp
		_towerGroup = new FlxTypedGroup<Tower>();
		add(_towerGroup);
		
		_plantGroup = new FlxTypedGroup<Plant>();
		add(_plantGroup);
		
		// Set and add unit to PlayState
		_unitGroup = new FlxTypedGroup<Unit>();
		add(_unitGroup);
		
		_gameData = new GameData();
		
		#if debug
		_debugUnit= new Unit(_gameMap, _gameData, 0, 0, _towerGroup, _plantGroup);
		_debugUnit.x = spawnPointX;
		_debugUnit.y = spawnPointY;
		add(_debugUnit);
		#end
	}
	
	override public function destroy():Void
	{
		super.destroy();
		
		_gameMap = null;
		_unitGroup = null;
		_towerGroup = null;
	}
	
	override public function draw():Void
	{
		super.draw();
		#if debug
		_debugUnit.drawDebug();
		#end	
		
	}
	
	override public function update(elapsed:Float):Void
	{
		makeUnits();
		super.update(elapsed);
		
		// Check mouse pressed and unit action
		if (FlxG.mouse.justPressed) 
		{
			// Get data map coordinate
			var mx:Int = Std.int(FlxG.mouse.screenX / TILE_WIDTH);
			var my:Int = Std.int(FlxG.mouse.screenY / TILE_HEIGHT);
			
			// Change tile toogle
			_gameMap.setTile(mx, my, 1 - _gameMap.getTile(mx, my), true);
		}
		updateSidebarText();
		_towerGroup.forEach(freeTrappedUnits, false);
	}
	
	private function freeTrappedUnits(t:Tower):Void{
		if (!t.placed) return;
		
		var center:FlxObject = new FlxObject(t.x + t.width / 2, t.y + t.height / 2, 1, 1);
		if (center.overlaps(_unitGroup)){
			_gameMap.setTile(_gameMap.screenXToTileX(t.x), _gameMap.screenYToTileY(t.y), 0);
			t.disrupted = true;
		} 
		if (t.disrupted && !t.overlaps(_unitGroup)){
			t.disrupted = false;
			_gameMap.setTile(_gameMap.screenXToTileX(t.x), _gameMap.screenYToTileY(t.y), 1);
		}
	}
	
	private function makeUnits(){
		_towerGroup.forEach(placeTower, false);
		if (unitsButtonPressed) makeUnits();
		unitsButtonPressed = false;
		makePlants();
	}
	
	private function placeTower(t:Tower):Void{
		
		if (t.placed) return;
		
		var killself:Bool = false;
		var towerTileX:Int = _gameMap.screenXToTileX(t.x);//Std.int((t.x+TILE_WIDTH/2)/TILE_WIDTH);
		var towerTileY:Int = _gameMap.screenYToTileY(t.y);//Std.int((t.y+TILE_HEIGHT/2)/TILE_HEIGHT);
		if (t.buildTimeout <= 0 || _gameMap.getTile(towerTileX, towerTileY) == 1) { //took too long or already a tower there
			FlxG.sound.load(FlxAssets.getSound("assets/sounds/nobuild")).play();
			killself = true;
		}else{
			if (_gameMap.isBuildable(towerTileX, towerTileY) && !anyBuildingsOverlap(t)) {
				if (!t.overlaps(_unitGroup)) {
					// no units on it
					if (_gameData.resourceCount > 0){
						_gameMap.setTile(towerTileX, towerTileY, 1, true);
						_gameData.resourceCount--;
						t.beginBuilding();
						//killself = true;
					}
				} 
			} else {
				killself = true;
			}
		}
		if (killself) {
			t._creator.doneBuilding();
			_towerGroup.remove(t);
			t.destroy();
			t = null;
		}
	}
	
	private function anyBuildingsOverlap(s:FlxSprite) {
		var testBox:FlxSprite = new FlxSprite(s.x, s.y);
		testBox.makeGraphic(Std.int(s.width), Std.int(s.height), 0x00000000);
		s.x = s.y = -1000;
		var result:Bool = false;
		if (testBox.overlaps(_plantGroup)){
			result = true;
		} else if (testBox.overlaps(_towerGroup)){
			result = true;
		} 
		s.x = testBox.x;
		s.y = testBox.y;
		return result;
	}
	
	private function unitsButton():Void {
		unitsButtonPressed = true;
	}
	
	private function makeUnits():Void {
		var unitsCounter:Int = 10;
		while (unitsCounter>0){
			var _unit:Unit = new Unit(_gameMap, _gameData, 0, 0, _towerGroup, _plantGroup);
			_unit.x = spawnPointX;
			_unit.y = spawnPointY;
			if (unitsCounter == 1){
				
				//
			}
			_unitGroup.add(_unit);
			unitsCounter--;
		}
	}
	
	//makes plants based on a rate of plants per 3600 frames
	private function makePlants():Void{
		
		plantRateTimer += (_gameData.plantSpawnRate / 3600); // math might not be right 
		while (plantRateTimer > newPlantThreshold) {
			makeOnePlant();
			newPlantThreshold++;
		}
		if (newPlantThreshold > 1000){
			plantRateTimer -= 1000;
			newPlantThreshold -= 1000;
		}
	}
	
	private function makeOnePlant():Void{
		var plant:Plant = new Plant(_gameData, 0, 0);
		plant.loadGraphic("assets/plant.png");
		
		var tileX:Int = Std.int(Math.random() * _gameMap.widthInTiles);
		var tileY:Int = Std.int(Math.random() * _gameMap.heightInTiles);
		plant.x = tileX * TILE_WIDTH;
		plant.y = tileY * TILE_HEIGHT;
		
		while (_gameMap.getTile(tileX, tileY) == 1 || anyBuildingsOverlap(plant)){
			tileX = Std.int(Math.random() * _gameMap.widthInTiles);
			tileY = Std.int(Math.random() * _gameMap.heightInTiles);
			plant.x = tileX * TILE_WIDTH;
			plant.y = tileY * TILE_HEIGHT;
		}
		_plantGroup.add(plant);
	}
	
	function makeBackground():Void
	{
		var bgw:Int = 0;
		var bgh:Int = 0;
		var bgPattern = new FlxSprite(0, 0, "assets/background.png");
		background = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		
		while (bgh < FlxG.height){
			while (bgw < FlxG.width){
				background.stamp(bgPattern,bgw,bgh);
				bgw += Std.int(bgPattern.width);
			}
			bgw = 0;
			bgh += Std.int(bgPattern.height);
		}
		bgPattern.destroy();
		bgPattern = null;
		add(background);
	}
	
	function makeTileMap():Void 
	{
		_gameMap = new GameMap();
		spawnPointX = _gameMap.width / 2;
		spawnPointY = _gameMap.height / 2;
		_gameMap.makeUnbuildable(_gameMap.screenXToTileX(spawnPointX),
								 _gameMap.screenYToTileY(spawnPointY));
		add(_gameMap);
	}
	
	function setupCameraSettings():Void 
	{
		FlxG.scaleMode = new RatioScaleMode();
		#if debug
		//FlxG.camera.zoom = 2;
		#end
	}
	
	function makeSidebar():Void 
	{
		var seperator:FlxSprite = new FlxSprite(_gameMap.widthInTiles * TILE_WIDTH, 0);
		seperator.makeGraphic(Std.int(FlxG.width - seperator.width), FlxG.height, 0xff8899cc);
		add(seperator);
		
		var buttonX:Float = FlxG.width - 90;
		
		// Add button move to goal to PlayState
		_summonUnitsButton = new FlxButton(buttonX, 10, "SUMMON UNITS", unitsButton);
		add(_summonUnitsButton);
			
		// Add some texts
		var textWidth:Int = 140;
		var textX:Int = FlxG.width - textWidth - 5;
		
		legends = new FlxText(textX, 140, textWidth, sidebarText, 16);
		add(legends);
	}
	
	function updateSidebarText():Void 
	{
		sidebarText = "yee" + testNum + "\n Mapwidth: " + _gameMap.width + ", " + _gameMap.widthInTiles + " tiles" 
						+ "\n Resources: " + _gameData.resourceCount;
		testNum++;
		legends.text = sidebarText;
	}
}