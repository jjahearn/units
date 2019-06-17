package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.*;

class MenuState extends FlxState
{
	public var txtbox:FlxText = new FlxText(0, 0, 0, "Hello World!");
	public var test:Float = 0;
	override public function create():Void
	{
		super.create();
		
		add(txtbox);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		txtbox.text = "test" + test;
		test++;
	}
}