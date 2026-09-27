package substates;

import options.OptionsState;
import states.StoryMenuState;
import states.FreeplayState;
import flixel.input.mouse.FlxMouseEvent;

class IAFTPauseSubState extends MusicBeatSubstate
{
	var menuItemsOG:Map<String, Array<Int>> = [
		'pausebg' => [203, 0],
		'options' => [292, 181],
		'almanac' => [535, 181],
		'quit' => [776, 185],
		'daveplay' => [279, 377],
		'restart' => [548, 369],
		'resume' => [548, 511]
	];
	var pauseMusic:FlxSound;

	public static var songName:String = null;

	override function create()
	{
		FlxG.mouse.visible = true;
		cameras = [states.PlayState.instance.camOther];

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if (pauseSong != null)
				pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch (e:Dynamic)
		{
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		bg.cameras = cameras;
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		levelInfo.cameras = cameras;
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Difficulty.getString().toUpperCase(), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.cameras = cameras;
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, Language.getPhrase("blueballed", "Blueballed: {1}", [PlayState.deathCounter]), 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.cameras = cameras;
		add(blueballedTxt);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, Language.getPhrase("Charting Mode").toUpperCase(), 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		chartingText.cameras = cameras;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		// ordered maps not possible
		var pausebg:BGSprite = new BGSprite('pausemenu/pausebg', menuItemsOG.get('pausebg')[0], menuItemsOG.get('pausebg')[1], 0, 0);
		pausebg.alpha = 0;
		pausebg.cameras = cameras;
		add(pausebg);
		for (item => pos in menuItemsOG)
		{
			if (item == 'pausebg')
				continue;

			var menuItem:BGSprite = new BGSprite('pausemenu/$item', pos[0], pos[1], 0, 0);
			menuItem.alpha = 0;
			menuItem.cameras = cameras;
			add(menuItem);

			FlxMouseEvent.add(menuItem, function(sprite:BGSprite)
			{
				clickEvent(sprite, item);
			}, null, null, null, false, true, false);

			FlxTween.tween(menuItem, {alpha: 1}, 0.4, {ease: FlxEase.quartInOut});
		}

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(pausebg, {alpha: 1}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		super.create();
	}

	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none'))
			return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
	}

	override function destroy()
	{
		pauseMusic.destroy();
		super.destroy();
	}

	function clickEvent(item:BGSprite, option:String):Void
	{
		switch (option)
		{
			case 'options':
				PlayState.instance.paused = true; // For lua
				PlayState.instance.vocals.volume = 0;
				PlayState.instance.canResync = false;
				MusicBeatState.switchState(new OptionsState());
				if(ClientPrefs.data.pauseMusic != 'None')
				{
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
					FlxG.sound.music.time = pauseMusic.time;
				}
				OptionsState.onPlayState = true;

			case 'almanac':
				trace('ALMANAC!');

			case 'quit':
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;

				PlayState.instance.canResync = false;
				Mods.loadTopMod();
				if(PlayState.isStoryMode)
					MusicBeatState.switchState(new StoryMenuState());
				else 
					MusicBeatState.switchState(new FreeplayState());

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				FlxG.camera.followLerp = 0;

			case 'daveplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;
				PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
				PlayState.instance.botplayTxt.alpha = 1;
				PlayState.instance.botplaySine = 0;

			case 'restart':
				PauseSubState.restartSong();

			case 'resume':
				close();
		}
	}

	function clickedOptions(sprite:BGSprite):Void
	{
		trace('OPTIONS!');
	}

	function clickedAlmanac(sprite:BGSprite):Void
	{
		trace('ALMANAC!');
	}

	function clickedQuit(sprite:BGSprite):Void
	{
		trace('QUIT!');
	}

	function clickedDaveplay(sprite:BGSprite):Void
	{
		trace('DAVEPLAY!');
	}

	function clickedRestart(sprite:BGSprite):Void
	{
		trace('RESTART!');
	}

	function clickedResume(sprite:BGSprite):Void
	{
		trace('RESUME!');
		close();
	}
}
