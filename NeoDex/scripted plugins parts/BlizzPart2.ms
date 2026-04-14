
plugin simpleManipulator BlizzParticle2
name:"BlizzPart2"
classID:#(0x2942cac, 0x43c6a3d9)
category:"Warcraft 3 Systems"
( 
	------------------------------------- Variable Registration -------------------------------------
	local ColorTemp 	  = color 255 255 255
	local Icon_Path = ((systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\neodex_icons\\")
	local MessageboxText  = "Head:\nParticles will always face forward, similar to billboard effect\nTail:\nParticles will have orientation angle, similar to ribbon effect\nTexture will be applied in the direction of ribbon texture"
	local MessageboxTitle = "Tips"
	local MessageboxText2 = "Conversion Complete!"
	local MessageboxText3 = "No animation data for current property!"
	------------------------------------- Menu Registration -------------------------------------

	fn adjustColor_PS baseColor hueShift satShift brightShift =
	(
		-- Delegate to the global Photoshop-compatible HSB color adjustment
		-- (defined in NeoDex GlobalFN / ::NeoDexUtils)
		::NeoDexUtils.AdjustColor_PS baseColor hueShift satShift brightShift
	)

	parameters main rollout:General
    (
        adsorption  type:#string	ui:Temp_adsorption
    )

    parameters main rollout:paramsE
    (
        IsAnim      type:#boolean	ui:CB_IsAnim    animatable:false	default:true
    )

	parameters main rollout:params1
	(
		rtexture 	type:#integer	ui:rtexture 	animatable:false	default:1
		texture 	type:#string	ui:texture		animatable:false
		path 		type:#string	ui:path			animatable:false	default:"Textures\\"
		filtermode 	type:#integer	ui:filtermode	animatable:false	default:2
		rows 		type:#integer	ui:rows			animatable:false	default:1
		cols 		type:#integer 	ui:cols			animatable:false	default:1
		Unshaded 	type:#boolean 	ui:unshaded		animatable:false	default:false
		Unfogged 	type:#boolean	ui:unfogged		animatable:false	default:false
		SortZ 		type:#boolean	ui:sortz		animatable:false	default:false
		textureid 	type:#integer					animatable:false	default:0 
	)

	parameters main rollout:params2
	(
		width		type:#float		ui:LZwidth --default: 10.0
		length		type:#float		ui:LZlength --default: 10.0
		LineEmitter type:#integer	ui:LineEmitter default:1    animatable:false
	)

	parameters main rollout:params3
	(
		Life        type:#float     ui:life     default:1.0     animatable:false
		PartsEmit   type:#float     ui:PartEmit default:50.0
		-- Visibility entfernt
		Squirt      type:#boolean   ui:Squirt   default:false   animatable:false
	)

	parameters main rollout:params4
	(
		speed		type:#float ui:speed	 default:10.0
		variation	type:#float ui:variation default:0.0
		coneangle	type:#float ui:coneangle default:0.0
		gravity		type:#float ui:gravity	 default:0.0
	)

	parameters main rollout:params5
	(
		priorityplane	type:#integer ui:Priority   default:0     animatable:false
		ParticleSpace	type:#boolean ui:PartSpace  default:false animatable:false
		XYQuads			type:#boolean ui:XYQuads    default:false animatable:false
	)

	parameters main rollout:params6
	(
		startcolor		type:#color   ui:Scolor			default:[255,255,255] animatable:false
		YS_startcolor	type:#color   ui:YS_Scolor		default:[255,255,255] animatable:false
		startalpha		type:#float   ui:Salpha			default:255			  animatable:false
		startscale		type:#float   ui:Sscale			default:10.0		  animatable:false
		middlecolor		type:#color   ui:Mcolor    		default:[128,128,128] animatable:false
		YS_middlecolor	type:#color   ui:YS_Mcolor		default:[128,128,128] animatable:false
		middlealpha		type:#float   ui:Malpha   		default:128           animatable:false
		middlescale		type:#float   ui:Mscale    		default:10.0          animatable:false
		midtime			type:#float   ui:MiddleTime		default:0.5           animatable:false
		endcolor		type:#color   ui:Ecolor			default:[0,0,0]		  animatable:false
		YS_endcolor		type:#color   ui:YS_Ecolor		default:[0,0,0]		  animatable:false
		endalpha		type:#float   ui:Ealpha			default:0			  animatable:false
		endscale		type:#float	  ui:Escale			default:10.0		  animatable:false
		TJQSeXiang		type:#integer ui:SeXiang		default:0			  animatable:false
		TJQBaoHeDu		type:#integer ui:BaoHeDu		default:0			  animatable:false
		TJQMingDu		type:#integer ui:MingDu			default:0			  animatable:false
		HKTSeXiang		type:#integer ui:sld_SeXiang	default:0			  animatable:false
		HKTBaoHeDu		type:#integer ui:sld_BaoHeDu	default:0			  animatable:false
		HKTMingDu		type:#integer ui:sld_MingDu		default:0			  animatable:false
	)

	parameters main rollout:params9
	(
		particletype type:#integer ui:PartType   default:1   animatable:false
		taillength   type:#float   ui:TailLength default:1.0 animatable:false
	)

	parameters main rollout:params10
	(
		startLifespanHead  type:#integer ui:Slheaduw default:0 animatable:false
		endLifespanHead    type:#integer ui:Elheaduw default:0 animatable:false
		repeatLifespanHead type:#integer ui:Rlheaduw default:1 animatable:false
		startDecayHead	   type:#integer ui:Sdheaduw default:0 animatable:false
		endDecayHead       type:#integer ui:Edheaduw default:0 animatable:false
		repeatDecayHead    type:#integer ui:Rdheaduw default:1 animatable:false
		startLifespanTail  type:#integer ui:Sltailuw default:0 animatable:false
		endLifespanTail    type:#integer ui:Eltailuw default:0 animatable:false
		repeatLifespanTail type:#integer ui:Rltailuw default:1 animatable:false
		startDecayTail     type:#integer ui:Sdtailuw default:0 animatable:false
		endDecayTail       type:#integer ui:Edtailuw default:0 animatable:false
		repeatDecayTail    type:#integer ui:Rdtailuw default:1 animatable:false
	)	
	------------------------ Define function to parse data and prepare keyframe info ------------------------
	fn PrepareKeyData dataStr delimiter1 delimiter2 =
	(
		local keyValuePairs = filterString dataStr delimiter1
		local keyData = #()
		for keyValue in keyValuePairs do
		(
			local parts = filterString keyValue delimiter2
			-- Prüfe ob beide Teile vorhanden sind
			if parts.count >= 2 and parts[1] != undefined and parts[2] != undefined then
			(
				local frameTime = parts[1] as time
				local frameValue = parts[2] as float
				if frameValue != undefined then
					append keyData #(frameTime, frameValue)
			)
		)
		return keyData
	)
	-----------------------------------Import particle configuration parameters-----------------------------------
	fn ImportParticle = 
(
    stopAnimation()
    sliderTime += 1
    local input_file = getOpenFileName caption:(::L.t "bp2_select_particleb_data_file_cap") types:"Config File (*.ini)|*.ini|" historyCategory:"ParticleBImportHistory"
    if (input_file == undefined) then (return undefined)
    local particleObj = selection[1]
    ----------------------------------------------------------------------------------------------------------------------
    local Date01 = getINISetting input_file "BlizzPart2" "PreFix"
    local Date02 = getINISetting input_file "BlizzPart2" "File"
    local Date03 = getINISetting input_file "BlizzPart2" "MixedMode"
    local Date04 = getINISetting input_file "BlizzPart2" "UnShadow"
    local Date05 = getINISetting input_file "BlizzPart2" "UnFogged"
    local Date06 = getINISetting input_file "BlizzPart2" "SortZ"
    local Date07 = getINISetting input_file "BlizzPart2" "ReplaceableTexture"
    local Date08 = getINISetting input_file "BlizzPart2" "Rows"
    local Date09 = getINISetting input_file "BlizzPart2" "Cols"
    local Date10 = getINISetting input_file "BlizzPart2" "Width"
    local Date11 = getINISetting input_file "BlizzPart2" "Length"
    local Date12 = getINISetting input_file "BlizzPart2" "EmitterType"
    local Date13 = getINISetting input_file "BlizzPart2" "LifeSpan"
    local Date14 = getINISetting input_file "BlizzPart2" "PartsEmit"
    local Date15 = getINISetting input_file "BlizzPart2" "Visibility"
    local Date16 = getINISetting input_file "BlizzPart2" "SquirtPartEmit"
    local Date17 = getINISetting input_file "BlizzPart2" "Speed"
    local Date18 = getINISetting input_file "BlizzPart2" "Variation"
    local Date19 = getINISetting input_file "BlizzPart2" "Coneangle"
    local Date20 = getINISetting input_file "BlizzPart2" "Gravity"
    local Date21 = getINISetting input_file "BlizzPart2" "PriorityPlane"
    local Date22 = getINISetting input_file "BlizzPart2" "ModelSpace"
    local Date23 = getINISetting input_file "BlizzPart2" "XYQuads"
    local Date24 = getINISetting input_file "BlizzPart2" "StartColor"
    local Date25 = getINISetting input_file "BlizzPart2" "StartAlpha"
    local Date26 = getINISetting input_file "BlizzPart2" "StartScale"
    local Date27 = getINISetting input_file "BlizzPart2" "MiddleColor"
    local Date28 = getINISetting input_file "BlizzPart2" "MiddleAlpha"
    local Date29 = getINISetting input_file "BlizzPart2" "MiddleScale"
    local Date30 = getINISetting input_file "BlizzPart2" "MiddleLifeSpan"
    local Date31 = getINISetting input_file "BlizzPart2" "EndColor"
    local Date32 = getINISetting input_file "BlizzPart2" "EndAlpha"
    local Date33 = getINISetting input_file "BlizzPart2" "EndScale"
    local Date34 = getINISetting input_file "BlizzPart2" "Head&TailFlag"
    local Date35 = getINISetting input_file "BlizzPart2" "TailLength"
    local Date36 = getINISetting input_file "BlizzPart2" "Head(LifeSpan)Start"
    local Date37 = getINISetting input_file "BlizzPart2" "Head(LifeSpan)End"
    local Date38 = getINISetting input_file "BlizzPart2" "Head(LifeSpan)Repeat"
    local Date39 = getINISetting input_file "BlizzPart2" "Head(Decay)Start"
    local Date40 = getINISetting input_file "BlizzPart2" "Head(Decay)End"
    local Date41 = getINISetting input_file "BlizzPart2" "Head(Decay)Repeat"
    local Date42 = getINISetting input_file "BlizzPart2" "Tail(LifeSpan)Start"
    local Date43 = getINISetting input_file "BlizzPart2" "Tail(LifeSpan)End"
    local Date44 = getINISetting input_file "BlizzPart2" "Tail(LifeSpan)Repeat"
    local Date45 = getINISetting input_file "BlizzPart2" "Tail(Decay)Start"
    local Date46 = getINISetting input_file "BlizzPart2" "Tail(Decay)End"
    local Date47 = getINISetting input_file "BlizzPart2" "Tail(Decay)Repeat"
    ----------------------------------------------------------------------------------------------------------------------
    if Date24 != undefined do
    (
        local C_Index = findString Date24 ")"
        local C_String = substring Date24 1 (C_Index-1)
        local C_String_Z = filterString C_String " "
        particleObj.params6.Scolor.color = color (C_String_Z[2] as float) (C_String_Z[3] as float) (C_String_Z[4] as float)
        particleObj.params6.YS_Scolor.color = particleObj.params6.Scolor.color
    )
    if Date27 != undefined do
    (
        local C_Index = findString Date27 ")"
        local C_String = substring Date27 1 (C_Index-1)
        local C_String_Z = filterString C_String " "
        particleObj.params6.Mcolor.color = color (C_String_Z[2] as float) (C_String_Z[3] as float) (C_String_Z[4] as float)
        particleObj.params6.YS_Mcolor.color = particleObj.params6.Mcolor.color
    )
    if Date31 != undefined do
    (
        local C_Index = findString Date31 ")"
        local C_String = substring Date31 1 (C_Index-1)
        local C_String_Z = filterString C_String " "
        particleObj.params6.Ecolor.color = color (C_String_Z[2] as float) (C_String_Z[3] as float) (C_String_Z[4] as float)
        particleObj.params6.YS_Ecolor.color = particleObj.params6.Ecolor.color
    )
    ----------------------------------------------------------------------------------------------------------------------
    if (Date01 != undefined) do (particleObj.path = Date01)
    if (Date02 != undefined) do (particleObj.texture = Date02)
    if (Date03 != undefined) do
    (
        if (Date03 == "Blend") do (particleObj.filtermode = 1)
        if (Date03 == "Additive") do (particleObj.filtermode = 2)
        if (Date03 == "Modulate") do (particleObj.filtermode = 3)
        if (Date03 == "Modulate2x") do (particleObj.filtermode = 4)
        if (Date03 == "AlphaKey") do (particleObj.filtermode = 5)
    )
    if (Date04 != undefined) do (if (Date04 == "True") then (particleObj.unshaded = true) else (particleObj.unshaded = false))
    if (Date05 != undefined) do (if (Date05 == "True") then (particleObj.unfogged = true) else (particleObj.unfogged = false))
    if (Date06 != undefined) do (if (Date06 == "True") then (particleObj.SortZ = true) else (particleObj.SortZ = false))
    if (Date07 != undefined) do
    (
        if (Date07 == "NotUsed" or Date07 == "1") do (particleObj.rtexture = 1)
        if (Date07 == "TeamColor" or Date07 == "2") do (particleObj.rtexture = 2)
        if (Date07 == "TeamGlow" or Date07 == "3") do (particleObj.rtexture = 3)
    )
    if (Date08 != undefined) do (particleObj.rows = Date08 as integer)
    if (Date09 != undefined) do (particleObj.cols = Date09 as integer)
    -------------------------------------------------------------------------------------------------
    if Date10 != undefined do
    (
        local useWidthAnim = getINISetting input_file "BlizzPart2" "WidthUseAnim"
        if useWidthAnim != undefined and useWidthAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.width.controller = bezier_float ()
                if particleObj.width.isAnimated == false then
                (
                    addNewKey particleObj.width.controller 0f
                )else
                (
                    deleteKeys particleObj.width.controller #allKeys
                    addNewKey particleObj.width.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Width"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.width.controller key[1]
                        particleObj.width.controller.keys[particleObj.width.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.width.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Width"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.width.controller #allKeys
                    addNewKey particleObj.width.controller 0f
                    particleObj.width.controller.keys[1].value = MaxkeyValue
                )else(particleObj.width = MaxkeyValue)
            )
        )else(particleObj.width = Date10 as float)
    )
    ----------------------------------------------------------------------------------------------------
    if Date11 != undefined do
    (
        local useLengthAnim = getINISetting input_file "BlizzPart2" "LengthUseAnim"
        if useLengthAnim != undefined and useLengthAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.length.controller = bezier_float ()
                if particleObj.length.isAnimated == false then
                (
                    addNewKey particleObj.length.controller 0f
                )else
                (
                    deleteKeys particleObj.length.controller #allKeys
                    addNewKey particleObj.length.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Length"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.length.controller key[1]
                        particleObj.length.controller.keys[particleObj.length.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.length.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Length"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.length.controller #allKeys
                    addNewKey particleObj.length.controller 0f
                    particleObj.length.controller.keys[1].value = MaxkeyValue
                )else(particleObj.length = MaxkeyValue)
            )
        )else(particleObj.length = Date11 as float)
    )
    ----------------------------------------------------------------------------------------------------
    if (Date12 != undefined) do (if (Date12 == "1") then (particleObj.lineEmitter = 1) else (particleObj.lineEmitter = 2))
    if (Date13 != undefined) do (particleObj.Life = Date13 as float)
    ----------------------------------------------------------------------------------------------
    if Date14 != undefined do
    (
        local usePartsEmitAnim = getINISetting input_file "BlizzPart2" "PartsEmitUseAnim"
        if usePartsEmitAnim != undefined and usePartsEmitAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.PartsEmit.controller = bezier_float ()
                if particleObj.PartsEmit.isAnimated == false then
                (
                    addNewKey particleObj.PartsEmit.controller 0f
                )else
                (
                    deleteKeys particleObj.PartsEmit.controller #allKeys
                    addNewKey particleObj.PartsEmit.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "PartsEmit"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.PartsEmit.controller key[1]
                        particleObj.PartsEmit.controller.keys[particleObj.PartsEmit.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.PartsEmit.controller
                local dataStr = getINISetting input_file "BlizzPart2" "PartsEmit"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.PartsEmit.controller #allKeys
                    addNewKey particleObj.PartsEmit.controller 0f
                    particleObj.PartsEmit.controller.keys[1].value = MaxkeyValue
                )else(particleObj.PartsEmit = MaxkeyValue)
            )
        )else(particleObj.PartsEmit = Date14 as float)
    )
    ----------------------------------------------------------------------------------------------
    if Date15 != undefined do
    (
        if getINISetting input_file "BlizzPart2" "VisibilityUseAnim" == "True" then
        (
            -- Parse die Animationsdaten einmal am Anfang
            local dataStr = getINISetting input_file "BlizzPart2" "Visibility"
            local keyData = prepareKeyData dataStr "|" " "
            local MaxkeyValue = 0.0
            
            -- Finde den Maximalwert (wird in beiden Fällen benötigt)
            for key in keyData do 
            (
                if key[2] != undefined and key[2] > MaxkeyValue do 
                    MaxkeyValue = key[2]
            )
            
            if (particleObj.IsAnim == true) then
            (
                -- WICHTIG: Zuerst Visibility initialisieren um den Track zu erstellen
                particleObj.visibility = true
                
                -- Versuche animierte Visibility zu setzen
                try
                (
                    -- Controller zuweisen (Track sollte jetzt existieren)
                    particleObj.visibility.controller = bezier_float()
                    local visCtrl = particleObj.visibility.controller
                    
                    -- Lösche alte Keys falls vorhanden
                    deleteKeys visCtrl #allKeys
                    
                    -- Füge alle Keyframes hinzu
                    for key in keyData do
                    (
                        if key[1] != undefined and key[2] != undefined then
                        (
                            local newKey = addNewKey visCtrl key[1]
                            newKey.value = key[2]
                        )
                    )
                )
                catch
                (
                    -- Falls Animation nicht möglich, setze statischen Wert als Boolean
                    particleObj.visibility = (MaxkeyValue > 0.5)
                )
            )
            else
            (
                -- IsAnim ist false, setze statischen Wert als Boolean
                particleObj.visibility = (MaxkeyValue > 0.5)
            )
        )
        else
        (
            -- Keine Animation verwendet, konvertiere zu passendem Typ
            local visValue = 1.0
            case Date15 of
            (
                "true":  visValue = 1.0
                "True":  visValue = 1.0
                "false": visValue = 0.0
                "False": visValue = 0.0
                default: try (visValue = Date15 as float) catch (visValue = 1.0)
            )
            
            -- Setze die Object-Visibility - versuche erst mit Controller, dann direkt
            try
            (
                -- Versuche einen Controller zu erstellen und den Wert zu setzen
                if particleObj.visibility.controller == undefined then
                    particleObj.visibility.controller = bezier_float()
                particleObj.visibility.controller.value = visValue
            )
            catch
            (
                -- Falls das nicht klappt, setze als Boolean
                particleObj.visibility = (visValue > 0.5)
            )
        )
    )
    ------------------------------------------------------------------------------------------------------------------------------------------------------------
    if (Date16 != undefined) do (if (Date16 == "True") then (particleObj.params3.squirt.checked = true) else (particleObj.params3.squirt.checked = false))
    ------------------------------------------------------------------------------------------------------------------------------------------------------------
    if Date17 != undefined do
    (
        local useSpeedAnim = getINISetting input_file "BlizzPart2" "SpeedUseAnim"
        if useSpeedAnim != undefined and useSpeedAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.speed.controller = bezier_float ()
                if particleObj.speed.isAnimated == false then
                (
                    addNewKey particleObj.speed.controller 0f
                )else
                (
                    deleteKeys particleObj.speed.controller #allKeys
                    addNewKey particleObj.speed.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Speed"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.speed.controller key[1]
                        particleObj.speed.controller.keys[particleObj.speed.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.speed.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Speed"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.speed.controller #allKeys
                    addNewKey particleObj.speed.controller 0f
                    particleObj.speed.controller.keys[1].value = MaxkeyValue
                )else(particleObj.speed = MaxkeyValue)
            )
        )else(particleObj.speed = Date17 as float)
    )
    ----------------------------------------------------------------------------------------------        
    if Date18 != undefined do
    (
        local useVarAnim = getINISetting input_file "BlizzPart2" "VariationUseAnim"
        if useVarAnim != undefined and useVarAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.variation.controller = bezier_float ()
                if particleObj.variation.isAnimated == false then
                (
                    addNewKey particleObj.variation.controller 0f
                )else
                (
                    deleteKeys particleObj.variation.controller #allKeys
                    addNewKey particleObj.variation.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Variation"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.variation.controller key[1]
                        particleObj.variation.controller.keys[particleObj.variation.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.variation.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Variation"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.variation.controller #allKeys
                    addNewKey particleObj.variation.controller 0f
                    particleObj.variation.controller.keys[1].value = MaxkeyValue
                )else(particleObj.variation = MaxkeyValue)
            )
        )else(particleObj.variation = Date18 as float)
    )
    ----------------------------------------------------------------------------------------------    
    if Date19 != undefined do
    (
        local useConeAnim = getINISetting input_file "BlizzPart2" "ConeangleUseAnim"
        if useConeAnim != undefined and useConeAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.coneangle.controller = bezier_float ()
                if particleObj.coneangle.isAnimated == false then
                (
                    addNewKey particleObj.coneangle.controller 0f
                )else
                (
                    deleteKeys particleObj.coneangle.controller #allKeys
                    addNewKey particleObj.coneangle.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Coneangle"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.coneangle.controller key[1]
                        particleObj.coneangle.controller.keys[particleObj.coneangle.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.coneangle.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Coneangle"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.coneangle.controller #allKeys
                    addNewKey particleObj.coneangle.controller 0f
                    particleObj.coneangle.controller.keys[1].value = MaxkeyValue
                )else(particleObj.coneangle = MaxkeyValue)
            )
        )
        else(particleObj.coneangle = Date19 as float)
    )
    ----------------------------------------------------------------------------------------------    
    if Date20 != undefined do
    (
        local useGravityAnim = getINISetting input_file "BlizzPart2" "GravityUseAnim"
        if useGravityAnim != undefined and useGravityAnim == "True" then
        (
            if (particleObj.IsAnim == true) then
            (
                particleObj.gravity.controller = bezier_float ()
                if particleObj.gravity.isAnimated == false then
                (
                    addNewKey particleObj.gravity.controller 0f
                )else
                (
                    deleteKeys particleObj.gravity.controller #allKeys
                    addNewKey particleObj.gravity.controller 0f
                )
                local dataStr = getINISetting input_file "BlizzPart2" "Gravity"
                local keyData = prepareKeyData dataStr "|" " "
                for key in keyData do
                (
                    if key[1] != undefined and key[2] != undefined then
                    (
                        addNewKey particleObj.gravity.controller key[1]
                        particleObj.gravity.controller.keys[particleObj.gravity.controller.keys.count].value = key[2]
                    )
                )
            )else
            (
                local tmp = particleObj.gravity.controller
                local dataStr = getINISetting input_file "BlizzPart2" "Gravity"
                local keyData = prepareKeyData dataStr "|" " "
                local MaxkeyValue = 0.0
                for key in keyData do (if key[2] != undefined and key[2] > MaxkeyValue do MaxkeyValue = key[2])
                if tmp != undefined then
                (
                    deleteKeys particleObj.gravity.controller #allKeys
                    addNewKey particleObj.gravity.controller 0f
                    particleObj.gravity.controller.keys[1].value = MaxkeyValue
                )else(particleObj.gravity = MaxkeyValue)
            )
        )else(particleObj.gravity = Date20 as float)
    )
    ----------------------------------------------------------------------------------------------    
    if (Date21 != undefined) do (particleObj.params5.Priority.value = Date21 as integer)
    if (Date22 != undefined) do (if (Date22 == "True") then (particleObj.params5.PartSpace.checked = true) else (particleObj.params5.PartSpace.checked = false))
    if (Date23 != undefined) do (if (Date23 == "True") then (particleObj.params5.XYQuads.checked = true) else (particleObj.params5.XYQuads.checked = false))
    if (Date25 != undefined) do (particleObj.params6.Salpha.value = Date25 as integer)
    if (Date26 != undefined) do (particleObj.params6.Sscale.value = Date26 as float)
    if (Date28 != undefined) do (particleObj.params6.Malpha.value = Date28 as integer)
    if (Date29 != undefined) do (particleObj.params6.Mscale.value = Date29 as float)
    if (Date30 != undefined) do (particleObj.params6.MiddleTime.value = Date30 as float)
    if (Date32 != undefined) do (particleObj.params6.Ealpha.value = Date32 as integer)
    if (Date33 != undefined) do (particleObj.params6.Escale.value = Date33 as float)
    if (Date34 != undefined) do
    (
        if (Date34 == "1") do (particleObj.params9.PartType.selection = 1)
        if (Date34 == "2") do (particleObj.params9.PartType.selection = 2)
        if (Date34 == "3") do (particleObj.params9.PartType.selection = 3)
    )
    if (Date35 != undefined) do (particleObj.params9.tailLength.value = Date35 as float)
    if (Date36 != undefined) do (particleObj.params10.Slheaduw.value = Date36 as integer)
    if (Date37 != undefined) do (particleObj.params10.Elheaduw.value = Date37 as integer)
    if (Date38 != undefined) do (particleObj.params10.Rlheaduw.value = Date38 as integer)
    if (Date39 != undefined) do (particleObj.params10.Sdheaduw.value = Date39 as integer)
    if (Date40 != undefined) do (particleObj.params10.Edheaduw.value = Date40 as integer)
    if (Date41 != undefined) do (particleObj.params10.Rdheaduw.value = Date41 as integer)
    if (Date42 != undefined) do (particleObj.params10.Sltailuw.value = Date42 as integer)
    if (Date43 != undefined) do (particleObj.params10.Eltailuw.value = Date43 as integer)
    if (Date44 != undefined) do (particleObj.params10.Rltailuw.value = Date44 as integer)
    if (Date45 != undefined) do (particleObj.params10.Sdtailuw.value = Date45 as integer)
    if (Date46 != undefined) do (particleObj.params10.Edtailuw.value = Date46 as integer)
    if (Date47 != undefined) do (particleObj.params10.Rdtailuw.value = Date47 as integer)
    ------------------------------------- UI Refresh (only for non-animated properties) -------------------------------------
    if not particleObj.width.isAnimated do particleObj.width = particleObj.width
    if not particleObj.length.isAnimated do particleObj.length = particleObj.length
    if not particleObj.PartsEmit.isAnimated do particleObj.PartsEmit = particleObj.PartsEmit
    if not particleObj.visibility.isAnimated do particleObj.visibility = particleObj.visibility
    if not particleObj.speed.isAnimated do particleObj.speed = particleObj.speed
    if not particleObj.variation.isAnimated do particleObj.variation = particleObj.variation
    if not particleObj.coneangle.isAnimated do particleObj.coneangle = particleObj.coneangle
    if not particleObj.gravity.isAnimated do particleObj.gravity = particleObj.gravity
    sliderTime -= 1
)
	-----------------------------------粒子动画数据输出------------------------------------
	fn ExportParticleAnimal ZJ PZXNR Path index =	  --ZJ=组件 PZXNR=配置项内容名 Path=输出路径
	(
        local str = setINISetting Path "BlizzPart2" PZXNR ""
        local str = ""
		if (index == 1)do
		(
			for i in ZJ.width.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 2)do
		(
			for i in ZJ.length.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 3)do
		(
			for i in ZJ.PartsEmit.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 4)do
		(
			for i in ZJ.Visibility.controller.keys do  -- War: ZJ.Palpha
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 5)do
		(
			for i in ZJ.speed.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 6)do
		(
			for i in ZJ.variation.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 7)do
		(
			for i in ZJ.coneangle.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
		if (index == 8)do
		(
			for i in ZJ.gravity.controller.keys do
			(
				local str4444 = (i.time) as string
				local str5555 = (i.value) as string
				append str (str4444 + " " + str5555 + "|")
				setINISetting Path "BlizzPart2" PZXNR str
			)
		)
        str	= getINISetting Path "BlizzPart2" PZXNR
        local NewStr = substring Str 1 (Str.count - 1)
        setINISetting Path "BlizzPart2" PZXNR NewStr
	)
	-----------------------------------导出粒子配置参数-----------------------------------
	fn ExportParticle = 
	(
		local output_file = getSaveFileName caption:(::L.t "bp2_select_the_location_to_export_cap") types:"Config File (*.ini)|*.ini|" historyCategory:"ParticleBExportHistory"
		if output_file != undefined then
		(
			local particleObj = selection[1]
			if (particleObj.path 	!= undefined)		do (setINISetting output_file "BlizzPart2" "PreFix" particleObj.path)
			if (particleObj.texture	!= undefined)		do (setINISetting output_file "BlizzPart2" "File" particleObj.texture)
			if (particleObj.filtermode == 1) 			do (setINISetting output_file "BlizzPart2" "MixedMode" "Blend")
			if (particleObj.filtermode == 2) 			do (setINISetting output_file "BlizzPart2" "MixedMode" "Additive")
			if (particleObj.filtermode == 3) 			do (setINISetting output_file "BlizzPart2" "MixedMode" "Modulate")
			if (particleObj.filtermode == 4) 			do (setINISetting output_file "BlizzPart2" "MixedMode" "Modulate2x")
			if (particleObj.filtermode == 5) 			do (setINISetting output_file "BlizzPart2" "MixedMode" "AlphaKey")
			if (particleObj.unshaded == true) then (setINISetting output_file "BlizzPart2" "UnShadow" "True") else (setINISetting output_file "BlizzPart2" "UnShadow" "False")
			if (particleObj.unfogged == true) then (setINISetting output_file "BlizzPart2" "UnFogged" "True") else (setINISetting output_file "BlizzPart2" "UnFogged" "False")
			if (particleObj.SortZ == true)	 then (setINISetting output_file "BlizzPart2" "SortZ" "True")	   else (setINISetting output_file "BlizzPart2" "SortZ" "False")
			if (particleObj.rtexture == 1)				do (setINISetting output_file "BlizzPart2" "ReplaceableTexture" "1")
			if (particleObj.rtexture == 2)				do (setINISetting output_file "BlizzPart2" "ReplaceableTexture" "2")
			if (particleObj.rtexture == 3)				do (setINISetting output_file "BlizzPart2" "ReplaceableTexture" "3")
			setINISetting output_file "BlizzPart2" "Rows" (particleObj.rows as string)
			setINISetting output_file "BlizzPart2" "Cols" (particleObj.cols as string)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.width.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Width" output_file 1
                    setINISetting output_file "BlizzPart2" "WidthUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.width.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Width" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "WidthUseAnim" "False"
                )     
			)else 
			(
				setINISetting output_file "BlizzPart2" "Width" (particleObj.width as string)
				setINISetting output_file "BlizzPart2" "WidthUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.length.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Length" output_file 2
                    setINISetting output_file "BlizzPart2" "LengthUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.length.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Length" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "LengthUseAnim" "False"
                ) 
			)else
			(
				setINISetting output_file "BlizzPart2" "Length" (particleObj.length as string)
				setINISetting output_file "BlizzPart2" "LengthUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.lineEmitter == 1)	do (setINISetting output_file "BlizzPart2" "EmitterType" "1")
			if (particleObj.lineEmitter == 2)	do (setINISetting output_file "BlizzPart2" "EmitterType" "2")
			setINISetting output_file "BlizzPart2" "LifeSpan" (particleObj.Life as string)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.PartsEmit.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "PartsEmit" output_file 3
                    setINISetting output_file "BlizzPart2" "PartsEmitUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.PartsEmit.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "PartsEmit" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "PartsEmitUseAnim" "False"
                )
			)else
			(
				setINISetting output_file "BlizzPart2" "PartsEmit" (particleObj.PartsEmit as string)
				setINISetting output_file "BlizzPart2" "PartsEmitUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			-- Ersetze diese Zeilen:
			if (particleObj.visibility.isAnimated != false) then
			(
				if particleObj.IsAnim then
				(
					-- Exportiere die Visibility-Animation
					local str = ""
					for i in particleObj.visibility.controller.keys do
					(
						local str4444 = (i.time) as string
						local str5555 = (i.value) as string
						append str (str4444 + " " + str5555 + "|")
					)
					local NewStr = substring str 1 (str.count - 1)
					setINISetting output_file "BlizzPart2" "Visibility" NewStr
					setINISetting output_file "BlizzPart2" "VisibilityUseAnim" "True"
				)else
				(
					local MaxkeyValue = 0.0
					for i in particleObj.visibility.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
					setINISetting output_file "BlizzPart2" "Visibility" (MaxkeyValue as string)
					setINISetting output_file "BlizzPart2" "VisibilityUseAnim" "False"
				)
			)else
			(
				setINISetting output_file "BlizzPart2" "Visibility" (particleObj.visibility as string)
				setINISetting output_file "BlizzPart2" "VisibilityUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.params3.squirt.checked == true) then (setINISetting output_file "BlizzPart2" "SquirtPartEmit" "True") else (setINISetting output_file "BlizzPart2" "SquirtPartEmit" "False")
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.speed.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Speed" output_file 5
                    setINISetting output_file "BlizzPart2" "SpeedUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.speed.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Speed" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "SpeedUseAnim" "False"
                )
			)else
			(
				setINISetting output_file "BlizzPart2" "Speed" (particleObj.speed as string)
				setINISetting output_file "BlizzPart2" "SpeedUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.variation.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Variation" output_file 6
                    setINISetting output_file "BlizzPart2" "VariationUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.variation.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Variation" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "VariationUseAnim" "False"
                )    
			)else
			(
				setINISetting output_file "BlizzPart2" "Variation" (particleObj.variation as string)
				setINISetting output_file "BlizzPart2" "VariationUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.coneangle.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Coneangle" output_file 7
                    setINISetting output_file "BlizzPart2" "ConeangleUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.coneangle.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Coneangle" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "ConeangleUseAnim" "False"
                )
			)else
			(
				setINISetting output_file "BlizzPart2" "Coneangle" (particleObj.coneangle as string)
				setINISetting output_file "BlizzPart2" "ConeangleUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			if (particleObj.gravity.isAnimated != false) then
			(
                if particleObj.IsAnim then
                (
                    ExportParticleAnimal particleObj "Gravity" output_file 8
                    setINISetting output_file "BlizzPart2" "GravityUseAnim" "True"
                )else
                (
                    local MaxkeyValue = 0.0
                    for i in particleObj.gravity.controller.keys do (if i.value > MaxkeyValue do MaxkeyValue = i.value)
                    setINISetting output_file "BlizzPart2" "Gravity" (MaxkeyValue as string)
                    setINISetting output_file "BlizzPart2" "GravityUseAnim" "False"
                )
			)else
			(
				setINISetting output_file "BlizzPart2" "Gravity" (particleObj.gravity as string)
				setINISetting output_file "BlizzPart2" "GravityUseAnim" "False"
			)
			----------------------------------------------------------------------------------------------------------------------------------
			setINISetting output_file "BlizzPart2" "PriorityPlane" (particleObj.priorityplane as string)
			if (particleObj.ParticleSpace == true) then (setINISetting output_file "BlizzPart2" "ModelSpace" "True") else (setINISetting output_file "BlizzPart2" "ModelSpace" "False")
			if (particleObj.XYQuads == true)	then (setINISetting output_file "BlizzPart2" "XYQuads" "True") else (setINISetting output_file "BlizzPart2" "XYQuads" "False")
			setINISetting output_file "BlizzPart2" "StartColor"		(particleObj.startcolor as string)
			setINISetting output_file "BlizzPart2" "StartAlpha"		(particleObj.startalpha as string)
			setINISetting output_file "BlizzPart2" "StartScale"		(particleObj.Startscale as string)
			setINISetting output_file "BlizzPart2" "MiddleColor"		(particleObj.Middlecolor as string)
			setINISetting output_file "BlizzPart2" "MiddleAlpha"		(particleObj.Middlealpha as string)
			setINISetting output_file "BlizzPart2" "MiddleScale"		(particleObj.Middlescale as string)
			setINISetting output_file "BlizzPart2" "MiddleLifeSpan"	(particleObj.midtime as string)
			setINISetting output_file "BlizzPart2" "EndColor" (particleObj.Endcolor as string)
			setINISetting output_file "BlizzPart2" "EndAlpha"	(particleObj.Endalpha as string)
			setINISetting output_file "BlizzPart2" "EndScale"	(particleObj.Endscale as string)
			if (particleObj.particletype == 1) do (setINISetting output_file "BlizzPart2" "Head&TailFlag" "1")
			if (particleObj.particletype == 2) do (setINISetting output_file "BlizzPart2" "Head&TailFlag" "2")
			if (particleObj.particletype == 3) do (setINISetting output_file "BlizzPart2" "Head&TailFlag" "3")
			setINISetting output_file "BlizzPart2" "TailLength" (particleObj.taillength as string)
			setINISetting output_file "BlizzPart2" "Head(LifeSpan)Start"	(particleObj.startLifespanHead as string)
			setINISetting output_file "BlizzPart2" "Head(LifeSpan)End"	(particleObj.endLifespanHead as string)
			setINISetting output_file "BlizzPart2" "Head(LifeSpan)Repeat"	(particleObj.repeatLifespanHead as string)
			setINISetting output_file "BlizzPart2" "Head(Decay)Start"		(particleObj.startDecayHead as string)
			setINISetting output_file "BlizzPart2" "Head(Decay)End"		(particleObj.endDecayHead as string)
			setINISetting output_file "BlizzPart2" "Head(Decay)Repeat"	(particleObj.repeatDecayHead as string)
			setINISetting output_file "BlizzPart2" "Tail(LifeSpan)Start"	(particleObj.startLifespanTail as string)
			setINISetting output_file "BlizzPart2" "Tail(LifeSpan)End"	(particleObj.endLifespanTail as string)
			setINISetting output_file "BlizzPart2" "Tail(LifeSpan)Repeat"	(particleObj.repeatLifespanTail as string)
			setINISetting output_file "BlizzPart2" "Tail(Decay)Start"		(particleObj.startDecayTail as string)
			setINISetting output_file "BlizzPart2" "Tail(Decay)End"		(particleObj.endDecayTail as string)
			setINISetting output_file "BlizzPart2" "Tail(Decay)Repeat"	(particleObj.repeatDecayTail as string)
		)
    )
	-------------------------------------------------------------------------------------
	rollout General "General Functions"
	(
		PickButton btn_adsorption "Select Object (Adsorb)" pos:[12,7] width:138 height:24
		edittext Temp_adsorption "" pos:[9999,0] width:0 height:0
		on btn_adsorption picked obj do
		(
			try
			(
				selection[1].pos = obj.pos
				selection[1].parent = obj
				Temp_adsorption.text = obj.name
				btn_adsorption.text = "Parent: " + Temp_adsorption.text
			)catch()
		)
		on General open do
		(
			if ::L != undefined then
				General.title = ::L.t "bp2_general_functions_title"
		)
	)
	rollout paramsE "Loading Particle Configuration" rolledUp:true
	(
		button btnImport "Import" height:24 width:64 pos:[12,7]
		button btnExport "Export" height:24 width:64 pos:[86,7]
		label Label1 "Load Dynamic Values ............" height:16 width:126 pos:[12,40] align:#left tooltip:"This option affects whether to use dynamic property values when importing/exporting particles"
		checkbox CB_IsAnim height:16 pos:[137,40] tooltip:"This option affects whether to use dynamic property values when importing/exporting particles"
		On btnImport pressed do ImportParticle()
		On btnExport pressed do ExportParticle()
		on paramsE open do
		(
			if ::L != undefined then
			(
				paramsE.title = ::L.t "bp2_loading_particle_configuration_title"
				btnImport.text = ::L.t "bp2_import_btn"
				btnExport.text = ::L.t "bp2_export_btn"
				Label1.text = ::L.t "bp2_load_dynamic_values_lbl"
			)
		)
	)

	rollout params1 "Particle Texture Map Parameters"
	(
		label l3 "- Texture Path Prefix -" pos:[35,7] align:#center
		edittext path pos:[8,25] height:20 width:142
		label l4 "- Particle Texture File -" pos:[35,50] align:#center
		edittext texture pos:[8,68] height:20 width:142
		button btn1 "Import Particle Texture" pos:[12,96] height:24 width:138
		button btnBrowseMPQ "Browse MPQ / CASC" pos:[12,124] height:24 width:138 tooltip:"Browse textures from MPQ/CASC archives"
		label l5 "- Texture Blend Mode -" pos:[35,155] align:#center
		dropdownlist filtermode "" items:#("Blend", "Additive", "Modulate", "Modulate2x", "AlphaKey") width:138 pos:[12,173]
		label l6 "Unshaded ....................." height:16 pos:[12,204] align:#left width:124
		checkbox unshaded height:16 pos:[137,204]
		label l7 "Unfogged ....................." height:16 pos:[12,228] align:#left width:124
		checkbox unfogged height:16 pos:[137,228]
		label l8 "Sort Z-Axis Geometry ......." height:16 pos:[12,252] align:#left width:124
		checkbox SortZ height:16 pos:[137,252]
		label l9 "- Replaceable Texture -" pos:[41,274] align:#center
		dropdownList rtexture "" items:#("Not Used", "Team Color", "Team Glow") selection:1 width:138 pos:[12,292]
		group "Sequence"
		(
			spinner rows "Rows:" height:16 range:[1,100,1] type:#integer scale:1 align:#left fieldwidth:25 offset:[-1,0] tooltip:"Rows must be power of 2"
			spinner cols "Cols:" height:16 range:[1,100,1] type:#integer scale:1 align:#right fieldwidth:25 offset:[1,-21] tooltip:"Columns must be power of 2"
		)
		on btn1 pressed do
		(
			texture.enabled = false
			local f = getOpenFileName caption:(::L.t "bp2_select_texture_file_cap") types:"All Files (*.*)|*.*|TGA File (*.tga)|*.tga|" historyCategory:"ParticleBTexture"
			if f != undefined then texture.text = f
			texture.enabled = true
		)
		on btnBrowseMPQ pressed do
		(
			try
			(
				::NeoDexTexBrowserTarget = #(this, "particle_texture")
				::NeoDexTexBrowserInitCategory = 4
				::NeoDexTexBrowser.show()
			)
			catch (messageBox "Texture Browser not available.")
		)
		on params1 open do
		(
			-- Enable/disable browse button
			local browserAvailable = false
			try
			(
				if ::NeoDexMPQ != undefined and ::NeoDexMPQ.getDirectory() != "" and ::NeoDexMPQ.validateDirectory() then
					browserAvailable = true
				if not browserAvailable then
				(
					local cascIni = getDir #plugcfg + "\\NeoDex_Settings.ini"
					local cascDir = getINISetting cascIni "CASC" "W3Path"
					if cascDir != "" and doesFileExist (cascDir + "\\.build.info") then
						browserAvailable = true
				)
			) catch()
			btnBrowseMPQ.enabled = browserAvailable
			
			if ::L != undefined then
			(
				params1.title = ::L.t "bp2_particle_texture_map_parameters_title"
				l3.text = ::L.t "bp2__texture_path_prefix_lbl"
				l4.text = ::L.t "bp2__particle_texture_file_lbl"
				btn1.text = ::L.t "bp2_import_particle_texture_btn"
				l5.text = ::L.t "bp2__texture_blend_mode_lbl"
				l6.text = ::L.t "bp2_unshaded_lbl"
				l7.text = ::L.t "bp2_unfogged_lbl"
				l8.text = ::L.t "bp2_sort_zaxis_geometry_lbl"
				l9.text = ::L.t "bp2__replaceable_texture_lbl"
				rows.tooltip = ::L.t "bp2_rows_must_be_power_of_2_tip"
				cols.tooltip = ::L.t "bp2_columns_must_be_power_of_2_tip"
			)
		)

	)

	rollout params2 "Particle Emission Range"
	(
				
		label l15 "Width .............." pos:[12,8] align:#left width:85
		spinner LZwidth pos:[94,7] height:16 range:[0,99999,0] fieldwidth:44 tooltip:"Particles will randomly appear within this range"
		label lizi_Kuandu "Control:" pos:[12,31] align:#left
		checkbutton btn_width_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Step Controller"    pos:[58,28] width:20 height:20
		checkbutton btn_width_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller"  pos:[82,28] width:20 height:20
		checkbutton btn_width_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller"  pos:[106,28] width:20 height:20
		checkbutton btn_width_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,28] width:20 height:20
		
		label l16 "Length .............." pos:[12,54] align:#left width:85
		spinner LZlength pos:[94,53] height:16 range:[0,99999,0] fieldwidth:44 tooltip:"Particles will randomly appear within this range"
		label lizi_Changdu "Control:" pos:[12,77] align:#left
		checkbutton btn_length_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   tooltip:"Step Controller"   pos:[58,74] width:20 height:20
		checkbutton btn_length_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller" pos:[82,74] width:20 height:20
		checkbutton btn_length_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller" pos:[106,74] width:20 height:20
		checkbutton btn_length_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller"    pos:[130,74] width:20 height:20
		
		label l1 "- Emitter Type -" pos:[41,101]
		dropdownlist lineEmitter "" items:#("Default Emitter", "Linear Emitter") width:138 pos:[12,119]
		
		-- Button group arrays (initialized in on open)
		local widthBtns, lengthBtns
		
		fn syncBtnGroup btnArr ctrl =
		(
			for b in btnArr do b.checked = false
			if ctrl != undefined do
			(
				if classof ctrl == Bezier_Float then
				(	if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #step then btnArr[1].checked = true
					else btnArr[3].checked = true
				)
				else if classof ctrl == Linear_Float then btnArr[2].checked = true
				else if classof ctrl == TCB_Float then btnArr[4].checked = true
			)
		)
		fn UpdateWidth_Buttons  = (try(syncBtnGroup widthBtns  (if selection.count > 0 and selection[1].width.isAnimated  then selection[1].width.controller  else undefined))catch())
		fn UpdateLength_Buttons = (try(syncBtnGroup lengthBtns (if selection.count > 0 and selection[1].length.isAnimated then selection[1].length.controller else undefined))catch())

		On btn_width_step changed state do
		(
			try
			(
				if selection[1].width.isAnimated != false then
				(
					if classof selection[1].width.controller != Bezier_float do
						selection[1].width.controller = Bezier_float()
					for i = 1 to selection[1].width.controller.keys.count do
					(
						selection[1].width.controller.keys[i].inTangentType = #step
						selection[1].width.controller.keys[i].outTangentType = #step
					)
					UpdateWidth_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_width_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_width_linear changed state do
		(
			try
			(
				if selection[1].width.isAnimated != false then
				(
					selection[1].width.controller = Linear_float ()
					UpdateWidth_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_width_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_width_bezier changed state do
		(
			try
			(
				if selection[1].width.isAnimated != false then
				(
					if classof selection[1].width.controller != Bezier_float do
						selection[1].width.controller = Bezier_float()
					for i = 1 to selection[1].width.controller.keys.count do
					(
						selection[1].width.controller.keys[i].inTangentType = #flat
						selection[1].width.controller.keys[i].outTangentType = #flat
					)
					UpdateWidth_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_width_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_width_Hermite changed state do
		(
			try
			(
				if selection[1].width.isAnimated != false then
				(
					selection[1].width.controller = TCB_float ()
					UpdateWidth_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_width_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		-- Length Buttons ----------------------------------------------------
		On btn_length_step changed state do
		(
			try
			(
				if selection[1].length.isAnimated != false then
				(
					if classof selection[1].length.controller != Bezier_float do
						selection[1].length.controller = Bezier_float()
					for i = 1 to selection[1].length.controller.keys.count do
					(
						selection[1].length.controller.keys[i].inTangentType = #step
						selection[1].length.controller.keys[i].outTangentType = #step
					)
					UpdateLength_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_length_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_length_linear changed state do
		(
			try
			(
				if selection[1].length.isAnimated != false then
				(
					selection[1].length.controller = Linear_float ()
					UpdateLength_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_length_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_length_bezier changed state do
		(
			try
			(
				if selection[1].length.isAnimated != false then
				(
					if classof selection[1].length.controller != Bezier_float do
						selection[1].length.controller = Bezier_float()
					for i = 1 to selection[1].length.controller.keys.count do
					(
						selection[1].length.controller.keys[i].inTangentType = #flat
						selection[1].length.controller.keys[i].outTangentType = #flat
					)
					UpdateLength_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_length_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_length_Hermite changed state do
		(
			try
			(
				if selection[1].length.isAnimated != false then
				(
					selection[1].length.controller = TCB_float ()
					UpdateLength_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_length_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)
		
		on LZwidth changed val do
		(
			UpdateWidth_Buttons()
		)
		
		on LZlength changed val do
		(
			UpdateLength_Buttons()
		)
		
		on params2 open do
		(
			widthBtns  = #(btn_width_step, btn_width_linear, btn_width_bezier, btn_width_Hermite)
			lengthBtns = #(btn_length_step, btn_length_linear, btn_length_bezier, btn_length_Hermite)
			UpdateWidth_Buttons()
			UpdateLength_Buttons()
			if ::L != undefined then
			(
				params2.title = ::L.t "bp2_particle_emission_range_title"
				l15.text = ::L.t "bp2_width_lbl"
				lizi_Kuandu.text = ::L.t "bp2_control_lbl"
				l16.text = ::L.t "bp2_length_lbl"
				lizi_Changdu.text = ::L.t "bp2_control_lbl_2"
				l1.text = ::L.t "bp2__emitter_type_lbl"
			)
		)
		
	)

	-------------------------------------------------------------------------------------------------------------------
	rollout params3 "Particle Emission Rate"
	(
		
		
		label lbllife "Lifespan:" pos:[12,8] align:#left width:85
		spinner life height:16 range:[0,99999,0] fieldwidth:44 pos:[94,8]
		
		label lblPartEmit "Emission Rate:" pos:[12,29] align:#left width:85
		spinner PartEmit height:16 range:[0,99999,50] fieldwidth:44 pos:[94,29] tooltip:"Particles emitted per second\nNote: Particles will appear sequentially, not simultaneously"
		label lizi_Fangshe "Control:" pos:[12,53] align:#left
		checkbutton btn_partemit_step   images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,50]  tooltip:"Step Controller" width:20 height:20
		checkbutton btn_partemit_linear images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,50] tooltip:"Linear Controller" width:20 height:20
		checkbutton btn_partemit_bezier images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,50] tooltip:"Bezier Controller" width:20 height:20
		checkbutton btn_partemit_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,50] tooltip:"Hermite Controller" width:20 height:20
		
		label l2 "Squirt Particles .................." height:16 pos:[12,75] align:#left width:124
		checkbox squirt "" height:16 pos:[137,75] tooltip:"Particles will appear all at once instead of sequentially!\nNote: Only works if there's a keyframe on the first frame of the animation!"
		
		local emitBtns
		fn syncBtnGroup btnArr ctrl =
		(
			for b in btnArr do b.checked = false
			if ctrl != undefined do
			(
				if classof ctrl == Bezier_Float then
				(	if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #step then btnArr[1].checked = true
					else btnArr[3].checked = true
				)
				else if classof ctrl == Linear_Float then btnArr[2].checked = true
				else if classof ctrl == TCB_Float then btnArr[4].checked = true
			)
		)
		fn UpdatePartEmit_Buttons = (try(syncBtnGroup emitBtns (if selection.count > 0 and selection[1].PartsEmit.isAnimated then selection[1].PartsEmit.controller else undefined))catch())

		On btn_partemit_step changed state do
		(
			try
			(
				if selection[1].PartsEmit.isAnimated != false then
				(
					if classof selection[1].PartsEmit.controller != Bezier_float do
						selection[1].PartsEmit.controller = Bezier_float()
					for i = 1 to selection[1].PartsEmit.controller.keys.count do
					(
						selection[1].PartsEmit.controller.keys[i].inTangentType = #step
						selection[1].PartsEmit.controller.keys[i].outTangentType = #step
					)
					UpdatePartEmit_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_partemit_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_partemit_linear changed state do
		(
			try
			(
				if selection[1].PartsEmit.isAnimated != false then
				(
					selection[1].PartsEmit.controller = Linear_float ()
					UpdatePartEmit_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_partemit_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_partemit_bezier changed state do
		(
			try
			(
				if selection[1].PartsEmit.isAnimated != false then
				(
					if classof selection[1].PartsEmit.controller != Bezier_float do
						selection[1].PartsEmit.controller = Bezier_float()
					for i = 1 to selection[1].PartsEmit.controller.keys.count do
					(
						selection[1].PartsEmit.controller.keys[i].inTangentType = #flat
						selection[1].PartsEmit.controller.keys[i].outTangentType = #flat
					)
					UpdatePartEmit_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_partemit_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_partemit_Hermite changed state do
		(
			try
			(
				if selection[1].PartsEmit.isAnimated != false then
				(
					selection[1].PartsEmit.controller = TCB_float ()
					UpdatePartEmit_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_partemit_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)
		
		on PartEmit changed val do
		(
			UpdatePartEmit_Buttons()
		)

		on params3 open do
		(
			emitBtns = #(btn_partemit_step, btn_partemit_linear, btn_partemit_bezier, btn_partemit_Hermite)
			UpdatePartEmit_Buttons()
			if ::L != undefined then
			(
				params3.title = ::L.t "bp2_particle_emission_rate_title"
				lbllife.text = ::L.t "bp2_lifespan_lbl"
				lblPartEmit.text = ::L.t "bp2_emission_rate_lbl"
				lizi_Fangshe.text = ::L.t "bp2_control_lbl_3"
				l2.text = ::L.t "bp2_squirt_particles_lbl"
			)
		)

	)
		-------------------------------------------------------------------------------------------------------

	rollout params4 "Particle Emission Velocity"
	(
				
		label l17 "Speed .............." pos:[12,8] align:#left width:85
		spinner speed height:16 range:[-99999,99999,10] pos:[94,7] fieldwidth:44 tooltip:"Particle emission distance.\nHigher values = farther distance"
		label lizi_Sudu "Control:" pos:[12,31] align:#left
		checkbutton btn_speed_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   tooltip:"Step Controller"    pos:[58,28] width:20 height:20
		checkbutton btn_speed_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller"  pos:[82,28] width:20 height:20
		checkbutton btn_speed_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller"  pos:[106,28] width:20 height:20
		checkbutton btn_speed_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,28] width:20 height:20
		
		label lblvariation "Variation........." height:16 pos:[12,54] align:#left width:85
		spinner variation height:16 pos:[94,53] range:[-100,100,0] fieldwidth:44 tooltip:"Parameter: 0.1 = 10%\nFormula: Speed+(Variation×Speed) or Speed-(Variation×Speed)\nNote: When variation > 1, speed can become negative causing reverse emission" offset:[40,-21]
		label lizi_Biansu "Control:" pos:[12,77] align:#left
		checkbutton btn_variation_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   tooltip:"Step Controller"    pos:[58,74] width:20 height:20
		checkbutton btn_variation_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller"  pos:[82,74] width:20 height:20
		checkbutton btn_variation_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller"  pos:[106,74] width:20 height:20
		checkbutton btn_variation_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,74] width:20 height:20
		
		label l18 "Latitude .............." pos:[12,100] align:#left width:85
		spinner coneangle "" height:16 range:[-180,180,0] pos:[94,99] fieldwidth:44 tooltip:"Parameter: 180 = 360°\nMeaning: Particles will randomly emit in 360° directions"
		label lizi_Weidu "Control:" pos:[12,123] align:#left
		checkbutton btn_coneangle_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   tooltip:"Step Controller"    pos:[58,120] width:20 height:20
		checkbutton btn_coneangle_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller"  pos:[82,120] width:20 height:20
		checkbutton btn_coneangle_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller"  pos:[106,120] width:20 height:20
		checkbutton btn_coneangle_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,120] width:20 height:20
		
		label l19 "Gravity .............." pos:[12,146] align:#left width:85
		spinner gravity "" height:16 range:[-99999,99999,0] pos:[94,145] fieldwidth:44 tooltip:"Can be negative (negative = upward gravity).\nGravity ignores rotation angles\nGravity only affects vertical movement" type:#float scale:0.1
		label lizi_Zhongli "Control:" pos:[12,169] align:#left
		checkbutton btn_gravity_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   tooltip:"Step Controller"    pos:[58,166] width:20 height:20
		checkbutton btn_gravity_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller"  pos:[82,166] width:20 height:20
		checkbutton btn_gravity_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller"  pos:[106,166] width:20 height:20
		checkbutton btn_gravity_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,166] width:20 height:20

		-- Button group arrays (initialized in on open)
		local speedBtns, varBtns, coneBtns, gravBtns
		
		fn syncBtnGroup btnArr ctrl =
		(
			for b in btnArr do b.checked = false
			if ctrl != undefined do
			(
				if classof ctrl == Bezier_Float then
				(	if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #step then btnArr[1].checked = true
					else btnArr[3].checked = true
				)
				else if classof ctrl == Linear_Float then btnArr[2].checked = true
				else if classof ctrl == TCB_Float then btnArr[4].checked = true
			)
		)
		fn UpdateSpeed_Buttons     = (try(syncBtnGroup speedBtns (if selection.count > 0 and selection[1].speed.isAnimated     then selection[1].speed.controller     else undefined))catch())
		fn UpdateVariation_Buttons = (try(syncBtnGroup varBtns   (if selection.count > 0 and selection[1].variation.isAnimated  then selection[1].variation.controller  else undefined))catch())
		fn UpdateConeangle_Buttons = (try(syncBtnGroup coneBtns  (if selection.count > 0 and selection[1].coneangle.isAnimated  then selection[1].coneangle.controller  else undefined))catch())
		fn UpdateGravity_Buttons   = (try(syncBtnGroup gravBtns  (if selection.count > 0 and selection[1].gravity.isAnimated    then selection[1].gravity.controller    else undefined))catch())


		-- Speed Buttons -----------------------------------------------------
		On btn_speed_step changed state do
		(
			try
			(
				if selection[1].speed.isAnimated != false then
				(
					if classof selection[1].speed.controller != Bezier_float do
						selection[1].speed.controller = Bezier_float()
					for i = 1 to selection[1].speed.controller.keys.count do
					(
						selection[1].speed.controller.keys[i].inTangentType = #step
						selection[1].speed.controller.keys[i].outTangentType = #step
					)
					UpdateSpeed_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_speed_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_speed_linear changed state do
		(
			try
			(
				if selection[1].speed.isAnimated != false then
				(
					selection[1].speed.controller = Linear_float ()
					UpdateSpeed_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_speed_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_speed_bezier changed state do
		(
			try
			(
				if selection[1].speed.isAnimated != false then
				(
					if classof selection[1].speed.controller != Bezier_float do
						selection[1].speed.controller = Bezier_float()
					for i = 1 to selection[1].speed.controller.keys.count do
					(
						selection[1].speed.controller.keys[i].inTangentType = #flat
						selection[1].speed.controller.keys[i].outTangentType = #flat
					)
					UpdateSpeed_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_speed_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_speed_Hermite changed state do
		(
			try
			(
				if selection[1].speed.isAnimated != false then
				(
					selection[1].speed.controller = TCB_float ()
					UpdateSpeed_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_speed_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		-- Variation Buttons -------------------------------------------------
		On btn_variation_step changed state do
		(
			try
			(
				if selection[1].variation.isAnimated != false then
				(
					if classof selection[1].variation.controller != Bezier_float do
						selection[1].variation.controller = Bezier_float()
					for i = 1 to selection[1].variation.controller.keys.count do
					(
						selection[1].variation.controller.keys[i].inTangentType = #step
						selection[1].variation.controller.keys[i].outTangentType = #step
					)
					UpdateVariation_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_variation_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_variation_linear changed state do
		(
			try
			(
				if selection[1].variation.isAnimated != false then
				(
					selection[1].variation.controller = Linear_float ()
					UpdateVariation_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_variation_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_variation_bezier changed state do
		(
			try
			(
				if selection[1].variation.isAnimated != false then
				(
					if classof selection[1].variation.controller != Bezier_float do
						selection[1].variation.controller = Bezier_float()
					for i = 1 to selection[1].variation.controller.keys.count do
					(
						selection[1].variation.controller.keys[i].inTangentType = #flat
						selection[1].variation.controller.keys[i].outTangentType = #flat
					)
					UpdateVariation_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_variation_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_variation_Hermite changed state do
		(
			try
			(
				if selection[1].variation.isAnimated != false then
				(
					selection[1].variation.controller = TCB_float ()
					UpdateVariation_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_variation_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		-- Coneangle Buttons -------------------------------------------------
		On btn_coneangle_step changed state do
		(
			try
			(
				if selection[1].coneangle.isAnimated != false then
				(
					if classof selection[1].coneangle.controller != Bezier_float do
						selection[1].coneangle.controller = Bezier_float()
					for i = 1 to selection[1].coneangle.controller.keys.count do
					(
						selection[1].coneangle.controller.keys[i].inTangentType = #step
						selection[1].coneangle.controller.keys[i].outTangentType = #step
					)
					UpdateConeangle_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_coneangle_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_coneangle_linear changed state do
		(
			try
			(
				if selection[1].coneangle.isAnimated != false then
				(
					selection[1].coneangle.controller = Linear_float ()
					UpdateConeangle_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_coneangle_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_coneangle_bezier changed state do
		(
			try
			(
				if selection[1].coneangle.isAnimated != false then
				(
					if classof selection[1].coneangle.controller != Bezier_float do
						selection[1].coneangle.controller = Bezier_float()
					for i = 1 to selection[1].coneangle.controller.keys.count do
					(
						selection[1].coneangle.controller.keys[i].inTangentType = #flat
						selection[1].coneangle.controller.keys[i].outTangentType = #flat
					)
					UpdateConeangle_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_coneangle_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_coneangle_Hermite changed state do
		(
			try
			(
				if selection[1].coneangle.isAnimated != false then
				(
					selection[1].coneangle.controller = TCB_float ()
					UpdateConeangle_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_coneangle_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		-- Gravity Buttons ---------------------------------------------------
		On btn_gravity_step changed state do
		(
			try
			(
				if selection[1].gravity.isAnimated != false then
				(
					if classof selection[1].gravity.controller != Bezier_float do
						selection[1].gravity.controller = Bezier_float()
					for i = 1 to selection[1].gravity.controller.keys.count do
					(
						selection[1].gravity.controller.keys[i].inTangentType = #step
						selection[1].gravity.controller.keys[i].outTangentType = #step
					)
					UpdateGravity_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_gravity_step.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_gravity_linear changed state do
		(
			try
			(
				if selection[1].gravity.isAnimated != false then
				(
					selection[1].gravity.controller = Linear_float ()
					UpdateGravity_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_gravity_linear.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_gravity_bezier changed state do
		(
			try
			(
				if selection[1].gravity.isAnimated != false then
				(
					if classof selection[1].gravity.controller != Bezier_float do
						selection[1].gravity.controller = Bezier_float()
					for i = 1 to selection[1].gravity.controller.keys.count do
					(
						selection[1].gravity.controller.keys[i].inTangentType = #flat
						selection[1].gravity.controller.keys[i].outTangentType = #flat
					)
					UpdateGravity_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_gravity_bezier.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)

		On btn_gravity_Hermite changed state do
		(
			try
			(
				if selection[1].gravity.isAnimated != false then
				(
					selection[1].gravity.controller = TCB_float ()
					UpdateGravity_Buttons()
					messagebox (MessageboxText2 + "    ") title:MessageboxTitle
				)else
				(
					btn_gravity_Hermite.checked = false
					messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				)
			)catch()
		)
		
		on speed changed val do
		(
			UpdateSpeed_Buttons()
		)
		
		on variation changed val do
		(
			UpdateVariation_Buttons()
		)
		
		on coneangle changed val do
		(
			UpdateConeangle_Buttons()
		)
		
		on gravity changed val do
		(
			UpdateGravity_Buttons()
		)

		on speed changed val do
		(
			UpdateSpeed_Buttons()
		)
		
		on params4 open do
		(
			speedBtns = #(btn_speed_step, btn_speed_linear, btn_speed_bezier, btn_speed_Hermite)
			varBtns   = #(btn_variation_step, btn_variation_linear, btn_variation_bezier, btn_variation_Hermite)
			coneBtns  = #(btn_coneangle_step, btn_coneangle_linear, btn_coneangle_bezier, btn_coneangle_Hermite)
			gravBtns  = #(btn_gravity_step, btn_gravity_linear, btn_gravity_bezier, btn_gravity_Hermite)
			UpdateSpeed_Buttons()
			UpdateVariation_Buttons()
			UpdateConeangle_Buttons()
			UpdateGravity_Buttons()
			if ::L != undefined then
			(
				params4.title = ::L.t "bp2_particle_emission_velocity_title"
				l17.text = ::L.t "bp2_speed_lbl"
				lizi_Sudu.text = ::L.t "bp2_control_lbl_4"
				lblvariation.text = ::L.t "bp2_variation_lbl"
				lizi_Biansu.text = ::L.t "bp2_control_lbl_5"
				l18.text = ::L.t "bp2_latitude_lbl"
				lizi_Weidu.text = ::L.t "bp2_control_lbl_6"
				l19.text = ::L.t "bp2_gravity_lbl"
				lizi_Zhongli.text = ::L.t "bp2_control_lbl_7"
			)
		)
	)



	---------------------------------------------------------------------------------------------

	rollout params5 "Particle Tag"
	(
		label l9 "Priority Plane ........" height:16 align:#left width:85 pos:[12,8]
		spinner Priority height:16 fieldwidth:44 type:#integer range:[-20,20,0] pos:[94,8]
		label l10 "Model Space .................." height:16 align:#left width:124 pos:[12,29]
		checkbox PartSpace height:16 tooltip:"Note: Requires parent bone to work!\nMeaning: Particles will follow bone movement instead of staying in place" pos:[137,29]
		label l11 "XY Quads ..............." height:16 align:#left width:124 pos:[12,50]
		checkbox XYQuads height:16 tooltip:"Note: Requires latitude value to work!\nMeaning: Particles will face emission direction instead of always facing one direction" pos:[137,50]
		on params5 open do
		(
			if ::L != undefined then
			(
				params5.title = ::L.t "bp2_particle_tag_title"
				l9.text = ::L.t "bp2_priority_plane_lbl"
				l10.text = ::L.t "bp2_model_space_lbl"
				l11.text = ::L.t "bp2_xy_quads_lbl"
			)
		)
	)
	--------------------------------------------------粒子的开始至结束三个部分的效果--------------------------------------------------
	rollout params6 "Particle Lifetime"
	(
		-- Nur diese Variable behalten:
		local isUpdating = false
		
		label       l12             "—— - Start Color - ——"    align:#center
		colorPicker Scolor                                     height:32 width:89   pos:[8,25   ]    enabled:false color:(color 255 255 255)
		colorPicker YS_Scolor                                  height:1  width:1    pos:[8,25   ]    visible:false color:(color 255 255 255)
		button      btn_Scolor      "..."                      height:32 width:32   pos:[118,25 ]    tooltip:"Change Color"
		button      btn_Scolor_Up   "↑"                        height:16 width:16   pos:[102,25 ]    tooltip:"Swap with End Color"
		button      btn_Scolor_Down "↓"                        height:16 width:16   pos:[102,41 ]    tooltip:"Swap with Middle Color"
		label       l20             "Start Alpha : "           width:85             pos:[12,62  ]    align:#left
		spinner     Salpha                                     height:16 scale:1    pos:[94,62  ]    type:#integer range:[0,255,255]         fieldwidth:44
		label       l21             "Start Scale : "           width:85             pos:[12,83  ]    align:#left
		spinner     Sscale                                     height:16 scale:0.1  pos:[94,83  ]    enabled:true  range:[0,1e+012,10]       fieldwidth:44
		label       l13             "—— - Middle Color - ——"   align:#center
		colorPicker Mcolor                                     height:32 width:89   pos:[8,122  ]    enabled:false color:(color 128 128 128)
		colorPicker YS_Mcolor                                  height:1  width:1    pos:[8,122  ]    visible:false color:(color 128 128 128)
		button      btn_Mcolor      "..."                      height:32 width:32   pos:[118,122]    tooltip:"Change Color"
		button      btn_Mcolor_Up   "↑"                        height:16 width:16   pos:[102,122]    tooltip:"Swap with Start Color"
		button      btn_Mcolor_Down "↓"                        height:16 width:16   pos:[102,138]    tooltip:"Swap with End Color"
		label       l22             "Middle Alpha : "          width:85             pos:[12,159 ]    align:#left
		spinner     Malpha                                     height:16 scale:1    pos:[94,159 ]    type:#integer range:[0,255,128]         fieldwidth:44
		label       l23             "Middle Scale : "          width:85             pos:[12,180 ]    align:#left
		spinner     Mscale                                     height:16 scale:0.1  pos:[94,180 ]    enabled:true  range:[0,1e+012,10]       fieldwidth:44
		label       l24             "Middle Time : "           width:85             pos:[12,201 ]    align:#left
		spinner     MiddleTime                                 height:16 scale:0.01 pos:[94,201 ]    enabled:true  range:[0.01,1e+012,0.5]   fieldwidth:44        
		label       l14             "—— - End Color - ——"      align:#center
		colorPicker Ecolor                                     height:32 width:89   pos:[8,240  ]    enabled:false color:(color 0 0 0)
		colorPicker YS_Ecolor                                  height:1  width:1    pos:[8,240  ]    visible:false color:(color 0 0 0)
		button      btn_Ecolor      "..."                      height:32 width:32   pos:[118,240]    tooltip:"Change Color"
		button      btn_Ecolor_Up   "↑"                        height:16 width:16   pos:[102,240]    tooltip:"Swap with Middle Color"
		button      btn_Ecolor_Down "↓"                        height:16 width:16   pos:[102,256]    tooltip:"Swap with Start Color"
		label       l25             "End Alpha : "             width:85             pos:[12,277 ]    align:#left
		spinner     Ealpha                                     height:16 scale:1    pos:[94,277 ]    type:#integer range:[0,255,0]           fieldwidth:44
		label       l26             "End Scale : "             width:85             pos:[12,298 ]    align:#left
		spinner     Escale                                     height:16 scale:0.1  pos:[94,298 ]    enabled:true  range:[0,1e+012,10]       fieldwidth:44
		group                       "3-Color Adjustment"
		(
			label   l27             "Hue .............."        width:85             pos:[12,338]     align:#left
			spinner SeXiang                                     height:16 scale:1    pos:[94,338]     type:#integer range:[-180,180,0]        fieldwidth:44
			slider  sld_SeXiang                                 ticks:0   width:154  pos:[10,359]     type:#integer range:[-180,180,0]
			label   l28             "Saturation ..........."    width:85             pos:[12,382]     align:#left
			spinner BaoHeDu                                     height:16 scale:1    pos:[94,382]     type:#integer range:[-100,100,0]        fieldwidth:44
			slider  sld_BaoHeDu                                 ticks:0   width:154  pos:[10,403]     type:#integer range:[-100,100,0]
			label   l29             "Brightness .............." width:85             pos:[12,426]     align:#left
			spinner MingDu                                      height:16 scale:1    pos:[94,426]     type:#integer range:[-100,100,0]        fieldwidth:44
			slider  sld_MingDu                                  ticks:0   width:154  pos:[10,447]     type:#integer range:[-100,100,0]
			button  btn_Retest      "Collapse Color Data"       height:24 width:138  pos:[12,472]
		)
		
		-- Apply current HSB adjustment sliders to all three color channels (Start/Middle/End)
		fn updateAllColors =
		(
			Scolor.color = adjustColor_PS YS_Scolor.color sld_SeXiang.value sld_BaoHeDu.value sld_MingDu.value
			Mcolor.color = adjustColor_PS YS_Mcolor.color sld_SeXiang.value sld_BaoHeDu.value sld_MingDu.value
			Ecolor.color = adjustColor_PS YS_Ecolor.color sld_SeXiang.value sld_BaoHeDu.value sld_MingDu.value
		)
		
		-- Event Handlers
		on sld_SeXiang changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				SeXiang.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		on sld_BaoHeDu changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				BaoHeDu.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		on sld_MingDu changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				MingDu.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		on SeXiang changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				sld_SeXiang.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		on BaoHeDu changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				sld_BaoHeDu.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		on MingDu changed val do
		(
			if isUpdating == false do 
			(
				isUpdating = true
				sld_MingDu.value = val
				updateAllColors()
				isUpdating = false
			)
		)
		
		-- Color Picker Button Handlers - Mit Standard Max Color Picker
		on btn_Scolor pressed do
		(
			-- Verwende die aktuelle sichtbare Farbe, nicht die Original-Farbe
			local newColor = colorPickerDlg Scolor.color "Choose Start Color" alpha:false
			if newColor != undefined do
			(
				-- Setze die neue Farbe als neue Basis
				YS_Scolor.color = newColor
				Scolor.color = newColor
				
				-- Resette die Slider, weil wir eine neue Basis-Farbe haben
				isUpdating = true
				SeXiang.value = 0
				BaoHeDu.value = 0
				MingDu.value = 0
				sld_SeXiang.value = 0
				sld_BaoHeDu.value = 0
				sld_MingDu.value = 0
				isUpdating = false
			)
		)

		on btn_Mcolor pressed do
		(
			-- Verwende die aktuelle sichtbare Farbe, nicht die Original-Farbe
			local newColor = colorPickerDlg Mcolor.color "Choose Middle Color" alpha:false
			if newColor != undefined do
			(
				-- Setze die neue Farbe als neue Basis
				YS_Mcolor.color = newColor
				Mcolor.color = newColor
				
				-- Resette die Slider, weil wir eine neue Basis-Farbe haben
				isUpdating = true
				SeXiang.value = 0
				BaoHeDu.value = 0
				MingDu.value = 0
				sld_SeXiang.value = 0
				sld_BaoHeDu.value = 0
				sld_MingDu.value = 0
				isUpdating = false
			)
		)

		on btn_Ecolor pressed do
		(
			-- Verwende die aktuelle sichtbare Farbe, nicht die Original-Farbe
			local newColor = colorPickerDlg Ecolor.color "Choose End Color" alpha:false
			if newColor != undefined do
			(
				-- Setze die neue Farbe als neue Basis
				YS_Ecolor.color = newColor
				Ecolor.color = newColor
				
				-- Resette die Slider, weil wir eine neue Basis-Farbe haben
				isUpdating = true
				SeXiang.value = 0
				BaoHeDu.value = 0
				MingDu.value = 0
				sld_SeXiang.value = 0
				sld_BaoHeDu.value = 0
				sld_MingDu.value = 0
				isUpdating = false
			)
		)
		
		on btn_Retest pressed do
		(
			isUpdating = true
			SeXiang.value = 0
			BaoHeDu.value = 0
			MingDu.value = 0
			sld_SeXiang.value = 0
			sld_BaoHeDu.value = 0
			sld_MingDu.value = 0
			YS_Scolor.color = Scolor.color
			YS_Mcolor.color = Mcolor.color
			YS_Ecolor.color = Ecolor.color
			isUpdating = false
		)
		
		on btn_Scolor_Up pressed do
		(
			ColorTemp        = YS_Scolor.color
			YS_Scolor.color  = YS_Ecolor.color
			YS_Ecolor.color  = ColorTemp
			updateAllColors()
		)
		
		on btn_Scolor_Down pressed do
		(
			ColorTemp        = YS_Scolor.color
			YS_Scolor.color  = YS_Mcolor.color
			YS_Mcolor.color  = ColorTemp
			updateAllColors()
		)
		
		on btn_Mcolor_Up pressed do
		(
			ColorTemp        = YS_Mcolor.color
			YS_Mcolor.color  = YS_Scolor.color
			YS_Scolor.color  = ColorTemp
			updateAllColors()
		)
		
		on btn_Mcolor_Down pressed do
		(
			ColorTemp        = YS_Mcolor.color
			YS_Mcolor.color  = YS_Ecolor.color
			YS_Ecolor.color  = ColorTemp
			updateAllColors()
		)
		
		on btn_Ecolor_Up pressed do
		(
			ColorTemp        = YS_Ecolor.color
			YS_Ecolor.color  = YS_Mcolor.color
			YS_Mcolor.color  = ColorTemp
			updateAllColors()
		)
		
		on btn_Ecolor_Down pressed do
		(
			ColorTemp        = YS_Ecolor.color
			YS_Ecolor.color  = YS_Scolor.color
			YS_Scolor.color  = ColorTemp
			updateAllColors()
		)
		
		on params6 open do
		(
			sld_SeXiang.ticks = 0
			sld_BaoHeDu.ticks = 0
			sld_MingDu.ticks  = 0
			if ::L != undefined then
			(
				params6.title = ::L.t "bp2_particle_lifetime_title"
				l12.text = ::L.t "bp2__start_color_lbl"
				l20.text = ::L.t "bp2_start_alpha_lbl"
				l21.text = ::L.t "bp2_start_scale_lbl"
				l13.text = ::L.t "bp2__middle_color_lbl"
				l22.text = ::L.t "bp2_middle_alpha_lbl"
				l23.text = ::L.t "bp2_middle_scale_lbl"
				l24.text = ::L.t "bp2_middle_time_lbl"
				l14.text = ::L.t "bp2__end_color_lbl"
				l25.text = ::L.t "bp2_end_alpha_lbl"
				l26.text = ::L.t "bp2_end_scale_lbl"
				l27.text = ::L.t "bp2_hue_lbl"
				l28.text = ::L.t "bp2_saturation_lbl"
				l29.text = ::L.t "bp2_brightness_lbl"
				btn_Retest.text = ::L.t "bp2_collapse_color_data_btn"
			)
		)
	)
	-------------------------------------------------------粒子头部与尾部的参数------------------------------------------------------
	rollout params9 "Head and Tail Markers"
	(
		dropdownlist PartType width:138 pos:[12,7] items:#("Head Only", "Tail Only", "Head and Tail")
		label l13 "Tail Length ........" width:85 align:#left pos:[12,34]
		spinner tailLength scale:0.05 height:16 pos:[94,34] tooltip:"Equivalent to ribbon effect length" range:[-99999,99999,1] fieldwidth:44
		button btn2 "Head & Tail Explanation" width:138 height:24 pos:[12,57]
		on btn2 pressed do
		(
			messagebox (MessageboxText + "    ")
		)
		on params9 open do
		(
			if ::L != undefined then
			(
				params9.title = ::L.t "bp2_head_and_tail_markers_title"
				l13.text = ::L.t "bp2_tail_length_lbl"
				btn2.text = ::L.t "bp2_head_tail_explanation_btn"
			)
		)
	)

	rollout params10 "Head & Tail Parameters"
	(
		group "Head (First Half)"
		(
			label tb1 "Sequence Start :" pos:[12,26] align:#left width:87
			spinner Slheaduw pos:[96,26] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label tb2 "Sequence End :" pos:[12,49] align:#left width:87
			spinner Elheaduw pos:[96,49] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label tb3 "Repeat Count :" pos:[12,70] align:#left width:87
			spinner Rlheaduw pos:[96,70] range:[1,5,1] fieldwidth:42 type:#integer
		)
		group "Head (Second Half)"
		(
			label tb4 "Sequence Start :" pos:[12,117] align:#left width:87
			spinner Sdheaduw pos:[96,117] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label tb5 "Sequence End :" pos:[12,138] align:#left width:87
			spinner Edheaduw pos:[96,138] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label tb6 "Repeat Count :" pos:[12,159] align:#left width:87
			spinner Rdheaduw pos:[96,159] range:[1,5,1] fieldwidth:42 type:#integer
		)
		group "Tail (First Half)"
		(
			label wb1 "Sequence Start :" pos:[12,208] align:#left width:87
			spinner Sltailuw pos:[96,208] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label wb2 "Sequence End :" pos:[12,229] align:#left width:87
			spinner Eltailuw pos:[96,229] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label wb3 "Repeat Count :" pos:[12,250] align:#left width:87
			spinner Rltailuw pos:[96,250] range:[1,5,1] fieldwidth:42 type:#integer
		)
		group "Tail (Second Half)"
		(
			label wb4 "Sequence Start :" pos:[12,299] align:#left width:87
			spinner Sdtailuw pos:[96,299] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label wb5 "Sequence End :" pos:[12,320] align:#left width:87
			spinner Edtailuw pos:[96,320] range:[0,128,0] fieldwidth:42 type:#integer tooltip:"0 = top-left first sequence\nIncreases left to right, top to bottom\nPlayback doesn't allow reverse order (e.g., start 9 end 0)"
			label wb6 "Repeat Count :" pos:[12,341] align:#left width:87
			spinner Rdtailuw pos:[96,341] range:[1,5,1] fieldwidth:42 type:#integer
		)
		on params10 open do
		(
			if ::L != undefined then
			(
				params10.title = ::L.t "bp2_head_tail_parameters_title"
				tb1.text = ::L.t "bp2_sequence_start_lbl"
				tb2.text = ::L.t "bp2_sequence_end_lbl"
				tb3.text = ::L.t "bp2_repeat_count_lbl"
				tb4.text = ::L.t "bp2_sequence_start_lbl_2"
				tb5.text = ::L.t "bp2_sequence_end_lbl_2"
				tb6.text = ::L.t "bp2_repeat_count_lbl_2"
				wb1.text = ::L.t "bp2_sequence_start_lbl_3"
				wb2.text = ::L.t "bp2_sequence_end_lbl_3"
				wb3.text = ::L.t "bp2_repeat_count_lbl_3"
				wb4.text = ::L.t "bp2_sequence_start_lbl_4"
				wb5.text = ::L.t "bp2_sequence_end_lbl_4"
				wb6.text = ::L.t "bp2_repeat_count_lbl_4"
			)
		)
	)

	---------------------------------创建粒子外形物体对象---------------------------------
	tool create
	(
		on mousePoint click do
		(
			case click of
			(
				1: nodeTM.translation = gridPoint
				2: #stop
				3: #stop
			)
		)
		on mouseMove click do
		(
			case click of
			(
				2: (length = abs (gridDist.y); width = abs (gridDist.x))
			)
		)
	)

	fn BuildGizmo points Drawcolor =
	(
		local unselectedColor = Drawcolor				--默认的颜色
		local selectedColor   = Drawcolor				--点燃的颜色
		local giz			  = manip.makeGizmoShape()	--生成形状
		giz.startNewLine() 
		for pnt in points do giz.addpoint pnt
		this.addGizmoShape giz 0 unselectedColor selectedColor
	)

	on updateGizmos do
	(
		this.clearGizmos()
		local Drawcolor = [179,153,255]
		Drawcolor = [Drawcolor.x/255,Drawcolor.y/255,Drawcolor.z/255]
		-- Emitter-Größe
		BuildGizmo #([-width/2,-length/2,0], [-width/2,length/2,0], [width/2,length/2,0], [width/2,-length/2,0],[-width/2,-length/2,0]) Drawcolor
		-- 3D-Pfeil
		BuildGizmo #([-2,-2,0],[2,-2,0],[2,2,0],[-2,2,0],[-2,-2,0],[-2,-2,8],[2,-2,8],[2,2,8],[-2,2,8],[-2,-2,8]) Drawcolor
		BuildGizmo #([-2,2,0],[-2,2,8]) Drawcolor
		BuildGizmo #([2,-2,0],[2,-2,8]) Drawcolor
		BuildGizmo #([2,2,0],[2,2,8]) Drawcolor
		BuildGizmo #([-4,-4,8],[-4,4,8],[4,4,8],[4,-4,8],[-4,-4,8],[0,0,12],[4,4,8]) Drawcolor
		BuildGizmo #([-4,4,8],[0,0,12],[4,-4,8]) Drawcolor
		
		-- Speed begrenzen für die Visualisierung
		local displaySpeed = speed
		if displaySpeed > 200 then displaySpeed = 200
		if displaySpeed < -200 then displaySpeed = -200
		
		-- Kegel mit sanfter Begrenzung
		local displayConeAngle = coneAngle
		
		-- Kombinierte Begrenzung: Wenn beide Werte hoch sind, stärker begrenzen
		if (abs(displaySpeed) > 100 and displayConeAngle > 120) then
		(
			-- Proportionale Reduktion basierend auf beiden Werten
			local speedFactor = (abs(displaySpeed) - 100) / 100.0  -- 0 bis 1
			local angleFactor = (displayConeAngle - 120) / 60.0     -- 0 bis 1
			local combinedFactor = speedFactor * angleFactor         -- 0 bis 1
			
			-- Je höher der kombinierte Faktor, desto stärker die Begrenzung
			displaySpeed = displaySpeed * (1.0 - combinedFactor * 0.5)  -- Maximal 50% Reduktion
			displayConeAngle = displayConeAngle - (combinedFactor * 20)  -- Maximal 20 Grad Reduktion
		)
		
		-- Zusätzliche Einzelbegrenzung für extreme Winkel
		if displayConeAngle > 175 then 
			displayConeAngle = 175
		
		local half = displayConeAngle / 2.0
		
		-- Schutz vor Division durch sehr kleine Werte
		if cos(half) < 0.01 then
		(
			-- Bei sehr flachen Winkeln feste Größe verwenden
			local B = displaySpeed * 10.0
			-- Zusätzliche Obergrenze für B
			if B > 400 then B = 400  -- Absolute Maximalgröße
			
			local p1 = [-B,B,displaySpeed]
			local p2 = [-B,-B,displaySpeed]
			local p3 = [B,-B,displaySpeed]
			local p4 = [B,B,displaySpeed]
			
			BuildGizmo #(p1, p2, p3, p4, P1) Drawcolor
			BuildGizmo #([0,0,0],p1) Drawcolor
			BuildGizmo #([0,0,0],p2) Drawcolor
			BuildGizmo #([0,0,0],p3) Drawcolor
			BuildGizmo #([0,0,0],p4) Drawcolor
		)
		else
		(
			-- Normale Berechnung für kleinere Winkel
			local A = displaySpeed / cos half
			local B = sqrt ( A*A - displaySpeed*displaySpeed )
			
			-- Sanfte Obergrenze bei sehr großen Werten
			local maxSize = displaySpeed * 10.0
			if maxSize > 400 then maxSize = 400  -- Absolute Maximalgröße
			if B > maxSize then B = maxSize
			
			local p1 = [-B,B,displaySpeed]
			local p2 = [-B,-B,displaySpeed]
			local p3 = [B,-B,displaySpeed]
			local p4 = [B,B,displaySpeed]
			
			BuildGizmo #(p1, p2, p3, p4, P1) Drawcolor
			BuildGizmo #([0,0,0],p1) Drawcolor
			BuildGizmo #([0,0,0],p2) Drawcolor
			BuildGizmo #([0,0,0],p3) Drawcolor
			BuildGizmo #([0,0,0],p4) Drawcolor
		)
	)
)