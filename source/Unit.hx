package;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.util.FlxPath;
import flash.display.BitmapData;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import haxe.Log;

enum States{
	Aimless;
	Moving;
	Building;
	Harvesting;
}

class Unit extends FlxSprite
{
	private var moveSpeed:Int;
	private var _map:GameMap;
	public var knownMap:FlxTilemap;
	public var state = States.Aimless;
	public var sight:Int;
	public var goalX:Float;
	public var goalY:Float;
	private var  fogMap:Array<Int>;
	private var _tileX:Int;
	private var _tileY:Int;
	private var _previousX:Int;
	private var _previousY:Int;
	private var uptime:Int = 0;
	private var _gameData:GameData;
	private var _towers:FlxTypedGroup<Tower>;
	private var _plants:FlxTypedGroup<Plant>;
	public var buildChance:Int;
	
	private static inline var DEFAULT_MOVESPEED:Int = 100; 
	private static inline var DEFAULT_SIGHT:Int = 4;
	private static inline var INITIAL_BUILD_CHANCE:Int = 2;
	private static inline var TILE_WIDTH:Int = PlayState.TILE_WIDTH;
	private static inline var TILE_HEIGHT:Int = PlayState.TILE_HEIGHT;
	
	override public function new(map:GameMap, gameData:GameData, ?x:Float = 0, ?y:Float = 0, ?SimpleGraphic:FlxGraphicAsset,
								towers:FlxTypedGroup<Tower>, plants:FlxTypedGroup<Plant>)
	{
		super(x, y, SimpleGraphic);
		moveSpeed = DEFAULT_MOVESPEED;
		sight = DEFAULT_SIGHT;
		resetBuildChance();
		
		_map = map;
		_gameData = gameData;

		_tileX = _map.screenXToTileX(x);
		_tileY = _map.screenYToTileY(y);
		_previousX = _map.widthInTiles+10; //something that isn't on the map, can't use 0 so a point outside the map was chosen
		_previousY = _map.heightInTiles+10;
		
		path = new FlxPath();
		
		knownMap = new FlxTilemap();
		fogMap = new Array();
		
		// generate blank fog of war array
		for (i in 0..._map.getData().length){
			fogMap.push(0); 
		} 
		knownMap.loadMapFromArray(fogMap, _map.widthInTiles, _map.heightInTiles, "assets/tiles.png", TILE_WIDTH, TILE_HEIGHT,OFF);
		// technically shouldn't be reusing fogMap like that but LoadMapFromArray takes it by value instead of ref so no conflicts
		
		knownMap.setTileProperties(2, FlxObject.NONE); 
		
		getTilesInRadius(_tileX, _tileY, sight); //units are born blind. Open their eyes.
		
		_towers = towers;
		_plants = plants;
		
		loadGraphic("assets/units.png", true, TILE_WIDTH, TILE_HEIGHT);
		
		animation.add("left", [3, 4, 3, 5], 12,  false);
		animation.add("right", [9, 10, 9, 11], 12, false);
		animation.add("up", [6, 7, 6, 8], 12, false);
		animation.add("down", [0, 1, 0, 2], 12, false);
		animation.add("wow", [12, 13], 12, false);
		animation.play("down");
	}
	
	public function resetFoW():Void {
		for (i in 0..._map.getData().length){
			fogMap[i] = 0; //reset fog of war knowledge
		}
		getTilesInRadius(_tileX, _tileY, sight);
	}
	
	private function getTilesInRadius(unitTileX:Int, unitTileY:Int, r:Int):Void
	{
		var xlimit = _map.putTileXInBounds(unitTileX + r);
		var ylimit = _map.putTileYInBounds(unitTileY + r);
		var ix:Int = _map.putTileXInBounds(unitTileX - r);
		var iy:Int = _map.putTileYInBounds(unitTileY - r);
		
		while (ix <= (xlimit))
		{
			while (iy <= (ylimit))
			{
				knownMap.setTile(ix, iy,  _map.getTile(ix, iy));  
				fogMap[iy * _map.widthInTiles + ix] = 1; //sets fog of war knowledge of these tiles to true
				iy++;
			}
			iy = _map.putTileYInBounds(unitTileY - r);
			ix++;
		}
	}
	
	private function randomNumberMaybeNegative(max:Int):Int {
		var result:Int = Std.random(max * 2 + 1) - max;
		return result;
	}
	
