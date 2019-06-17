package;
import flixel.tile.FlxTilemap;
import PlayState;
import man.HxPrimMaze;

/**
 * now with potentially reusable functions for map math
 */
class GameMap extends FlxTilemap
{
	private static inline var TILE_WIDTH:Int = PlayState.TILE_WIDTH;
	private static inline var TILE_HEIGHT:Int = PlayState.TILE_HEIGHT;
	
	public var buildRestrictionMap:Array<Int>;

	override public function new() 
	{
		super();
		loadMapFromCSV("assets/pathfinding_map.txt", "assets/tiles.png", TILE_WIDTH, TILE_HEIGHT);
		var testmaze:Array<Array<Int>> = HxPrimMaze.generateIntMatrix(54,54);
		buildRestrictionMap = new Array<Int>();
		for (i in 2...52){
			for (j in 2...52) {
				if (testmaze[i][j] == 0 && i != 2 && i != 51 && j != 2 && j != 51){
				buildRestrictionMap.push(0);
				}else{
				buildRestrictionMap.push(1);
				}
			}
		}
		testmaze = null;
	}
	
	public function isBuildable(tileX:Int, tileY:Int):Bool{
		if (buildRestrictionMap[tileX + (tileY * widthInTiles)] == 0 && getTile(tileX, tileY) == 0) return true;
		return false;
	}
	
	public function makeUnbuildable(tileX:Int, tileY:Int):Void{
		buildRestrictionMap[tileX + (tileY * widthInTiles)] = 1;
	}
	
	public function putTileXInBounds(tileX:Int):Int{
		if (tileX >= widthInTiles){
			return widthInTiles-1;
		} else if (tileX < 0) {
			return 0;
		} else	{
			return tileX;
		}
	}
	
	public function putTileYInBounds(tileY:Int):Int{
		if (tileY >=  heightInTiles){
			return heightInTiles-1;
		} else if (tileY < 0) {
			return 0;
		} else	{
			return tileY;
		}
	}
	
	public function isTileInBounds(tileX:Int, tileY:Int):Bool{
		if (tileX >= 0 && tileX < widthInTiles &&
			tileY >= 0 && tileY < heightInTiles){
				return true;
		} else return false;
	}
	
	public function isPointInBounds(x:Float, y:Float):Bool{
		var tileX:Int = screenXToTileX(x);
		var tileY:Int = screenYToTileY(y);
		return isTileInBounds(tileX, tileY);
	}
	
	public function screenXToTileX(ix:Float):Int {
		return Std.int(Math.floor(ix / TILE_WIDTH));
	}
	
	public function screenYToTileY(iy:Float):Int {
		return Std.int(Math.floor(iy / TILE_HEIGHT));
	}
}