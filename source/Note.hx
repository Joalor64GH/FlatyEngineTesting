package;

import flixel.FlxSprite;
import ui.PreferencesMenu;

using StringTools;

class Note extends FlxSprite
{
	public static final swagWidth:Float = 160 * 0.7;
	public static final defaultHitHealth:Float = 0.023;
	public static final defaultMissHealth:Float = 0.0475;

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var mustPress:Bool = false;
	public var altNote:Bool = false;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var sustainLength:Float = 0;
	public var sustainEndOffset:Float = Math.NEGATIVE_INFINITY;

	public var prevNote(default, null):Note;
	public var parentNote(default, null):Note;
	public var children(default, null):Array<Note> = [];

	public var hitHealth:Float = defaultHitHealth;
	public var missHealth:Float = defaultMissHealth;

	public var lateHitMult:Float = 1;
	public var earlyHitMult:Float = 1;
	public var canBeHit(get, never):Bool;

	inline public function get_canBeHit()
	{
		return strumTime > Conductor.songPosition - Conductor.safeZoneOffset * lateHitMult
			&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset * earlyHitMult;
	}

	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;

	public var copyAngle:Bool = true;

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, sustainNote:Bool = false)
	{
		super();

		this.strumTime = strumTime;
		this.noteData = noteData;
		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		switch (PlayState.curStage)
		{
			case 'school' | 'schoolEvil':
				if (sustainNote)
				{
					loadGraphic(Paths.image('pixelUI/arrowEnds'), true, 7, 6);

					animation.add('purpleholdend', [4], 12);
					animation.add('greenholdend', [6], 12);
					animation.add('redholdend', [7], 12);
					animation.add('blueholdend', [5], 12);

					animation.add('purplehold', [0], 12);
					animation.add('greenhold', [2], 12);
					animation.add('redhold', [3], 12);
					animation.add('bluehold', [1], 12);
				}
				else
				{
					loadGraphic(Paths.image('pixelUI/arrows-pixels'), true, 17, 17);

					animation.add('greenScroll', [6], 12);
					animation.add('redScroll', [7], 12);
					animation.add('blueScroll', [5], 12);
					animation.add('purpleScroll', [4], 12);
				}

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			default:
				frames = Paths.getSparrowAtlas('NOTE_assets');

				if (sustainNote)
				{
					animation.addByPrefix('purpleholdend', 'pruple end hold', 24);
					animation.addByPrefix('greenholdend', 'green hold end', 24);
					animation.addByPrefix('redholdend', 'red hold end', 24);
					animation.addByPrefix('blueholdend', 'blue hold end', 24);

					animation.addByPrefix('purplehold', 'purple hold piece', 24);
					animation.addByPrefix('greenhold', 'green hold piece', 24);
					animation.addByPrefix('redhold', 'red hold piece', 24);
					animation.addByPrefix('bluehold', 'blue hold piece', 24);
				}
				else
				{
					animation.addByPrefix('greenScroll', 'green0', 24);
					animation.addByPrefix('redScroll', 'red0', 24);
					animation.addByPrefix('blueScroll', 'blue0', 24);
					animation.addByPrefix('purpleScroll', 'purple0', 24);
				}

				setGraphicSize(Std.int(width * 0.7));
				antialiasing = true;
		}
		updateHitbox();

		if (!sustainNote)
		{
			if (!PreferencesMenu.getPref('opaque-notes'))
				alpha = 0.7;
			
			switch (noteData)
			{
				case 0:
					animation.play('purpleScroll');
				case 1:
					animation.play('blueScroll');
				case 2:
					animation.play('greenScroll');
				case 3:
					animation.play('redScroll');
			}
		}
		else if (prevNote != null)
		{
			isSustainEnd = true;
			earlyHitMult = 0.5;

			alpha = 0.6;
			copyAngle = false;

			parentNote = prevNote;
			while (parentNote.prevNote != null)
				parentNote = parentNote.prevNote;
			parentNote.children.push(this);

			if (PreferencesMenu.getPref('downscroll'))
				flipY = true;

			offsetX = width / 2;

			switch (noteData)
			{
				case 0:
					animation.play('purpleholdend');
				case 1:
					animation.play('blueholdend');
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
			}

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.isSustainEnd = false;

				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.updateScale();
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress && !tooLate && !wasGoodHit && strumTime < Conductor.songPosition - Conductor.safeZoneOffset && canBeHit)
			tooLate = true;

		if (tooLate && alpha > 0.3)
			alpha = 0.3;
	}

	public function updateScale()
	{
		if (isSustainNote && !isSustainEnd)
		{
			scale.y = (width / frameWidth) * ((Conductor.stepCrochet / 100) * 1.5);
			if (PlayState.instance != null)
				scale.y *= PlayState.instance.songSpeed;
			updateHitbox();
		}
	}
}
