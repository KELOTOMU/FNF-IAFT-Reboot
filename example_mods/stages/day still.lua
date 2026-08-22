	-- quem leu tem a sexualidade duvidosa ;3
function onCreate()
	makeLuaSprite('IAFT day stage development', 'day/IAFT day stage development', -538, -752);
	setScrollFactor('IAFT day stage development', 1, 1);
	addLuaSprite('IAFT day stage development', false);

	if shadersEnabled == true then
        initLuaShader('adjustColor')
        for i, object in ipairs({'boyfriend', 'dad', 'gf'}) do
            setSpriteShader(object, 'adjustColor')
            setShaderFloat(object, 'hue', 15)
            setShaderFloat(object, 'saturation', 0)
            setShaderFloat(object, 'contrast', 15)
            setShaderFloat(object, 'brightness', 0)
        end
end
	close(true);
end