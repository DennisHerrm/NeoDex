macroScript NeoDex_Manager
buttonText:"Neodex Manager"
category:"NeoDex Toolkit"
internalCategory:"NeoDex Toolkit"
(
	-- Includes
-- include "NeoDexModules\\Wc3Model.ms"
-- include "NeoDexModules\\UtilityFunctions.ms"
	-- end Includes
	
-- include "SequenceManager.ms"
-- include "NodeManager.ms"
-- include "AnimTools.ms"
-- include "GridAndDummyCreator.ms"
-- include "FBXAnimationSaver.ms"
-- include "SkinChanger.ms"
-- include "VisibilityKeyer.ms"
-- include "TeamColorManager.ms"

	
	fn getIniSettingWithClass filename sectionString keyString valueClass defaultValue =
	(
		-- get the ini setting as usual
		local settingString = getINISetting filename sectionString keyString
		-- if no value is found for whatever reason the defaultvalue is returned
		if settingString == "" then return defaultValue
		-- if the class is a string then just return the string if it is not empty
		if valueClass == String then return settingString
		-- try to get the executed value of the ini string and if execution fails return defaultValue
		try local val = safeExecute settingString ignoreSSSEState:true
		catch return defaultValue
		-- only if the class of the value matches the given valueClass then return the value from the ini file
		if classOf val == valueClass then return val else return defaultValue
	)
	
	-- Ini Settings File
	global neoDexManagerINIFilename = getDir #plugcfg + "\\" + "NeodexManager.ini"
	---------------------------------------------------------------------------------------
	-- Macro
	---------------------------------------------------------------------------------------
	global neodexManagerFloater
	
	-- Define a rollout for saving position, size and rolled up states
	-- since roloutfloater need a rollout for this
	rollout neodexManagerFloaterRollout "Neodex Manager Floater Rollout"
	(
		local floater
		
		on neodexManagerFloaterRollout open do
		(
			floater = neodexManagerFloaterRollout.rolloutFloater
			
			print "Neodex Manager Opened."
		)
		
		on neodexManagerFloaterRollout oktoclose do
		(
			-- safe the position, size and rolled up states of the rollouts to ini file
			setINISetting neoDexManagerINIFilename "Rollout Floater" "Pos" (floater.pos as string)
			setINISetting neoDexManagerINIFilename "Rollout Floater" "Size" (floater.size as string)
			
			for rl in floater.rollouts do
			(
				setINISetting neoDexManagerINIFilename rl.title "RolledUp" ((not rl.open) as string)
			)
			
			true -- return true to let the rollout be closed!!!
		)
		
		on neodexManagerFloaterRollout close do
		(
			print "Neodex Manager Closed."
		)
	)
	
	on execute do
	(
		local neodexManagerRollouts = #(
			::SequenceManager.mainRollout,
			::VisibilityKeyer.mainRollout,
			::AnimTools.generalRoll,
			::AnimTools.controllersRoll,
			::SkinChanger.mainRollout,
			::GridAndDummyCreator.mainRollout,
			::ObjectManipulationTools.mainRollout,
			::AnimTools.skinRoll,
			::AnimTools.scalerRoll,
			::NodeManager.mainRollout,
			::TeamColorManager.mainRollout,
			::ObjectSettings.mainRollout
		)
	
		if neodexManagerFloater == undefined or not neodexManagerFloater.open then
		(
			-- Initial Values
			local pos = getIniSettingWithClass neoDexManagerINIFilename "Rollout Floater" "Pos" Point2 [0, 0]
			local size = getIniSettingWithClass neoDexManagerINIFilename "Rollout Floater" "Size" Point2 [456, 800]
			
			-- Localized floater title
			local floaterTitle = "NeoDex Manager"
			if ::L != undefined then floaterTitle = ::L.t "mgr_neodex_manager_macbtn"
			
			neodexManagerFloater = newrolloutfloater floaterTitle 456 size.y pos.x pos.y
			
			-- Suppress redraws while adding rollouts
			try (neodexManagerFloater.lock = true) catch()
			
			-- add rollouts from array
			for rl in neodexManagerRollouts do
			(
				-- only add the rollout if it is not already displayed in another dialog or floater
				if rl.isDisplayed then continue
				
				-- get the rolled up state from ini files
				local rolledUpState = getIniSettingWithClass neoDexManagerINIFilename rl.title "RolledUp" BooleanClass false
				addrollout rl neodexManagerFloater rolledUp:rolledUpState
			)
			
			-- add the hidden rollout for saving ini settings
			addrollout neodexManagerFloaterRollout neodexManagerFloater rolledUp:true border:false
			
			-- Resume redraws
			try (neodexManagerFloater.lock = false) catch()
			
		)
		else
		(
			if classof neodexManagerFloater == RolloutFloater \
				and neodexManagerFloater.open then
			(
				if (windows.getWindowPlacement neodexManagerFloater)[1] == #showMinimized then
				(
					windows.showWindow neodexManagerFloater #Restore
				)
			)
		)
	)
)