	//get random destination
	private function wander():FlxPoint {
		var wanderX:Int = randomNumberMaybeNegative(sight) + _tileX;
		var wanderY:Int = randomNumberMaybeNegative(sight) + _tileY;
		
		//while the randomly chosen tile is unacceptable, choose another
		while (_map.getTile(wanderX, wanderY) == 1 || _map.isTileInBounds(wanderX, wanderY) == false || (wanderX == _tileX && wanderY == _tileY)){ 
			wanderX =  randomNumberMaybeNegative(sight) + _tileX;
			wanderY =  randomNumberMaybeNegative(sight) + _tileY;
		}
		
		var result:FlxPoint = new FlxPoint(0, 0);
		result.x = wanderX * TILE_WIDTH + TILE_WIDTH / 2;
		result.y = wanderY * TILE_HEIGHT + TILE_HEIGHT / 2;
		return result;
	}
	
	public function updateKnownTiles():Void
	{
		var ix:Int;
		var iy:Int;
		for (i in 0...fogMap.length) {
			iy = Std.int(Math.floor(i / _map.widthInTiles));
			ix = i % fogMap.length;
			if (fogMap[i] > 0){ // only update tiles it remembers seeing
				knownMap.setTile(ix, iy, _map.getTileByIndex(i), false); //setTile somehow slightly faster than setTilebyIndex. getTileByIndex however is super fast
				//needs further testing. might revert back to setTilebyIndex
			} else {
				knownMap.setTile(ix, iy, 0, false);
			}
		}
	}
	
	override public function update(elapsed:Float):Void
	{				
		_tileX = _map.screenXToTileX(x + width / 2);
		_tileY = _map.screenYToTileY(y + height / 2);
		
		switch(state) {
			case States.Moving:
				var nextNode:FlxPoint = path.nodes[path.nodeIndex];
				var realNextNodeTile:Int = _map.getTile(_map.screenXToTileX(nextNode.x), _map.screenYToTileY(nextNode.y));
				var fogNextNodeTile:Int = knownMap.getTile(_map.screenXToTileX(nextNode.x), _map.screenYToTileY(nextNode.y));
				if (realNextNodeTile != fogNextNodeTile) { // check to see if the next node unit is going to has updated
					knownMap.setTile(_map.screenXToTileX(nextNode.x), _map.screenYToTileY(nextNode.y), realNextNodeTile); // update 
					moveToCenterOfTile();
				}
			
				if ((_previousX != _tileX) || (_previousY != _tileY)){ //run this only when unit has entered new tile

					updateKnownTiles();
					_previousX = _tileX;
					_previousY = _tileY;
					getTilesInRadius(_tileX, _tileY, sight);
				}
				
				if (inSameTileAsThisUnit(goalX,goalY))
				{
					moveToCenterOfTile();
				}
				
				uptime++;
				if (uptime > 3) {
					getTilesInRadius(_tileX, _tileY, sight);
					moveToGoal();
					uptime = 0;
					if (_gameData.resourceCount > 0){
						if (Std.random(201) < buildChance){ 
							createTower();
						}
					}
				}
			case States.Building:
				moveToCenterOfTile();
			case States.Harvesting:
				moveToCenterOfTile();
			case States.Aimless:
				var destination:FlxPoint = chooseDestination();
				goalX = destination.x;
				goalY = destination.y;
				state = States.Moving;
				moveToGoal();
		}
		
		animation.play(chooseAnimation());
		
		super.update(elapsed);
	}
	
	private function chooseAnimation():String
	{
		/*
		if (path.angle == 0 || path.angle == 45 || path.angle == -45) {
			animation.play("up");
		}
		if (path.angle == 180 || path.angle == -135 || path.angle == 135) {
			animation.play("down");
		}
		if (path.angle == 90) {
			animation.play("right");
		}
		if (path.angle == -90) {
			animation.play("left");
		}
		*/
		
		/*
		if (animation.name == "wow") {
			return "wow";
		} else return "down";
		*/
		
		if (state == States.Building){
			return "wow";
		} else return "down";
	}
	
