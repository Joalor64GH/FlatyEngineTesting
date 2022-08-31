package;

import flixel.FlxSprite;

class FNFSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;

	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		animOffsets = new Map<String, Array<Float>>();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
		{
			var daOffset:Array<Float> = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
