plugin simpleManipulator BlizRibbon
    name:"BlizRibbon"
    classID:#(0x179527d0, 0x1c217376)
    category:"Warcraft 3 Systems"
(
	-- Set arrow shape width and height
    local heightA = [0,0,0]
    local heightB = [0,0,0]
	-- Set initial values for ribbon height changes affecting shape
	local apos = point3 0 0 0
	local bpos = point3 0 0 0
	local bugfixer = undefined
	local Icon_Path = ((systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\neodex_icons\\")
	local isLoading = false
	local MessageboxText2 = "Conversion Complete!"
	local MessageboxText3 = "Current property has no animation data!"
	
	------------------------------------------Register UI----------------------------------------
	parameters main rollout:General
    (
        adsorption  type:#string	ui:Temp_adsorption  default:"Select Object (Adsorb)"
    )
	parameters main rollout:Ribbon_Window1
	(
		twosides			type:#boolean	animatable:false	ui:twosides					default:true
		unshaded			type:#boolean	animatable:false	ui:unshaded					default:true
		unfogged			type:#boolean	animatable:false	ui:unfogged					default:true
		rmaterial			type:#material	animatable:false	ui:btn1
		rows				type:#integer   animatable:false	ui:spn_rows					default: 1
		columns				type:#integer	animatable:false	ui:spn_columns				default: 1
		slots				type:#integer	animatable:true		ui:spn_slots				default: 0
		filtermode			type:#integer	animatable:false	ui:filtermode				default: 4
		texture				type:#texturemap					ui:Btn_map
		path 				type:#string	animatable:false	ui:Pather					default:"Textures\\"
		PriorityPlane		type:#integer	animatable:false	ui:PriorityPlane			default:0
		on texture set val do
		(
			try
			(
				if val != undefined and (not isLoading) then this.rmaterial.texture = this.texture
				this.rmaterial.path			 = this.path
				this.rmaterial.filtermode	 = this.filtermode
				this.rmaterial.twosides		 = this.twosides
				this.rmaterial.unshaded		 = this.unshaded
				this.rmaterial.unfogged		 = this.unfogged
				this.rmaterial.PriorityPlane = this.PriorityPlane
			)catch()
		)
		on path set val do (try(this.rmaterial.path	= val)catch())
		on filtermode set val do (try(this.rmaterial.filtermode = val)catch())
		on twosides set val do (try(this.rmaterial.twosides = val)catch())
		on unshaded set val do (try(this.rmaterial.unshaded = val)catch())
		on unfogged set val do (try(this.rmaterial.unfogged = val)catch())
		on PriorityPlane set val do (try(this.rmaterial.PriorityPlane = val)catch())
	)
	parameters main rollout:Ribbon_Window2
	( 
		matid				type:#integer	animatable:false
		emission			type:#float		animatable:false	ui:spn_emission				default:10.0
		life				type:#float		animatable:false	ui:spn_life					default:1.0
		gravity				type:#float		animatable:false	ui:spn_gravity				default:0.0
		Above				type:#float		animatable:true		ui:spn_staticHeightAbove	default:20.0
		Below  				type:#float		animatable:true		ui:spn_staticHeightBelow	default:20.0
		vertexcolor			type:#color		animatable:true		ui:cp1						default:white
		alpha				type:#float		animatable:true		ui:spn_alpha				default:1.000
		on Above set val do -- Upper length affects the positive Y-axis length of viewport ribbon object
		(
			if (val < 0) then this.Above = 0
			heightA.y = Above
		)
		on Below set val do -- Lower length affects the negative Y-axis length of viewport ribbon object
		(
			if (val < 0) then this.Below = 0
			heightB.y = Below
		)
	)
	-----------------------------------------------------------------------------------------
    rollout General "General Functions"
    (
        PickButton btn_adsorption "Select Object (Adsorb)" pos:[12,7] width:138 height:24
        edittext Temp_adsorption "" pos:[9999,0] width:0 height:0
        on btn_adsorption picked obj do
        (
            try
            (
                selection[1].pos	 = obj.pos
                selection[1].parent	 = obj
                Temp_adsorption.text = obj.name
                btn_adsorption.text	 = "Parent: " + Temp_adsorption.text
            )catch()
        )
        on General open do
        (
            if ::L != undefined then
                General.title = ::L.t "ribbon_general_functions_title"
        )
    )
	rollout Ribbon_Window1 "Ribbon Material Parameters" width:162 height:300
	(
		materialButton	btn1		height:24	align:#center	pos:[999,-24] width:141
		label			l01		   "——— - Prefix Path - ———"						align:#center
		edittext		Pather		height:20	align:#center	width:141  labelOnTop:true
		label			l02		   "——— - Texture File - ———"						align:#center
		mapbutton		Btn_map		height:20	align:#center	width:141
		label			l03		   "——— - Filter Mode - ———"						align:#center
		dropdownlist	filtermode	items:#("None", "Transparent", "Blend", "Additive", "Additive 2x", "Modulate", "Modulate 2x") width:141

		HyperLink		fg01	"——————————————"			pos:[12,136]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg02	"——————————————"			pos:[12,137]   align:#center	width:138	color:(color 112 112 112)		enabled:false

		label        	l04 "Unshaded ................."		height:16   pos:[12,149]	align:#left		width:124
		checkbox     	unshaded							height:16   pos:[137,149]
		label        	l05 "Unfogged ................."		height:16   pos:[12,173]	align:#left		width:124
		checkbox     	unfogged							height:16   pos:[137,173]
		label        	l06 "Two-sided ................"		height:16   pos:[12,197]	align:#left		width:124
		checkbox     	twosides							height:16   pos:[137,197]
		label        	l07 "Priority Plane ...."				height:16   pos:[12,221]	align:#left		width:124
		spinner  		PriorityPlane						height:16	pos:[94,221]   type:#integer   fieldwidth:44	range:[-20,20,0]

		HyperLink		fg03	"——————————————"			pos:[12,235]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg04	"——————————————"			pos:[12,236]   align:#center	width:138	color:(color 112 112 112)		enabled:false
		group "Sequence Mode"
		(
			spinner spn_rows 	"Rows:" height:16 range:[1,100,1] type:#integer scale:1 align:#left  fieldwidth:25	offset:[-1,0 ]	tooltip:"Number of rows must be a power of 2"
			spinner spn_columns "Cols:" height:16 range:[1,100,1] type:#integer scale:1 align:#right fieldwidth:25	offset:[1,-21]	tooltip:"Number of columns must be a power of 2"
			label			l16	"Sequence Position:"			 pos:[12,299]					 align:#left		width:85
			spinner spn_slots							pos:[94,298]					height:16	 fieldwidth:44	range:[0,127,0]	type:#integer	scale:1
		)
		button	Btn_Instantiate	"Instantiate to Material Editor"	height:24	align:#center	offset:[0,2]	width:154 tooltip:"Instantiate the current ribbon's material to the currently selected material slot in the Material Editor"
		label			hhf1					   height:0					   offset:[999,-4]
		on Btn_Instantiate pressed do
		(
			try
			(
				local i = medit.GetActiveMtlSlot()
				meditMaterials[i] = this.rmaterial
			)catch()
		)
		on Ribbon_Window1 open do
		(
			if ::L != undefined then
			(
				Ribbon_Window1.title = ::L.t "ribbon_ribbon_material_parameters_title"
				l01.text = ::L.t "ribbon__prefix_path_lbl"
				l02.text = ::L.t "ribbon__texture_file_lbl"
				l03.text = ::L.t "ribbon__filter_mode_lbl"
				l04.text = ::L.t "ribbon_unshaded_lbl"
				l05.text = ::L.t "ribbon_unfogged_lbl"
				l06.text = ::L.t "ribbon_twosided_lbl"
				l07.text = ::L.t "ribbon_priority_plane_lbl"
				l16.text = ::L.t "ribbon_sequence_position_lbl"
				spn_rows.tooltip = ::L.t "ribbon_number_of_rows_must_be_a_power_tip"
				spn_columns.tooltip = ::L.t "ribbon_number_of_columns_must_be_a_po_tip"
				Btn_Instantiate.text = ::L.t "ribbon_instantiate_to_material_editor_btn"
				Btn_Instantiate.tooltip = ::L.t "ribbon_instantiate_the_current_ribbon_tip"
			)
		)
	)
	rollout Ribbon_Window2 "Ribbon Properties" width:162 height:300
	(
		label			l01		   "——— - Ribbon Color - ———"						align:#center
		colorPicker 	cp1									pos:[8,25]					   height:32	width:142		color:white
		label			l02			"Controller:"			 pos:[12,69]	align:#left
		checkbutton	btn_color_none    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Instant Controller" pos:[58,66 ] width:20 height:20
		checkbutton	btn_color_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller" pos:[82,66] width:20 height:20
		checkbutton	btn_color_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller" pos:[106,66] width:20 height:20
		checkbutton	btn_color_hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,66] width:20 height:20

		HyperLink		fg01	"——————————————"			pos:[12,84]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg02	"——————————————"			pos:[12,85]   align:#center	width:138	color:(color 112 112 112)		enabled:false

		label			l03			"Above Length:"			 pos:[12,99]	align:#left		 width:85
		spinner spn_staticHeightAbove						pos:[94,98]					   	height:16	fieldwidth:44	range:[0,10000,20]	type:#float
		label		 	l04			"Controller:"			 pos:[12,126]	align:#left
		checkbutton	btn_above_none    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Instant Controller" pos:[58,123 ] width:20 height:20
		checkbutton	btn_above_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller" pos:[82,123] width:20 height:20
		checkbutton	btn_above_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller" pos:[106,123] width:20 height:20
		checkbutton	btn_above_hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,123] width:20 height:20

		HyperLink		fg03	"——————————————"			pos:[12,141]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg04	"——————————————"			pos:[12,142]   align:#center	width:138	color:(color 112 112 112)		enabled:false

		label			l05			"Below Length:"			 pos:[12,156]	align:#left		 width:85
		spinner spn_staticHeightBelow						pos:[94,155]					height:16	fieldwidth:44	range:[0,10000,20]	type:#float
		label		 	l06			"Controller:"			 pos:[12,183]	align:#left
		checkbutton	btn_below_none    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Instant Controller" pos:[58,180 ] width:20 height:20
		checkbutton	btn_below_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller" pos:[82,180] width:20 height:20
		checkbutton	btn_below_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller" pos:[106,180] width:20 height:20
		checkbutton	btn_below_hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,180] width:20 height:20

		HyperLink		fg05	"——————————————"			pos:[12,198]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg06	"——————————————"			pos:[12,199]   align:#center	width:138	color:(color 112 112 112)		enabled:false

		label			l09			"Alpha:"				 pos:[12,213]	align:#left		width:85
		spinner spn_alpha									pos:[94,212]				   height:16	fieldwidth:44	range:[0,1,1]	type:#float
		label			l10			"Controller:"			 pos:[12,240]	align:#left
		checkbutton	btn_alpha_none    images:#(Icon_Path + "ndx_none.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Instant Controller" pos:[58,237 ] width:20 height:20
		checkbutton	btn_alpha_linear  images:#(Icon_Path + "ndx_linear.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Linear Controller" pos:[82,237] width:20 height:20
		checkbutton	btn_alpha_bezier  images:#(Icon_Path + "ndx_bezier.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Bezier Controller" pos:[106,237] width:20 height:20
		checkbutton	btn_alpha_hermite images:#(Icon_Path + "ndx_hermite.bmp", undefined, 2, 1,2,1,2, True) tooltip:"Hermite Controller" pos:[130,237] width:20 height:20

		HyperLink		fg11	"——————————————"			pos:[12,255]   align:#center	width:138	color:(color 32 32 32)			enabled:false
		HyperLink		fg12	"——————————————"			pos:[12,256]   align:#center	width:138	color:(color 112 112 112)		enabled:false

		label			l11			"Emission Rate:"	 pos:[12,270]	align:#left		width:85
		spinner spn_emission								pos:[94,269]				   height:16	fieldwidth:44	range:[0,1000,10]	type:#float

		label			l12			"Life Span:"		 pos:[12,297]	align:#left		width:85
		spinner spn_life									pos:[94,296]				   height:16	fieldwidth:44	range:[0,100000,2]	type:#float

		label			l13			"Gravity:"				pos:[12,324]	align:#left		width:85
		spinner spn_gravity									pos:[94,323]				   height:16	fieldwidth:44	range:[-10000,10000,0]	type:#float
		
		--------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
		-- Button group arrays (initialized in on open)
		local colorBtns, aboveBtns, belowBtns, alphaBtns
		
		-- ==================== Generic Helper Functions ====================
		
		-- Syncs a group of 4 controller checkbuttons for float properties.
		fn syncFloatBtnGroup btnArr ctrl =
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
		
		-- Syncs a group of 4 controller checkbuttons for color properties.
		-- Color uses Bezier_Color, Bezier_Point3 (for linear), and TCB_Color.
		fn syncColorBtnGroup btnArr ctrl =
		(
			for b in btnArr do b.checked = false
			if ctrl != undefined do
			(
				if classof ctrl == Bezier_Color then
				(
					if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #step then
						btnArr[1].checked = true
					else
						btnArr[3].checked = true
				)
				else if classof ctrl == Bezier_Point3 then
				(
					if ctrl.keys.count > 0 and ctrl.keys[1].inTangentType == #linear then
						btnArr[2].checked = true
				)
				else if classof ctrl == TCB_Color then
					btnArr[4].checked = true
			)
		)
		
		-- Applies tangent types to all keys of a controller.
		fn applyTangents ctrl tangentType =
		(
			for i = 1 to ctrl.keys.count do
			(
				ctrl.keys[i].inTangentType = tangentType
				ctrl.keys[i].outTangentType = tangentType
			)
		)

		-- ==================== Refresh Functions ====================
		fn refreshColor = (try(syncColorBtnGroup colorBtns (if selection.count > 0 and selection[1].vertexcolor.isAnimated then selection[1].vertexcolor.controller else undefined))catch())
		fn refreshAbove = (try(syncFloatBtnGroup aboveBtns (if selection.count > 0 and selection[1].Above.isAnimated then selection[1].Above.controller else undefined))catch())
		fn refreshBelow = (try(syncFloatBtnGroup belowBtns (if selection.count > 0 and selection[1].Below.isAnimated then selection[1].Below.controller else undefined))catch())
		fn refreshAlpha = (try(syncFloatBtnGroup alphaBtns (if selection.count > 0 and selection[1].alpha.isAnimated then selection[1].alpha.controller else undefined))catch())

		-- ==================== Color Controller Events ====================
		on btn_color_none changed state do
		(	try (
				if selection[1].vertexcolor.isAnimated then
				(	if classof selection[1].vertexcolor.controller != Bezier_color do selection[1].vertexcolor.controller = Bezier_color()
					applyTangents selection[1].vertexcolor.controller #step
					refreshColor(); messagebox MessageboxText2
				) else (refreshColor(); messagebox MessageboxText3)
			) catch()
		)
		on btn_color_linear changed state do
		(	try (
				if selection[1].vertexcolor.isAnimated then
				(	if classof selection[1].vertexcolor.controller != bezier_point3 do selection[1].vertexcolor.controller = bezier_point3()
					applyTangents selection[1].vertexcolor.controller #linear
					refreshColor(); messagebox MessageboxText2
				) else (refreshColor(); messagebox MessageboxText3)
			) catch()
		)
		on btn_color_bezier changed state do
		(	try (
				if selection[1].vertexcolor.isAnimated then
				(	if classof selection[1].vertexcolor.controller != Bezier_color do selection[1].vertexcolor.controller = Bezier_color()
					applyTangents selection[1].vertexcolor.controller #flat
					refreshColor(); messagebox MessageboxText2
				) else (refreshColor(); messagebox MessageboxText3)
			) catch()
		)
		on btn_color_hermite changed state do
		(	try (
				if selection[1].vertexcolor.isAnimated then
				(	selection[1].vertexcolor.controller = TCB_color()
					refreshColor(); messagebox MessageboxText2
				) else (refreshColor(); messagebox MessageboxText3)
			) catch()
		)
		-- ==================== Above Length Controller Events ====================
		on btn_above_none changed state do
		(	try (
				if selection[1].Above.isAnimated then
				(	if classof selection[1].Above.controller != Bezier_float do selection[1].Above.controller = Bezier_float()
					applyTangents selection[1].Above.controller #step
					refreshAbove(); messagebox MessageboxText2
				) else (refreshAbove(); messagebox MessageboxText3)
			) catch()
		)
		on btn_above_linear changed state do
		(	try (
				if selection[1].Above.isAnimated then
				(	selection[1].Above.controller = Linear_float()
					refreshAbove(); messagebox MessageboxText2
				) else (refreshAbove(); messagebox MessageboxText3)
			) catch()
		)
		on btn_above_bezier changed state do
		(	try (
				if selection[1].Above.isAnimated then
				(	if classof selection[1].Above.controller != Bezier_float do selection[1].Above.controller = Bezier_float()
					applyTangents selection[1].Above.controller #flat
					refreshAbove(); messagebox MessageboxText2
				) else (refreshAbove(); messagebox MessageboxText3)
			) catch()
		)
		on btn_above_hermite changed state do
		(	try (
				if selection[1].Above.isAnimated then
				(	selection[1].Above.controller = TCB_float()
					refreshAbove(); messagebox MessageboxText2
				) else (refreshAbove(); messagebox MessageboxText3)
			) catch()
		)
		-- ==================== Below Length Controller Events ====================
		on btn_below_none changed state do
		(	try (
				if selection[1].Below.isAnimated then
				(	if classof selection[1].Below.controller != Bezier_float do selection[1].Below.controller = Bezier_float()
					applyTangents selection[1].Below.controller #step
					refreshBelow(); messagebox MessageboxText2
				) else (refreshBelow(); messagebox MessageboxText3)
			) catch()
		)
		on btn_below_linear changed state do
		(	try (
				if selection[1].Below.isAnimated then
				(	selection[1].Below.controller = Linear_float()
					refreshBelow(); messagebox MessageboxText2
				) else (refreshBelow(); messagebox MessageboxText3)
			) catch()
		)
		on btn_below_bezier changed state do
		(	try (
				if selection[1].Below.isAnimated then
				(	if classof selection[1].Below.controller != Bezier_float do selection[1].Below.controller = Bezier_float()
					applyTangents selection[1].Below.controller #flat
					refreshBelow(); messagebox MessageboxText2
				) else (refreshBelow(); messagebox MessageboxText3)
			) catch()
		)
		on btn_below_hermite changed state do
		(	try (
				if selection[1].Below.isAnimated then
				(	selection[1].Below.controller = TCB_float()
					refreshBelow(); messagebox MessageboxText2
				) else (refreshBelow(); messagebox MessageboxText3)
			) catch()
		)
		-- ==================== Alpha Controller Events ====================
		on btn_alpha_none changed state do
		(	try (
				if selection[1].alpha.isAnimated then
				(	if classof selection[1].alpha.controller != Bezier_float do selection[1].alpha.controller = Bezier_float()
					applyTangents selection[1].alpha.controller #step
					refreshAlpha(); messagebox MessageboxText2
				) else (refreshAlpha(); messagebox MessageboxText3)
			) catch()
		)
		on btn_alpha_linear changed state do
		(	try (
				if selection[1].alpha.isAnimated then
				(	selection[1].alpha.controller = Linear_float()
					refreshAlpha(); messagebox MessageboxText2
				) else (refreshAlpha(); messagebox MessageboxText3)
			) catch()
		)
		on btn_alpha_bezier changed state do
		(	try (
				if selection[1].alpha.isAnimated then
				(	if classof selection[1].alpha.controller != Bezier_float do selection[1].alpha.controller = Bezier_float()
					applyTangents selection[1].alpha.controller #flat
					refreshAlpha(); messagebox MessageboxText2
				) else (refreshAlpha(); messagebox MessageboxText3)
			) catch()
		)
		on btn_alpha_hermite changed state do
		(	try (
				if selection[1].alpha.isAnimated then
				(	selection[1].alpha.controller = TCB_float()
					refreshAlpha(); messagebox MessageboxText2
				) else (refreshAlpha(); messagebox MessageboxText3)
			) catch()
		)

		-- ==================== Spinner/ColorPicker Events ====================
		on cp1 changed val                  do refreshColor()
		on spn_staticHeightAbove changed val do refreshAbove()
		on spn_staticHeightBelow changed val do refreshBelow()
		on spn_alpha changed val             do refreshAlpha()

		-- ==================== Rollout Open ====================
		on Ribbon_Window2 open do
		(
			-- Initialize button group arrays
			colorBtns = #(btn_color_none, btn_color_linear, btn_color_bezier, btn_color_hermite)
			aboveBtns = #(btn_above_none, btn_above_linear, btn_above_bezier, btn_above_hermite)
			belowBtns = #(btn_below_none, btn_below_linear, btn_below_bezier, btn_below_hermite)
			alphaBtns = #(btn_alpha_none, btn_alpha_linear, btn_alpha_bezier, btn_alpha_hermite)

			refreshColor()
			refreshAbove()
			refreshBelow()
			refreshAlpha()

			-- Localization
			if ::L != undefined then
			(
				Ribbon_Window2.title = ::L.t "ribbon_ribbon_properties_title"
				l01.text = ::L.t "ribbon__ribbon_color_lbl"
				l02.text = ::L.t "ribbon_controller_lbl"
				btn_color_none.tooltip = ::L.t "ribbon_instant_controller_tip"
				btn_color_linear.tooltip = ::L.t "ribbon_linear_controller_tip"
				btn_color_bezier.tooltip = ::L.t "ribbon_bezier_controller_tip"
				btn_color_hermite.tooltip = ::L.t "ribbon_hermite_controller_tip"
				l03.text = ::L.t "ribbon_above_length_lbl"
				l04.text = ::L.t "ribbon_controller_lbl_2"
				btn_above_none.tooltip = ::L.t "ribbon_instant_controller_tip_2"
				btn_above_linear.tooltip = ::L.t "ribbon_linear_controller_tip_2"
				btn_above_bezier.tooltip = ::L.t "ribbon_bezier_controller_tip_2"
				btn_above_hermite.tooltip = ::L.t "ribbon_hermite_controller_tip_2"
				l05.text = ::L.t "ribbon_below_length_lbl"
				l06.text = ::L.t "ribbon_controller_lbl_3"
				btn_below_none.tooltip = ::L.t "ribbon_instant_controller_tip_3"
				btn_below_linear.tooltip = ::L.t "ribbon_linear_controller_tip_3"
				btn_below_bezier.tooltip = ::L.t "ribbon_bezier_controller_tip_3"
				btn_below_hermite.tooltip = ::L.t "ribbon_hermite_controller_tip_3"
				l09.text = ::L.t "ribbon_alpha_lbl"
				l10.text = ::L.t "ribbon_controller_lbl_4"
				btn_alpha_none.tooltip = ::L.t "ribbon_instant_controller_tip_4"
				btn_alpha_linear.tooltip = ::L.t "ribbon_linear_controller_tip_4"
				btn_alpha_bezier.tooltip = ::L.t "ribbon_bezier_controller_tip_4"
				btn_alpha_hermite.tooltip = ::L.t "ribbon_hermite_controller_tip_4"
				l11.text = ::L.t "ribbon_emission_rate_lbl"
				l12.text = ::L.t "ribbon_life_span_lbl"
				l13.text = ::L.t "ribbon_gravity_lbl"
			)
		)
	)
	
	------------------------------------Create ribbon object shape------------------------------------
	tool create 
	(
		on mousePoint click do
		(
			case click of
				(
					1:(
						nodeTM.translation = gridPoint
						this.rmaterial = Warcraft3()
						this.rmaterial.path	= this.path
						this.rmaterial.filtermode = this.filtermode
						this.rmaterial.twosides = this.twosides
						this.rmaterial.unshaded = this.unshaded
						this.rmaterial.unfogged = this.unfogged
						this.rmaterial.PriorityPlane = this.PriorityPlane
						#stop
					)
				)
		)
	)

	function BuildGizmo points Drawcolor =
	(
		local unselectedColor = Drawcolor
		local selectedColor	  = Drawcolor
		local giz = manip.makeGizmoShape()
		giz.startNewLine()
		for pnt in points do giz.addpoint pnt
		this.addGizmoShape giz 0 unselectedColor selectedColor
	)

	on updateGizmos do
	(
		this.clearGizmos()
		local Drawcolor = [255,89,136]
		Drawcolor = [Drawcolor.x/255,Drawcolor.y/255,Drawcolor.z/255]
		
		-- Limit display values to 70 units for better visualization
		local displayHeightA = heightA
		local displayHeightB = heightB
		if displayHeightA.y > 70 then displayHeightA.y = 70
		if displayHeightB.y > 70 then displayHeightB.y = 70
		
		BuildGizmo #([0,-2,0],[0,-2,8]) Drawcolor
		BuildGizmo #([0,2,0],[0,2,8]) Drawcolor
		BuildGizmo #([0,-4,8],[0,0,12],[0,4,8],[0,-4,8]) Drawcolor
		BuildGizmo #(displayHeightB * -1,[0,0,0]) Drawcolor
		BuildGizmo #([0,0,0],displayHeightA) Drawcolor
		BuildGizmo #([0,0,-8],[0,0,24]) Drawcolor
	)
	----------------------------------------------------------------------------------------
)
