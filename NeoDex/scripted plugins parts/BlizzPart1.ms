plugin simpleManipulator BlizzParticle1
name:"BlizzPart1"
classID:#(0x750735E3, 0x21F2D857)
category:"Warcraft 3 Systems"
( 
	local Icon_Path = ((systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\neodex_icons\\")
	local MessageboxText2 = "Conversion Complete!"
	local MessageboxText3 = "Current property has no animation data!"
	local parentBtnLabel = "Parent Object: "
	local TempSelction = "None"
	
	parameters main rollout:params1
	(
		radius    type:#float	ui:spn_radius	 default:0		animatable:true
		longitude type:#float ui:spn_longitude default:180.0	animatable:true
		latitude  type:#float ui:spn_latitude  default:180.0	animatable:true
		path	  type:#string	ui:path							animatable:false	default:"war3mapImported\\"
		Part	  type:#string	ui:Part							animatable:false
		PartEmit  type:#float	ui:PartEmit	 	 default:50		animatable:true
		Life	  type:#float	ui:Life			 default:1		animatable:true
		Gravity	  type:#float	ui:Gravity		 default:0		animatable:true
	)
	rollout General "General Functions"
	(
		PickButton btn_select_parent "Select Object (Attach to)" pos:[12,7] width:138 height:24
		
		on btn_select_parent picked obj do
		(
			try
			(
				selection[1].pos = obj.pos
				selection[1].parent = obj
				btn_select_parent.text = parentBtnLabel + obj.name
			)catch()
		)
		on General open do
		(
			if ::L != undefined then
				General.title = ::L.t "bp1_general_functions_title"
		)
	)
	rollout params1 "Basic Parameters"
	(
		Label l1 "- Particle Prefix Path -" align:#center
		edittext Path pos:[8,25] height:20 width:142
		
		Label l2 "- Particle File -" align:#center
		edittext Part pos:[8,68] height:20 width:142
		
		button btn_import_particle "Import Particle Model" pos:[12,96] height:24 width:138
		
		group "Particle Properties"
		(
			label l5 "Emission Rate:" pos:[12,144] align:#left width:70
			spinner PartEmit pos:[79,143] height:16 range:[0,99999,50] fieldwidth:59
			
			label l6 "Control:" pos:[12,167] align:#left
			checkbutton btn_emission_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,164]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_emission_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,164]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_emission_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,164] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_emission_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,164] tooltip:"Hermite Controller" width:20 height:20
			
			label l7 "Life Span:" pos:[12,198] align:#left width:70
			spinner Life pos:[79,197] height:16 range:[0,99999,1] fieldwidth:59
			
			label l8 "Control:" pos:[12,221] align:#left
			checkbutton btn_life_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,218]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_life_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,218]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_life_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,218] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_life_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,218] tooltip:"Hermite Controller" width:20 height:20
		)
		
		group "Emission Range"
		(
			label l9 "Longitude:" pos:[12,269] align:#left width:70
			spinner spn_longitude pos:[79,268] height:16 range:[0,180,180] fieldwidth:59
			
			label l10 "Control:" pos:[12,292] align:#left
			checkbutton btn_longitude_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,289]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_longitude_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,289]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_longitude_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,289] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_longitude_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,289] tooltip:"Hermite Controller" width:20 height:20
			
			label l11 "Latitude:" pos:[12,323] align:#left width:70
			spinner spn_latitude pos:[79,322] height:16 range:[0,180,180] fieldwidth:59
			
			label l12 "Control:" pos:[12,346] align:#left
			checkbutton btn_latitude_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,343]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_latitude_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,343]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_latitude_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,343] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_latitude_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,343] tooltip:"Hermite Controller" width:20 height:20
			
			label l13 "Speed:" pos:[12,377] align:#left width:70
			spinner spn_radius pos:[79,376] height:16 range:[-99999,99999,10] fieldwidth:59
			
			label l14 "Control:" pos:[12,400] align:#left
			checkbutton btn_speed_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,397]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_speed_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,397]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_speed_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,397] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_speed_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,397] tooltip:"Hermite Controller" width:20 height:20
			
			label l15 "Gravity:" pos:[12,431] align:#left width:70
			spinner Gravity pos:[79,430] height:16 range:[-99999,99999,0] fieldwidth:59
			
			label l16 "Control:" pos:[12,454] align:#left
			checkbutton btn_gravity_step    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True)   pos:[58,451]  tooltip:"Step Controller" width:20 height:20
			checkbutton btn_gravity_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) pos:[82,451]  tooltip:"Linear Controller" width:20 height:20
			checkbutton btn_gravity_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) pos:[106,451] tooltip:"Bezier Controller" width:20 height:20
			checkbutton btn_gravity_Hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) pos:[130,451] tooltip:"Hermite Controller" width:20 height:20
		)
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- Button group arrays: #(stepBtn, linearBtn, bezierBtn, hermiteBtn)
		-- Initialized in on params1 open
		local emBtns, lifeBtns, longBtns, latBtns, speedBtns, gravBtns
		
		-- ==================== Generic Helper Functions ====================
		
		-- Syncs a group of 4 controller checkbuttons to reflect the current controller type.
		-- btnArr: #(stepBtn, linearBtn, bezierBtn, hermiteBtn)
		-- ctrl: the current animation controller (or undefined if not animated)
		fn syncBtnGroup btnArr ctrl =
		(
			for b in btnArr do b.checked = false
			if ctrl != undefined do
			(
				if classof ctrl == Bezier_Float then
				(
					if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #step then
						btnArr[1].checked = true
					else
						btnArr[3].checked = true
				)
				else if classof ctrl == Linear_Float then
					btnArr[2].checked = true
				else if classof ctrl == TCB_Float then
					btnArr[4].checked = true
			)
		)
		
		-- Applies step tangents (#step) to all keys of a Bezier_float controller.
		fn applyStepTangents ctrl =
		(
			for i = 1 to ctrl.keys.count do
			(
				ctrl.keys[i].inTangentType = #step
				ctrl.keys[i].outTangentType = #step
			)
		)
		
		-- Applies smooth tangents (#flat) to all keys of a Bezier_float controller.
		fn applyBezierTangents ctrl =
		(
			for i = 1 to ctrl.keys.count do
			(
				ctrl.keys[i].inTangentType = #flat
				ctrl.keys[i].outTangentType = #flat
			)
		)

		-- ==================== Refresh Functions ====================
		-- Each reads the current controller state and updates button highlights accordingly.
		fn refreshEmission  = (try(syncBtnGroup emBtns    (if selection.count > 0 and selection[1].PartEmit.isAnimated  then selection[1].PartEmit.controller  else undefined))catch())
		fn refreshLife      = (try(syncBtnGroup lifeBtns  (if selection.count > 0 and selection[1].Life.isAnimated      then selection[1].Life.controller      else undefined))catch())
		fn refreshLongitude = (try(syncBtnGroup longBtns  (if selection.count > 0 and selection[1].longitude.isAnimated then selection[1].longitude.controller else undefined))catch())
		fn refreshLatitude  = (try(syncBtnGroup latBtns   (if selection.count > 0 and selection[1].latitude.isAnimated  then selection[1].latitude.controller  else undefined))catch())
		fn refreshSpeed     = (try(syncBtnGroup speedBtns (if selection.count > 0 and selection[1].radius.isAnimated    then selection[1].radius.controller    else undefined))catch())
		fn refreshGravity   = (try(syncBtnGroup gravBtns  (if selection.count > 0 and selection[1].Gravity.isAnimated   then selection[1].Gravity.controller   else undefined))catch())

		-- ==================== Controller Change Handlers ====================
		-- Emission Rate --
		on btn_emission_step changed state do
		(	try (
				if selection[1].PartEmit.isAnimated then
				(	if classof selection[1].PartEmit.controller != Bezier_float do selection[1].PartEmit.controller = Bezier_float()
					applyStepTangents selection[1].PartEmit.controller
					refreshEmission(); messagebox MessageboxText2
				) else (refreshEmission(); messagebox MessageboxText3)
			) catch()
		)
		on btn_emission_linear changed state do
		(	try (
				if selection[1].PartEmit.isAnimated then
				(	selection[1].PartEmit.controller = Linear_float()
					refreshEmission(); messagebox MessageboxText2
				) else (refreshEmission(); messagebox MessageboxText3)
			) catch()
		)
		on btn_emission_bezier changed state do
		(	try (
				if selection[1].PartEmit.isAnimated then
				(	if classof selection[1].PartEmit.controller != Bezier_float do selection[1].PartEmit.controller = Bezier_float()
					applyBezierTangents selection[1].PartEmit.controller
					refreshEmission(); messagebox MessageboxText2
				) else (refreshEmission(); messagebox MessageboxText3)
			) catch()
		)
		on btn_emission_Hermite changed state do
		(	try (
				if selection[1].PartEmit.isAnimated then
				(	selection[1].PartEmit.controller = TCB_float()
					refreshEmission(); messagebox MessageboxText2
				) else (refreshEmission(); messagebox MessageboxText3)
			) catch()
		)
		-- Life Span --
		on btn_life_step changed state do
		(	try (
				if selection[1].Life.isAnimated then
				(	if classof selection[1].Life.controller != Bezier_float do selection[1].Life.controller = Bezier_float()
					applyStepTangents selection[1].Life.controller
					refreshLife(); messagebox MessageboxText2
				) else (refreshLife(); messagebox MessageboxText3)
			) catch()
		)
		on btn_life_linear changed state do
		(	try (
				if selection[1].Life.isAnimated then
				(	selection[1].Life.controller = Linear_float()
					refreshLife(); messagebox MessageboxText2
				) else (refreshLife(); messagebox MessageboxText3)
			) catch()
		)
		on btn_life_bezier changed state do
		(	try (
				if selection[1].Life.isAnimated then
				(	if classof selection[1].Life.controller != Bezier_float do selection[1].Life.controller = Bezier_float()
					applyBezierTangents selection[1].Life.controller
					refreshLife(); messagebox MessageboxText2
				) else (refreshLife(); messagebox MessageboxText3)
			) catch()
		)
		on btn_life_Hermite changed state do
		(	try (
				if selection[1].Life.isAnimated then
				(	selection[1].Life.controller = TCB_float()
					refreshLife(); messagebox MessageboxText2
				) else (refreshLife(); messagebox MessageboxText3)
			) catch()
		)
		-- Longitude --
		on btn_longitude_step changed state do
		(	try (
				if selection[1].longitude.isAnimated then
				(	if classof selection[1].longitude.controller != Bezier_float do selection[1].longitude.controller = Bezier_float()
					applyStepTangents selection[1].longitude.controller
					refreshLongitude(); messagebox MessageboxText2
				) else (refreshLongitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_longitude_linear changed state do
		(	try (
				if selection[1].longitude.isAnimated then
				(	selection[1].longitude.controller = Linear_float()
					refreshLongitude(); messagebox MessageboxText2
				) else (refreshLongitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_longitude_bezier changed state do
		(	try (
				if selection[1].longitude.isAnimated then
				(	if classof selection[1].longitude.controller != Bezier_float do selection[1].longitude.controller = Bezier_float()
					applyBezierTangents selection[1].longitude.controller
					refreshLongitude(); messagebox MessageboxText2
				) else (refreshLongitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_longitude_Hermite changed state do
		(	try (
				if selection[1].longitude.isAnimated then
				(	selection[1].longitude.controller = TCB_float()
					refreshLongitude(); messagebox MessageboxText2
				) else (refreshLongitude(); messagebox MessageboxText3)
			) catch()
		)
		-- Latitude --
		on btn_latitude_step changed state do
		(	try (
				if selection[1].latitude.isAnimated then
				(	if classof selection[1].latitude.controller != Bezier_float do selection[1].latitude.controller = Bezier_float()
					applyStepTangents selection[1].latitude.controller
					refreshLatitude(); messagebox MessageboxText2
				) else (refreshLatitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_latitude_linear changed state do
		(	try (
				if selection[1].latitude.isAnimated then
				(	selection[1].latitude.controller = Linear_float()
					refreshLatitude(); messagebox MessageboxText2
				) else (refreshLatitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_latitude_bezier changed state do
		(	try (
				if selection[1].latitude.isAnimated then
				(	if classof selection[1].latitude.controller != Bezier_float do selection[1].latitude.controller = Bezier_float()
					applyBezierTangents selection[1].latitude.controller
					refreshLatitude(); messagebox MessageboxText2
				) else (refreshLatitude(); messagebox MessageboxText3)
			) catch()
		)
		on btn_latitude_Hermite changed state do
		(	try (
				if selection[1].latitude.isAnimated then
				(	selection[1].latitude.controller = TCB_float()
					refreshLatitude(); messagebox MessageboxText2
				) else (refreshLatitude(); messagebox MessageboxText3)
			) catch()
		)
		-- Speed --
		on btn_speed_step changed state do
		(	try (
				if selection[1].radius.isAnimated then
				(	if classof selection[1].radius.controller != Bezier_float do selection[1].radius.controller = Bezier_float()
					applyStepTangents selection[1].radius.controller
					refreshSpeed(); messagebox MessageboxText2
				) else (refreshSpeed(); messagebox MessageboxText3)
			) catch()
		)
		on btn_speed_linear changed state do
		(	try (
				if selection[1].radius.isAnimated then
				(	selection[1].radius.controller = Linear_float()
					refreshSpeed(); messagebox MessageboxText2
				) else (refreshSpeed(); messagebox MessageboxText3)
			) catch()
		)
		on btn_speed_bezier changed state do
		(	try (
				if selection[1].radius.isAnimated then
				(	if classof selection[1].radius.controller != Bezier_float do selection[1].radius.controller = Bezier_float()
					applyBezierTangents selection[1].radius.controller
					refreshSpeed(); messagebox MessageboxText2
				) else (refreshSpeed(); messagebox MessageboxText3)
			) catch()
		)
		on btn_speed_Hermite changed state do
		(	try (
				if selection[1].radius.isAnimated then
				(	selection[1].radius.controller = TCB_float()
					refreshSpeed(); messagebox MessageboxText2
				) else (refreshSpeed(); messagebox MessageboxText3)
			) catch()
		)
		-- Gravity --
		on btn_gravity_step changed state do
		(	try (
				if selection[1].Gravity.isAnimated then
				(	if classof selection[1].Gravity.controller != Bezier_float do selection[1].Gravity.controller = Bezier_float()
					applyStepTangents selection[1].Gravity.controller
					refreshGravity(); messagebox MessageboxText2
				) else (refreshGravity(); messagebox MessageboxText3)
			) catch()
		)
		on btn_gravity_linear changed state do
		(	try (
				if selection[1].Gravity.isAnimated then
				(	selection[1].Gravity.controller = Linear_float()
					refreshGravity(); messagebox MessageboxText2
				) else (refreshGravity(); messagebox MessageboxText3)
			) catch()
		)
		on btn_gravity_bezier changed state do
		(	try (
				if selection[1].Gravity.isAnimated then
				(	if classof selection[1].Gravity.controller != Bezier_float do selection[1].Gravity.controller = Bezier_float()
					applyBezierTangents selection[1].Gravity.controller
					refreshGravity(); messagebox MessageboxText2
				) else (refreshGravity(); messagebox MessageboxText3)
			) catch()
		)
		on btn_gravity_Hermite changed state do
		(	try (
				if selection[1].Gravity.isAnimated then
				(	selection[1].Gravity.controller = TCB_float()
					refreshGravity(); messagebox MessageboxText2
				) else (refreshGravity(); messagebox MessageboxText3)
			) catch()
		)

		-- ==================== Spinner Change Events ====================
		on PartEmit changed val     do refreshEmission()
		on Life changed val          do refreshLife()
		on spn_longitude changed val do refreshLongitude()
		on spn_latitude changed val  do refreshLatitude()
		on spn_radius changed val    do refreshSpeed()
		on Gravity changed val       do refreshGravity()

		-- ==================== Rollout Open ====================
		on params1 open do
		(
			-- Initialize button group arrays
			emBtns    = #(btn_emission_step,  btn_emission_linear,  btn_emission_bezier,  btn_emission_Hermite)
			lifeBtns  = #(btn_life_step,      btn_life_linear,      btn_life_bezier,      btn_life_Hermite)
			longBtns  = #(btn_longitude_step, btn_longitude_linear, btn_longitude_bezier, btn_longitude_Hermite)
			latBtns   = #(btn_latitude_step,  btn_latitude_linear,  btn_latitude_bezier,  btn_latitude_Hermite)
			speedBtns = #(btn_speed_step,     btn_speed_linear,     btn_speed_bezier,     btn_speed_Hermite)
			gravBtns  = #(btn_gravity_step,   btn_gravity_linear,   btn_gravity_bezier,   btn_gravity_Hermite)

			-- Sync all button states
			refreshEmission()
			refreshLife()
			refreshLongitude()
			refreshLatitude()
			refreshSpeed()
			refreshGravity()

			-- Localization
			if ::L != undefined then
			(
				params1.title = ::L.t "bp1_basic_parameters_title"
				l1.text = ::L.t "bp1__particle_prefix_path_lbl"
				l2.text = ::L.t "bp1__particle_file_lbl"
				btn_import_particle.text = ::L.t "bp1_import_particle_model_btn"
				l5.text = ::L.t "bp1_emission_rate_lbl"
				l6.text = ::L.t "bp1_control_lbl"
				l7.text = ::L.t "bp1_life_span_lbl"
				l8.text = ::L.t "bp1_control_lbl_2"
				l9.text = ::L.t "bp1_longitude_lbl"
				l10.text = ::L.t "bp1_control_lbl_3"
				l11.text = ::L.t "bp1_latitude_lbl"
				l12.text = ::L.t "bp1_control_lbl_4"
				l13.text = ::L.t "bp1_speed_lbl"
				l14.text = ::L.t "bp1_control_lbl_5"
				l15.text = ::L.t "bp1_gravity_lbl"
				l16.text = ::L.t "bp1_control_lbl_6"
			)
		)
	)
	
	-- ==================== Gizmo Creation ====================
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
				2: radius = abs (gridDist.y)
			)
		)
	)

	
	fn BuildGizmo points Drawcolor =
	(
		local unselectedColor = Drawcolor
		local selectedColor   = Drawcolor
		local giz			  = manip.makeGizmoShape()
		giz.startNewLine() 
		for pnt in points do giz.addpoint pnt
		this.addGizmoShape giz 0 unselectedColor selectedColor
	)

	on updateGizmos do
	(
		this.clearGizmos()
		-- Base shapes
		local Drawcolor = [255,171,240]
		Drawcolor = [Drawcolor.x/255,Drawcolor.y/255,Drawcolor.z/255]
		BuildGizmo #([0,-5,0],[-5,0,0],[0,5,0],[5,0,0],[0,-5,0]) Drawcolor
		BuildGizmo #([0,-5,0],[0,0,5],[-5,0,0]) Drawcolor
		BuildGizmo #([5,0,0],[0,0,5],[0,5,0]) Drawcolor
		BuildGizmo #([0,-5,0],[0,0,-5],[-5,0,0]) Drawcolor
		BuildGizmo #([0,5,0],[0,0,-5],[5,0,0]) Drawcolor
		
		-- Clamp speed (radius) for visualization
		local displayRadius = amax -100 (amin 100 radius)
		
		-- Range shapes with clamped radius
		Drawcolor = [146,81,135]
		Drawcolor = [Drawcolor.x/255,Drawcolor.y/255,Drawcolor.z/255]
		local r = displayRadius
		local r7 = 0.707 * r
		local r5 = 0.5 * r
		local V01 = [0,0,r]
		local V02 = [0,-r7,r7]
		local V03 = [-r5,-r5,r7]
		local V04 = [-r7,0,r7]
		local V05 = [-r5,r5,r7]
		local V06 = [0,r7,r7]
		local V07 = [r5,r5,r7]
		local V08 = [r7,0,r7]
		local V09 = [r5,-r5,r7]
		local V10 = [0,-r,0]
		local V11 = [-r7,-r7,0]
		local V12 = [-r,0,0]
		local V13 = [-r7,r7,0]
		local V14 = [0,r,0]
		local V15 = [r7,r7,0]
		local V16 = [r,0,0]
		local V17 = [r7,-r7,0]
		local V18 = [0,-r7,-r7]
		local V19 = [-r5,-r5,-r7]
		local V20 = [-r7,0,-r7]
		local V21 = [-r5,r5,-r7]
		local V22 = [0,r7,-r7]
		local V23 = [r5,r5,-r7]
		local V24 = [r7,0,-r7]
		local V25 = [r5,-r5,-r7]
		local V26 = [0,0,-r]
		
		BuildGizmo #(V02,V03,V04,V05,V06,V07,V08,V09,V02) Drawcolor
		BuildGizmo #(V02,V01,V03) Drawcolor
		BuildGizmo #(V04,V01,V05) Drawcolor
		BuildGizmo #(V06,V01,V07) Drawcolor
		BuildGizmo #(V08,V01,V09) Drawcolor
		BuildGizmo #(V02,V10,V11) Drawcolor
		BuildGizmo #(V03,V11,V12) Drawcolor
		BuildGizmo #(V04,V12,V13) Drawcolor
		BuildGizmo #(V05,V13,V14) Drawcolor
		BuildGizmo #(V06,V14,V15) Drawcolor
		BuildGizmo #(V07,V15,V16) Drawcolor
		BuildGizmo #(V08,V16,V17) Drawcolor
		BuildGizmo #(V09,V17,V10) Drawcolor
		BuildGizmo #(V10,V18,V19) Drawcolor
		BuildGizmo #(V11,V19,V20) Drawcolor
		BuildGizmo #(V12,V20,V21) Drawcolor
		BuildGizmo #(V13,V21,V22) Drawcolor
		BuildGizmo #(V14,V22,V23) Drawcolor
		BuildGizmo #(V15,V23,V24) Drawcolor
		BuildGizmo #(V16,V24,V25) Drawcolor
		BuildGizmo #(V17,V25,V18) Drawcolor
		BuildGizmo #(V18,V26,V19) Drawcolor
		BuildGizmo #(V18,V26,V19) Drawcolor
		BuildGizmo #(V20,V26,V21) Drawcolor
		BuildGizmo #(V22,V26,V23) Drawcolor
		BuildGizmo #(V24,V26,V25) Drawcolor
	)
)
