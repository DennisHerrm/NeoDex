fn InstallNeoDexMenu =
(
	fn isMenuInMainBar main ndMenu =
	(
		local result = false
		local n = main.numItems()
		for i = 1 to n while not result do
		(
			local it = main.getItem i
			if (it.getSubMenu ()) == ndMenu then result = true
		)
		result
	)
	
	fn cleanMenu m =
	(
		local n = m.numItems()
		for i = n to 1 by -1 do m.removeItemByPosition i
	)
    
	local main = menuMan.getMainMenuBar()
	local neoDexMain = menuMan.findMenu "NeoDex"
	local subNeoDex

	if neoDexMain == undefined then
	(
		neoDexMain = menuMan.createMenu "NeoDex"
		subNeoDex = menuMan.createSubMenuItem "NeoDex" neoDexMain
		main.addItem subNeoDex -1
	)
	else
	(
		if not (isMenuInMainBar main neoDexMain) then
		(
			subNeoDex = menuMan.createSubMenuItem "NeoDex" neoDexMain
			main.addItem subNeoDex -1
		)
	)
	
	local num = neoDexMain.numItems()
	if num != 0 then cleanMenu neoDexMain
		
	local importItem = menuMan.createActionItem "NeoDex_Importer" "NeoDex Toolkit"
	local exportItem = menuMan.createActionItem "NeoDex_Exporter" "NeoDex Toolkit"
	local managerItem = menuMan.createActionItem "NeoDex_Manager" "NeoDex Toolkit"
	local settingsItem = menuMan.createActionItem "NeoDex_Settings" "NeoDex Toolkit"
	local aboutItem = menuMan.createActionItem "NeoDex_About" "NeoDex Toolkit"

	-- Extra Tools submenu
	-- menuMan.createMenu registers a NEW menu in the permanent menu database on
	-- every call. The main menu above is guarded with findMenu; this one was not,
	-- so each 3ds Max start left another orphaned copy behind. Reuse and clear it.
	-- Registered under a NeoDex-specific name ("NeoDex Extra Tools") so we cannot
	-- hijack a menu that another plugin registered under the generic "Extra Tools".
	-- The displayed caption stays "Extra Tools" - that comes from createSubMenuItem.
	local extraMenu = menuMan.findMenu "NeoDex Extra Tools"
	if extraMenu == undefined then
		extraMenu = menuMan.createMenu "NeoDex Extra Tools"
	else
		cleanMenu extraMenu

	local kfOptimizerItem = menuMan.createActionItem "NeoDex_KeyframeOptimizer" "NeoDex Toolkit"
	local cellShadeItem = menuMan.createActionItem "NeoDex_CellShadeCreator" "NeoDex Toolkit"
	extraMenu.addItem kfOptimizerItem -1
	extraMenu.addItem cellShadeItem -1
	local extraSubItem = menuMan.createSubMenuItem "Extra Tools" extraMenu

	local sep1 = menuMan.createSeparatorItem()
	local sep2 = menuMan.createSeparatorItem()
	
	try
	(
		neoDexMain.addItem importItem -1
		neoDexMain.addItem exportItem -1
		neoDexMain.addItem sep1 -1
		neoDexMain.addItem managerItem -1
		neoDexMain.addItem extraSubItem -1
		neoDexMain.addItem settingsItem -1
		neoDexMain.addItem sep2 -1
		neoDexMain.addItem aboutItem -1
		
		menuMan.updateMenuBar()
	)
	catch print (getCurrentException())
		
	print "Neodex Menu installed"
)
InstallNeoDexMenu()
