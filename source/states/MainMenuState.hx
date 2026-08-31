package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;
	var allowMouse:Bool = true; //Turn this off to block mouse movement in menus

	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;

	//Centered/Text options
	var optionShit:Array<String> = [
		'story_mode',
		'options',
		'credits'
	];

	var leftOption:String = null;
	var rightOption:String = null;

	var selectorLeft:FlxSprite;
	var selectorRight:FlxSprite;
	var selectorLeftTween:FlxTween;
	var selectorRightTween:FlxTween;

	var spirals:FlxSpriteGroup;

	static var showOutdatedWarning:Bool = true;
	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		for (i in 1...3)
		{
			var layer:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/Layer$i'));
			layer.antialiasing = ClientPrefs.data.antialiasing;
			layer.scrollFactor.set();
			layer.setGraphicSize(1280, 720);
			layer.updateHitbox();
			layer.screenCenter();
			add(layer);
			if (i == 2)
				layer.blend = ADD;
		}

		var mic:FlxSprite = new FlxSprite(1000, 400).loadGraphic(Paths.image('mainmenu/mic'));
		mic.antialiasing = ClientPrefs.data.antialiasing;
		mic.setGraphicSize(mic.width * 0.7);
		mic.updateHitbox();
		mic.scrollFactor.set();
		add(mic);
		mic.angularVelocity = -20;
		FlxTween.tween(mic, {y: mic.y + 30}, 2.5, {ease: FlxEase.quadInOut, type: PINGPONG});

		spirals = new FlxSpriteGroup();
		add(spirals);

		var spiral1:FlxSprite = new FlxSprite(325, 500);
		spirals.add(spiral1);
		var spiral2:FlxSprite = new FlxSprite(50, 225);
		spirals.add(spiral2);
		var spiral3:FlxSprite = new FlxSprite(1115, 500);
		spirals.add(spiral3);

		spirals.forEach(function(spiral:FlxSprite)
		{
			for (i in 1...4)
				spiral.loadGraphic(Paths.image('mainmenu/spiral$i'));
			spiral.antialiasing = ClientPrefs.data.antialiasing;
			spiral.blend = ADD;
			spiral.angularVelocity = FlxG.random.int(-10, 10);
		});
		spiral1.setGraphicSize(spiral1.width * 0.65);
		spiral1.updateHitbox();
		spiral2.setGraphicSize(spiral2.width * 1.25);
		spiral2.updateHitbox();
		spiral2.flipX = true;
		spiral3.setGraphicSize(spiral3.width * 1.35);
		spiral3.updateHitbox();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var item:FlxSprite = createMenuItem(option, 0, ((num * 100) + offset) + 100);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

		for (i in 3...5)
		{
			var layer:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/Layer$i'));
			layer.antialiasing = false;
			layer.scrollFactor.set();
			layer.setGraphicSize(1280, 720);
			layer.updateHitbox();
			layer.screenCenter();
			add(layer);

			if (i == 3)
				layer.blend = ADD;
		}

		selectorLeft = new FlxSprite().loadGraphic(Paths.image('mainmenu/ArrowLeft'));
		selectorLeft.setGraphicSize(selectorLeft.width * 0.65);
		selectorLeft.updateHitbox();
		selectorLeft.offset.y -= 15;
		add(selectorLeft);
		selectorRight = new FlxSprite().loadGraphic(Paths.image('mainmenu/ArrowRight'));
		selectorRight.setGraphicSize(selectorRight.width * 0.65);
		selectorRight.updateHitbox();
		selectorRight.offset.y -= 15;
		add(selectorRight);

		var logo:FlxSprite = new FlxSprite(0, -FlxG.height).loadGraphic(Paths.image('mainmenu/Logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.scrollFactor.set();
		logo.setGraphicSize(logo.width * 0.65);
		logo.updateHitbox();
		logo.screenCenter(X);
		add(logo);
		new FlxTimer().start(0.5, function(tmr:FlxTimer) FlxTween.tween(logo, {y: 20}, 1, {ease: FlxEase.expoOut}));

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y).loadGraphic(Paths.image('mainmenu/menu_$name'));
		menuItem.setGraphicSize(Std.int(menuItem.width * 0.6));
		menuItem.updateHitbox();
		
		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			var allowMouse:Bool = allowMouse;
			if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)) //FlxG.mouse.deltaScreenX/Y checks is more accurate than FlxG.mouse.justMoved
			{
				allowMouse = false;
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					allowMouse = true;
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					allowMouse = true;
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
								allowMouse = true;
							}
						}
					}

					if(distItem != -1 && selectedItem != menuItems.members[distItem])
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if(timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				var item:FlxSprite;
				var option:String;
				switch(curColumn)
				{
					case CENTER:
						option = optionShit[curSelected];
						item = menuItems.members[curSelected];

					case LEFT:
						option = leftOption;
						item = leftItem;

					case RIGHT:
						option = rightOption;
						item = rightItem;
				}

				FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (option)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());

						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'achievements':
							MusicBeatState.switchState(new AchievementsMenuState());
						#end

						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						case 'donate':
							CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
							selectedSomethin = false;
							item.visible = true;
						default:
							trace('Menu Item ${option} doesn\'t do anything');
							selectedSomethin = false;
							item.visible = true;
					}
				});

				FlxFlicker.flicker(selectorLeft, 1, 0.1, false, false);
				FlxFlicker.flicker(selectorRight, 1, 0.1, false, false);
				
				for (memb in menuItems)
				{
					if(memb == item)
						continue;

					FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
		selectedItem.centerOffsets();
		selectedItem.screenCenter(X);

		selectorLeft.screenCenter(X);
		selectorRight.screenCenter(X);
		selectorLeft.x -= selectedItem.width;
		selectorLeft.y = selectedItem.y;
		selectorRight.x += selectedItem.width;
		selectorRight.y = selectedItem.y;

		selectorLeftTween?.cancel();
		selectorRightTween?.cancel();

		selectorLeftTween = FlxTween.tween(selectorLeft, {x: selectorLeft.x + 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
		selectorRightTween = FlxTween.tween(selectorRight, {x: selectorRight.x - 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
	}
}
