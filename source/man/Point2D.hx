package man;

class Point2D
{
	public var x:Int;
	public var y:Int;
	public var parent:Point2D;
	
	public function new(X:Int, Y:Int, Parent:Point2D)
	{
		x = X;
		y = Y;
		parent = Parent;
	}
	
	public function GetOpposite():Point2D
	{
		var diffX:Int = x - parent.x;
		var diffY:Int = y - parent.y;
		
		if (diffX != 0) return new Point2D(x + diffX, y, parent);
		if (diffY != 0) return new Point2D(x, y + diffY, parent);
		
		return null;
	}
}