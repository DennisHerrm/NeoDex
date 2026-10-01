/*
	NeoDex Import Functions
	=======================
	Contains all import logic separated from the UI.
	This file is loaded as a pre-start-up script and provides:
	  - ImporterSettings struct
	  - NeoDexExecuteImport function
	
	The UI remains in the macroscript (NeoDex_Toolkit-NeoDex_Importer.mcr)
*/

global NeoDexImportSettings
global NeoDexImportedModel
global NeoDexOrigBindPoses

struct ImporterSettings
(
	importMaterials = true,
	importSkinning = true,
	importAnimations = true,
	importObjects = true,
	importBones = true,
	importHelpers = true,
	importLights = true,
	importAttachments = true,
	importPE1 = true,
	importPE2 = true,
	importRE = true,
	importEO = true,
	importCS = true,
	importCameras = true,
	importTransAnim = true,
	importRotAnim = true,
	importScaleAnim = true,
	importTXAnim = true,
	importUVAnim = true,
	importVisAnim = true,
	importColorAnim = true,
	importParamAnim = true,
	importHelpersAsMaxBones = true,
	importBonesAsMaxBones = true,
	importHelpersAsPointHelpers = true,
	optimizeGeometry = true,
	optimizeBonesHelpers = true,
	searchMPQ = false,
	importFormat = #NeoDex,
	-- Reforged v1200
	importCornEmitters = true,
	importFaceFX = true,
	searchCASC = false
	
)

/*
	NeoDexReadMDX
	Reads an MDX file and stores the result in ::NeoDexImportedModel
	
	Parameters:
		infile_name  - Full path to the .mdx file
		debugMode    - true = standard mode (with try/catch), false = debug mode (no error handling)
	
	Returns:
		true if successful, false if error occurred
*/
fn NeoDexReadMDX infile_name debugMode =
(
    local noError = true
    local ver = peekMDXVersion infile_name
    format "NeoDex: MDX version %\n" ver
    
    local readFunc
    if ver >= 1100 then
        readFunc = ::NeoDexMDXReaderV1200.InputMDX
    else
        readFunc = ::NeoDexMDXReader.InputMDX
    
    if debugMode then
    (
        try ::NeoDexImportedModel = readFunc infile_name
        catch
        (
            messageBox "Import Failed: Error while reading the mdx file\n Please open the listener and report the bug"
            format "*** % ***\n" (getCurrentException()) to:listener
            noError = false
        )
    )
    else
    (
        ::NeoDexImportedModel = readFunc infile_name
    )
    
    noError
)

/*
	NeoDexExecuteImport
	Executes the import process: relinks, optimizes and rebuilds the scene.
	
	Parameters:
		model         - The parsed WC3 model (::NeoDexImportedModel)
		modelpath     - The directory path of the source file
		mode          - true = standard mode (with try/catch), false = debug mode
		progressLabel - UI label control for progress display
		progressBar   - UI progressbar control for progress display
	
	Returns:
		true if successful, false if error occurred
*/
fn NeoDexExecuteImport model modelpath mode progressLabel progressBar =
(
	local timeStart = timestamp()
	local noError = true

	::Progress.initiate progressLabel progressBar
	
	if mode then
	(
		try
		(
			::Progress.downLevel 50 1
			with redraw off (::ModelRelinker.relinkModel model)
			::Progress.updateItem "Cleaning up..."
			gc ()
			::Progress.upLevel ()
			::Progress.updateItem "Optimizing Model..."
			::Optimizer.optimizeImportModel model ::NeoDexImportSettings.optimizeGeometry ::NeoDexImportSettings.optimizeBonesHelpers
			::Progress.downLevel 50 1
			::SceneRebuilder.rebuildSceneModel model modelpath
			::Progress.upLevel ()
			::Progress.finalize ()
		)
		catch
		(
			messageBox "Export Failed: Error while rebuilding scene\n Please open the listener and report the bug"
			format "*** % ***\n" (getCurrentException()) to:listener
			noError = false
		)
	)
	else
	(
		MXSDebugger.showFirstFrameOnly = true
		::Progress.downLevel 50 1
		with redraw off
		(
			::ModelRelinker.relinkModel model
		)
		gc()
		::Progress.upLevel()
		::Progress.updateItem "Optimizing Model..."
		::Optimizer.optimizeImportModel model ::NeoDexImportSettings.optimizeGeometry ::NeoDexImportSettings.optimizeBonesHelpers
		::Progress.downLevel 50 1
		::SceneRebuilder.rebuildSceneModel model modelpath
		::Progress.upLevel()
		::Progress.finalize()
	)
	
	local message = "Total Time: " + (((timestamp () - timeStart) / 1000.0) as string) + "s."
	
	#(noError, message)
)

/*
	NeoDexPostImportActions
	Runs post-import actions like updating sequence manager and viewport settings.
*/
global NeoDexViewportToggled = false

fn NeoDexPostImportActions =
(
	-- Update Sequences in SequenceManager
	try ::SequenceManager.sceneChangeCallback() catch()
	
	-- Viewport settings
	--
	-- "554" (Consistent Colors / Flat Color) ist entfernt - in dem Modus
	-- wertet Nitrous Materialien gar nicht aus.
	--
	-- Verifizierte IDs (ueber actionMan-Enumeration in Max 2027):
	--   0 "550"    Viewport Visual Style Shaded          (Default Shading)
	--   0 "63545"  Viewport Materials Display as Shaded with Maps
	--   0 "40607"  Viewport Visual Style Transparency Toggle
	--
	-- WICHTIG: Die Materialanzeige faellt nach Materialzuweisungen auf
	-- "ohne Maps" zurueck. "63545" muss deshalb ganz zuletzt stehen und
	-- wird nach einem vollstaendigen Redraw ein zweites Mal gesetzt -
	-- sonst greift sie nicht, weil destroyDialog direkt davor den Fokus
	-- verschiebt und die Action auf den aktiven Viewport wirkt.
	fn ndxApplyViewportMaterialMode =
	(
		try ( actionMan.executeAction 0 "550" )   catch ()
		try ( actionMan.executeAction 0 "63545" ) catch ()
	)

	actionMan.executeAction -844228238 "12"  -- Viewport Lighting and Shadows: High Quality
	actionMan.executeAction -844228238 "17"  -- Viewport Lighting and Shadows: Progressive Skylight

	-- "5" (Shadows) und "0" (Ambient Occlusion) sind TOGGLES, keine
	-- Setzer. Beim zweiten Import in derselben Session haetten sie vorher
	-- wieder ausgeschaltet.
	if ::NeoDexViewportToggled != true do
	(
		actionMan.executeAction -844228238 "5"  -- Viewport Shadows Toggle
		actionMan.executeAction -844228238 "0"  -- Ambient Occlusion Toggle
		::NeoDexViewportToggled = true
	)

	ndxApplyViewportMaterialMode()
	try ( forceCompleteRedraw() ) catch ()
	ndxApplyViewportMaterialMode()
	try ( redrawViews() ) catch ()
)
