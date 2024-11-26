package;

#if sys
import sys.FileSystem;
#end
import lime.utils.Assets;
import flixel.util.FlxSave;
import polymod.Polymod;
import polymod.fs.PolymodFileSystem;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules;

typedef Mod =
{
	var metadata:ModMetadata;
	var enabled:Bool;
}

class ModHandler
{
	public static final MOD_DIRECTORY:String = './mods';
	public static final GLOBAL_MOD_ID:String = 'global';

	public static var modList(default, null):Array<Mod> = [];

	public static var fs(default, null):IFileSystem;

	static var save:FlxSave;

	private static final extensions:Map<String, PolymodAssetType> = [
		'ogg' => AUDIO_GENERIC,
		'mp3' => AUDIO_GENERIC,
		'png' => IMAGE,
		'xml' => TEXT,
		'json' => TEXT,
		'txt' => TEXT,
		'ttf' => FONT,
		'otf' => FONT
	];

	public static function init()
	{
		save = new FlxSave();
		save.bind('mod_list', CoolUtil.getSavePath());

		#if sys
		if (!FileSystem.exists(MOD_DIRECTORY))
			FileSystem.createDirectory(MOD_DIRECTORY);
		#end

		fs = PolymodFileSystem.makeFileSystem(null, {modRoot: MOD_DIRECTORY});

		reloadModList();
		reloadPolymod();
	}

	public static function reloadModList()
	{
		modList = [];

		var savedModList:Map<String, Bool> = cast save.data.modList;
		var doSave:Bool = false;
		if (savedModList == null)
		{
			savedModList = new Map<String, Bool>();
			doSave = true;
		}
		for (modMetadata in Polymod.scan({modRoot: MOD_DIRECTORY}))
		{
			if (modMetadata.id == GLOBAL_MOD_ID)
				continue;

			if (!savedModList.exists(modMetadata.id))
			{
				doSave = true;
				savedModList.set(modMetadata.id, true);
			}
			modList.push({metadata: modMetadata, enabled: savedModList.get(modMetadata.id)});
		}

		if (doSave)
		{
			save.data.modList = savedModList;
			save.flush();
		}
	}

	public static function saveModList()
	{
		var savedModList:Map<String, Bool> = new Map<String, Bool>();
		for (mod in modList)
			savedModList.set(mod.metadata.id, mod.enabled);
		save.data.modList = savedModList;
		save.flush();
	}

	public static function reloadPolymod()
	{
		var dirs:Array<String> = [];
		var globalDirPath:String = '$MOD_DIRECTORY/$GLOBAL_MOD_ID';
		if (fs.exists(globalDirPath) && fs.isDirectory(globalDirPath))
			dirs.push(GLOBAL_MOD_ID);
		for (mod in modList)
		{
			if (mod.enabled)
				dirs.push(mod.metadata.id);
		}

		Polymod.init({
			modRoot: MOD_DIRECTORY,
			dirs: dirs,
			customFilesystem: fs,
			framework: OPENFL,
			frameworkParams: {
				assetLibraryPaths: [
					"default" => "./preload", // ./preload
					"songs" => "./songs", 
					"shared" => "./", 
					"week2" => "./week2", 
					"week3" => "./week3", 
					"week4" => "./week4", 
					"week5" => "./week5", 
					"week6" => "./week6", 
					"week7" => "./week7"
				],
				coreAssetRedirect: 'assets'
			},
			parseRules: getParseRules(),
			extensionMap: extensions,
			ignoredFiles: Polymod.getDefaultIgnoreList()
		});
	}

	public static function getParseRules():ParseRules {
		final output:ParseRules = ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		return output != null ? output : null;
	}
}