	private function createTower():Void {
		state = States.Building;
		moveToCenterOfTile();
		buildChance += 25;
		
		var _tower:Tower = new Tower(this, _gameData);
		_tower.makeGraphic(TILE_WIDTH, TILE_HEIGHT, FlxColor.RED, true);
		//_tower.loadGraphic("assets/temptower.png");
		var tOffsetX:Int = 0;
		var tOffsetY:Int = 0;
		while (tOffsetX == 0 && tOffsetY == 0){
		tOffsetX= randomNumberMaybeNegative(1);
		tOffsetY = randomNumberMaybeNegative(1);
		}
		
		var towerTileX:Int = _map.putTileXInBounds(_tileX + tOffsetX);
		var towerTileY:Int = _map.putTileYInBounds(_tileY + tOffsetY);
		
		knownMap.setTile(towerTileX, towerTileY, 1);
		_tower.x = towerTileX * TILE_WIDTH;
		_tower.y = towerTileY * TILE_HEIGHT;
		
		_towers.add(_tower);
	}
	
	
	private function inSameTileAsThisUnit(ix:Float, iy:Float):Bool{
		if (Std.int(ix / TILE_WIDTH) == _tileX && Std.int(iy / TILE_HEIGHT) == _tileY){
			return true;
		} else{
			return false;
		}
	}
	
	public function moveToGoal():Void
	{
		//is the goal a passable tile?
		if (_map.getTile(_map.screenXToTileX(goalX), _map.screenYToTileY(goalY)) != 0){
			stopUnit();
			return;
		}
		
		// Find path from unit to goal
		var pathPoints:Array<FlxPoint> = _map.findPath(
			FlxPoint.get(x + width / 2, y + height / 2),
			FlxPoint.get(goalX, goalY),true,false,NONE);
		
		// Tell unit to follow path
		if (pathPoints != null) 
		{
			path.start(pathPoints, moveSpeed);
		}
		else 
		{
			moveToCenterOfTile();
		}
	}
	
	override public function hurt(damage:Float){
		//process damage
		super.hurt(damage);
	}
	
	private function moveToCenterOfTile():Void
	{
		var startX:Float = x + width / 2;
		var startY:Float = y + height / 2;
		_tileX = _map.screenXToTileX(startX);
		_tileY = _map.screenYToTileY(startY);
		var endX:Float = _tileX * TILE_WIDTH + TILE_WIDTH / 2;
		var endY:Float = _tileY * TILE_HEIGHT + TILE_HEIGHT / 2;
		if (Math.abs(startX - endX) <= 2 && Math.abs(startY - endY) <= 2) { // if close snap to center
			x = endX - TILE_WIDTH / 2;
			y = endY - TILE_HEIGHT / 2;
			startX = endX;
			startY = endY;
		}
		if (startX == endX && startY == endY ) {
			if (state!= States.Building) {
				stopUnit();
			}else{
				return;
			}
		}
		var pathPoints:Array<FlxPoint> = _map.findPath(
			FlxPoint.get(startX,startY),
			FlxPoint.get(endX, endY)
			);
		// Tell unit to follow path
		if (pathPoints != null) 
		{
			path.start(pathPoints, moveSpeed);
		}
	}
	
	public function doneBuilding():Void{
		state = States.Aimless;
		resetBuildChance();
	}
	
	public function harvestResource():Void{
		state = States.Harvesting;
	}
	
	public function doneHarvesting(plant:Plant):Void{
		state = States.Aimless;
		_plants.remove(plant);
	}
	
	private function resetBuildChance(?bonus:Int):Void 
	{
		buildChance = INITIAL_BUILD_CHANCE + bonus;
	}
	
	private function chooseDestination():FlxPoint 
	{
		var result:FlxPoint = new FlxPoint( -1, -1);
		if (harvestPlant()){
			return getPosition();
		}
		var nearestPlant:Plant = getNearestPlant();
		if (nearestPlant != null){
			result = nearestPlant.getMidpoint();
		}else {
			result = wander();
		}
		return result;
	}
	
	private function harvestPlant():Bool
	{
		var success:Bool = false;
		
		if (overlaps(_plants)){ // are we touching any plants?
			for (plant in _plants){ //if so loop through and find the plant we are touching
				if (overlaps(plant)){
					success = true;
					state = States.Harvesting;
					plant.addHarvester(this);
				}
			}
		}
		return success;
	}
	
	private function getNearestPlant():Plant{
		var result:Plant = null; 
		var bestDistance:Float = 1000000000;
		
		for (plant in _plants){
			
			var distance:Float = getPosition().distanceTo(plant.getPosition());
			
			if (plant.matured && distance <= sight * TILE_HEIGHT){
				
				if (result == null){
					
					result = plant;
					bestDistance = distance;
					
				} else if (distance < bestDistance){
					
					result = plant;
					bestDistance = distance;
				}
			}
		}
		
		return result;
	}
	
	public function stopUnit():Void
	{
		// Stop unit and destroy unit path
		state = States.Aimless;
		resetFoW();
		path.cancel();
		velocity.x = velocity.y = 0;
	}
	
}