plugin material Warcraft3
name:"Warcraft 3"
classID:#(0x681a50f9, 0x2fae1330)
extends:Standard replaceUI:true version:5
(	
	-- Sets viewport display based on WC3 replaceable texture type.
	-- val: 0=None, 1=Normal, 2=TeamColor, 3=TeamGlow, 4+=other replaceables
	fn adjustMapping val =
	(
		local defaultDiffuse = color 92 92 92
		local defaultAmbient = color 150 150 150
		
		if val <= 1 then
		(
			-- Normal texture or no replaceable: show texture directly
			delegate.diffuseMap = this.texture
			delegate.opacityMap = this.opacityTexture
			delegate.Diffuse = defaultDiffuse
			delegate.Ambient = defaultAmbient
		)
		else if val == 2 then
		(
			-- Team Color: composite texture over team color using alpha as mask
			-- WC3 formula: finalColor = tex.rgb * tex.a + teamcolor.rgb * (1 - tex.a)
			if this.texture != undefined then
			(
				local compositeMap = Mix()
				compositeMap.color1 = NeoDexWc3MaterialTeamColors[NeoDexTeamColor]

				-- RGB channel from texture
				this.texture.monoOutput = 0
				this.texture.alphaSource = 0
				compositeMap.map2 = this.texture

				-- Alpha channel as blend mask (separate copy)
				local alphaMask = copy this.texture
				alphaMask.monoOutput = 1
				alphaMask.alphaSource = 0
				compositeMap.mask = alphaMask

				delegate.diffuseMap = compositeMap
				delegate.opacityMapEnable = off
			)
			else
			(
				delegate.diffuseMap = undefined
				delegate.opacityMap = undefined
			)
			-- Team Color needs white base so the Mix output isn't tinted
			delegate.Diffuse = color 255 255 255
			delegate.Ambient = color 255 255 255
		)
		else if val == 3 then
		(
			-- Team Glow: use pre-loaded team glow textures
			local hasGlowTex = (NeoDexWc3MaterialTeamGlowTextures.count == 16)
			local glowTex = if hasGlowTex then NeoDexWc3MaterialTeamGlowTextures[NeoDexTeamColor] else undefined
			delegate.diffuseMap = glowTex
			delegate.opacityMap = glowTex
			delegate.Diffuse = defaultDiffuse
			delegate.Ambient = defaultAmbient
		)
		else
		(
			-- Other replaceables (Cliff, Trees, etc): no viewport preview available
			delegate.diffuseMap = undefined
			delegate.opacityMap = undefined
			delegate.Diffuse = defaultDiffuse
			delegate.Ambient = defaultAmbient
		)
	)
	-- Configures viewport opacity display based on WC3 filter mode.
	-- val: 1=None, 2=Transparent, 3=Blend, 4=Additive, 5=Additive2x, 6=Modulate, 7=Modulate2x
	fn adjustFilterMode val =
	(
		-- Helper: configure bitmap opacity channel output
		fn configureBitmapOpacity bmpTex mono alpha =
		(
			if classof bmpTex == Bitmaptexture do
			(
				bmpTex.monoOutput = mono
				bmpTex.alphaSource = alpha
			)
		)
		
		-- Helper: detect if texture uses meaningful alpha channel
		-- by sampling corner and center pixels.
		-- Returns false (= no alpha, use RGB) when bitmap can't be read.
		fn textureHasAlpha bmpTex =
		(
			if classof bmpTex != Bitmaptexture do return false
			try
			(
				local bmp = bmpTex.bitmap
				if bmp == undefined do return false
				local w = bmp.width
				local h = bmp.height
				local samplePoints = #([0,0], [w-1,0], [0,h-1], [w-1,h-1], [w/2,h/2], [w/4,h/4], [w*3/4,h*3/4])
				for pt in samplePoints do
				(
					local px = (getPixels bmp pt 1)[1]
					if px.alpha < 250 do return true
				)
				return false
			) catch ( return false )
		)
		
		local grayDiffuse = color 92 92 92
		local grayAmbient = color 150 150 150
		
		-- Mode 1: None - no transparency at all
		if val == 1 then
		(
			delegate.opacityMapEnable = off
			delegate.Diffuse = grayDiffuse
			delegate.Ambient = grayAmbient
			return()
		)
		
		-- All other modes need an opacity map to work
		local opMap = delegate.opacityMap
		if opMap == undefined then
		(
			delegate.opacityMapEnable = off
			return()
		)
		
		-- Modes 2-3: Transparent / Blend - alpha test/blend
		if val == 2 or val == 3 then
		(
			delegate.opacityMapEnable = on
			delegate.opacityType = 0
			delegate.Diffuse = grayDiffuse
			delegate.Ambient = grayAmbient
			configureBitmapOpacity opMap 1 0
		)
		-- Modes 4-5: Additive / Additive 2x - black background + additive
		else if val == 4 or val == 5 then
		(
			delegate.opacityMapEnable = on
			delegate.opacityType = 0
			delegate.Diffuse = color 0 0 0
			delegate.Ambient = color 0 0 0
			if classof opMap == Bitmaptexture do
			(
				opMap.coords.U_Tile = true
				opMap.coords.V_Tile = true
				-- Auto-detect: if all sampled pixels have full alpha,
				-- use RGB luminance for opacity (common for additive effects).
				-- Otherwise use the alpha channel.
				if textureHasAlpha opMap then
					configureBitmapOpacity opMap 1 0
				else
					configureBitmapOpacity opMap 0 2
			)
		)
		-- Modes 6-7: Modulate / Modulate 2x - multiply blend
		else if val == 6 or val == 7 then
		(
			delegate.opacityMapEnable = off
			delegate.opacityType = 1
			delegate.Diffuse = grayDiffuse
			delegate.Ambient = grayAmbient
		)
	)
	-- Creates an opacity map copy from the diffuse texture.
	-- Returns the configured texture or undefined if no valid texture.
	fn generateOpacity tex =
	(
		if classof tex != Bitmaptexture do return undefined
		local isValid = (tex.fileName != undefined and tex.fileName != "") or (tex.bitmap != undefined)
		if not isValid do return undefined
		tex.alphaSource = 0
		tex.monoOutput = 1
		delegate.opacityMap = tex
		tex
	)
	-- Applies both replaceable texture mapping and filter mode to the delegate material.
	-- Must be called whenever retexture or filterMode changes.
	fn adjustDelegate retexture filterMode =
	(
		adjustMapping retexture
		adjustFilterMode filterMode
		-- Team Color mode requires white Diffuse/Ambient so the Mix map
		-- compositing produces correct colors (gray would tint the output).
		if retexture == 2 do
		(
			delegate.Diffuse = color 255 255 255
			delegate.Ambient = color 255 255 255
		)
	)
	-- Counts the number of valid image file references inside an IFL animation file.
	-- IFL files list one texture filename per line; lines starting with ; are comments.
	fn getIFLFileCount iflPath =
	(
		local validCount = 0
		local iflDir = getFilenamePath iflPath
		local fileStream = openFile iflPath mode:"r"
		if fileStream == undefined do return 0
		while not eof fileStream do
		(
			local entry = readLine fileStream
			-- Strip whitespace
			entry = trimLeft entry
			entry = trimRight entry
			-- Skip empty lines and comments
			if entry.count == 0 do continue
			if matchPattern entry pattern:"*;*" do continue
			-- Check if the referenced file actually exists
			local resolvedPath = pathConfig.normalizePath (pathConfig.appendPath iflDir entry)
			if doesFileExist resolvedPath do validCount += 1
		)
		close fileStream
		validCount
	)
	local isLoading		  = false
	local Icon_Path = ((systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\neodex_icons\\")
	local MessageboxTitle = "Tips"
	local MessageboxText1 = "Generation completed!"
	local MessageboxText2 = "Conversion completion!"
	local MessageboxText3 = "There is no animation data for the current attribute!"
	local MessageboxText4 = "Please import the bitmap and generate it again!"
	local MessageboxText5 = "You haven't selected any object in the scene yet!"
	local SJTJ_Front1 = "Anim Keys:"
	local SJTJ_After1 = "F"
	local SJTJ_Front2 = "Anim Time:"
	local SJTJ_After2 = "S"
	

	--------------------------------BLP1 Decode Support (C# Helper)------------------------
	-- Kompiliert einen C# Helper als DLL fuer schnelles BLP1 Decoding
	-- Wird lazy beim ersten BLP-Zugriff kompiliert und bleibt im Speicher
	local g_blpCS = undefined
	local g_blpFailed = false
	local g_blpTemp = (getDir #temp) + "\\BLP_Textures\\"
	
	fn ensureBLPHelper = (
		if g_blpCS != undefined do return true
		if g_blpFailed do return false
		makeDir g_blpTemp all:true
		local dllPath = g_blpTemp + "BLPHelper.dll"
		
		-- Step 1: Try loading existing BLPHelper.dll
		if (doesFileExist dllPath) do
		(
			try
			(
				dotNet.loadAssembly dllPath
				g_blpCS = dotNetClass "BLPHelper"
				if g_blpCS != undefined do return true
			)
			catch()
		)
		
		-- Step 2: Try loading BLPHelper_v17.dll (legacy name)
		local v17Path = g_blpTemp + "BLPHelper_v17.dll"
		if (doesFileExist v17Path) do
		(
			try
			(
				dotNet.loadAssembly v17Path
				g_blpCS = dotNetClass "BLPHelper"
				if g_blpCS != undefined do return true
			)
			catch()
		)
		
		-- Step 3: Compile from source
		local csharpCode = "
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public class BLPHelper
{
    public static string DecodeBLP(string blpPath, string pngPath)
    {
        try
        {
            byte[] d = File.ReadAllBytes(blpPath);
            if (d.Length < 156) return \"ERR|Datei zu klein\";
            if (d[0]!=0x42||d[1]!=0x4C||d[2]!=0x50||d[3]!=0x31) return \"ERR|Kein BLP1\";
            int comp=BitConverter.ToInt32(d,4), alphaD=BitConverter.ToInt32(d,8);
            int w=BitConverter.ToInt32(d,12), h=BitConverter.ToInt32(d,16);
            int picType=BitConverter.ToInt32(d,20);
            int mipOff=BitConverter.ToInt32(d,28), mipSize=BitConverter.ToInt32(d,92);
            if (mipOff<=0||mipSize<=0) return \"ERR|Mipmap ungueltig\";
            if (comp==1) {
                int aBits=0;
                if (picType==3||picType==4) aBits=8;
                if (alphaD==8) aBits=8; if (alphaD==4) aBits=4; if (alphaD==1) aBits=1;
                if (alphaD==0&&picType>=5) aBits=0;
                DecodePal(d,156,mipOff,mipSize,w,h,aBits,pngPath);
            } else if (comp==0) {
                int hs=BitConverter.ToInt32(d,156);
                DecodeJPG(d,160,hs,mipOff,mipSize,w,h,pngPath);
            } else return \"ERR|Typ \"+comp;
            return \"OK|\"+w+\"|\"+h+\"|\"+comp+\"|\"+alphaD+\"|\"+picType;
        } catch(Exception ex) { return \"ERR|\"+ex.Message; }
    }
    static void DecodePal(byte[] d,int po,int mo,int ms,int w,int h,int ab,string o) {
        int n=w*h; byte[] pR=new byte[256],pG=new byte[256],pB=new byte[256];
        for(int i=0;i<256;i++){int p=po+i*4;pB[i]=d[p];pG[i]=d[p+1];pR[i]=d[p+2];}
        int aS=ms-n; if(aS<0)aS=0; if(ab>0&&aS<=0)ab=0;
        Bitmap b=new Bitmap(w,h,PixelFormat.Format32bppArgb);
        BitmapData bd=b.LockBits(new Rectangle(0,0,w,h),ImageLockMode.WriteOnly,PixelFormat.Format32bppArgb);
        int st=Math.Abs(bd.Stride); byte[] px=new byte[st*h];
        for(int y=0;y<h;y++){int ro=y*st;for(int x=0;x<w;x++){
            int idx=y*w+x,ci=d[mo+idx]; byte r=pR[ci],g=pG[ci],bl=pB[ci],a=255;
            if(ab>0&&aS>0){int aO=mo+n;
                if(ab==8){if(idx<aS)a=d[aO+idx];}
                else if(ab==4){int bi=idx/2;if(bi<aS){byte bv=d[aO+bi];a=(idx%2==0)?(byte)((bv&0x0F)*17):(byte)(((bv>>4)&0x0F)*17);}}
                else if(ab==1){int bi=idx/8;if(bi<aS){byte bv=d[aO+bi];a=(byte)((bv&(1<<(idx%8)))!=0?255:0);}}
            }
            int pp=ro+x*4;px[pp]=bl;px[pp+1]=g;px[pp+2]=r;px[pp+3]=a;
        }}
        Marshal.Copy(px,0,bd.Scan0,px.Length);b.UnlockBits(bd);b.Save(o,ImageFormat.Png);b.Dispose();
    }
    static void DecodeJPG(byte[] d,int hs,int hsl,int mo,int ms,int w,int h,string o) {
        byte[] j=new byte[hsl+ms]; Array.Copy(d,hs,j,0,hsl); Array.Copy(d,mo,j,hsl,ms);
        Bitmap s; using(MemoryStream m=new MemoryStream(j)){s=new Bitmap(m);}
        int iw=s.Width,ih=s.Height;
        Bitmap b=new Bitmap(iw,ih,PixelFormat.Format32bppArgb);
        using(Graphics g=Graphics.FromImage(b)){g.DrawImage(s,0,0,iw,ih);} s.Dispose();
        BitmapData bd=b.LockBits(new Rectangle(0,0,iw,ih),ImageLockMode.ReadWrite,PixelFormat.Format32bppArgb);
        int st=Math.Abs(bd.Stride); byte[] px=new byte[st*ih];
        Marshal.Copy(bd.Scan0,px,0,px.Length);
        for(int i=0;i<px.Length;i+=4){byte t=px[i];px[i]=px[i+2];px[i+2]=t;}
        Marshal.Copy(px,0,bd.Scan0,px.Length);b.UnlockBits(bd);b.Save(o,ImageFormat.Png);b.Dispose();
    }
}
"
		try ( deleteFile dllPath ) catch ()
		
		local compiled = false
		
		-- Methode 1: CSharpCodeProvider (3ds Max < 2025, .NET Framework)
		try (
			local provider = dotNetObject "Microsoft.CSharp.CSharpCodeProvider"
			local params = dotNetObject "System.CodeDom.Compiler.CompilerParameters"
			params.ReferencedAssemblies.Add "System.dll"
			params.ReferencedAssemblies.Add "System.Drawing.dll"
			params.GenerateInMemory = false
			params.OutputAssembly = dllPath
			local result = provider.CompileAssemblyFromSource params #(csharpCode)
			if (not result.Errors.HasErrors) do ( compiled = true )
		) catch ()
		
		-- Methode 2: csc.exe Kommandozeile (3ds Max 2025+ / .NET 6+)
		if (not compiled) do
		(
			-- C# Quellcode als .cs Datei schreiben
			local csPath = g_blpTemp + "BLPHelper.cs"
			try ( (dotNetClass "System.IO.File").WriteAllText csPath csharpCode ) catch()
			
			-- csc.exe dynamisch suchen
			local cscPath = undefined
			local fwBase = (dotNetClass "System.Runtime.InteropServices.RuntimeEnvironment").GetRuntimeDirectory()
			if fwBase != undefined do
			(
				local testCsc = fwBase + "csc.exe"
				if (doesFileExist testCsc) do ( cscPath = testCsc )
			)
			if cscPath == undefined do
			(
				local winDir = (dotNetClass "System.Environment").GetFolderPath (dotNetClass "System.Environment+SpecialFolder").Windows
				local candidates = #(
					winDir + @"\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
					winDir + @"\Microsoft.NET\Framework\v4.0.30319\csc.exe"
				)
				for c in candidates while cscPath == undefined do
					if (doesFileExist c) do ( cscPath = c )
			)
			
			if cscPath != undefined then
			(
				-- Build reference paths from runtime directory
				local refDir = fwBase
				local sysRef = refDir + "System.dll"
				local drawRef = refDir + "System.Drawing.dll"
				
				local args = "/target:library"
				args += " /out:\"" + dllPath + "\""
				args += " /reference:\"" + sysRef + "\",\"" + drawRef + "\""
				args += " \"" + csPath + "\""
				
				local startInfo = dotNetObject "System.Diagnostics.ProcessStartInfo"
				startInfo.FileName = cscPath
				startInfo.Arguments = args
				startInfo.UseShellExecute = false
				startInfo.CreateNoWindow = true
				startInfo.RedirectStandardOutput = true
				startInfo.RedirectStandardError = true
				
				local proc = dotNetObject "System.Diagnostics.Process"
				proc.StartInfo = startInfo
				proc.Start()
				proc.WaitForExit 30000
				
				if (proc.ExitCode == 0) and (doesFileExist dllPath) do ( compiled = true )
				
				if (not compiled) do
				(
					local errOutput = proc.StandardError.ReadToEnd()
					format "*** Wc3Material BLP compile error: %\n" errOutput
				)
			)
			else
			(
				format "*** Wc3Material: csc.exe nicht gefunden. .NET Framework 4.x scheint nicht installiert.\n"
			)
		)
		
		if (not compiled) do ( g_blpFailed = true; return false )
		dotNet.loadAssembly dllPath
		g_blpCS = dotNetClass "BLPHelper"
		return (g_blpCS != undefined)
	)
	
	--------------------------------TGA/DDS/BLP Preview Support-----------------------------
	-- Diese Funktion ermöglicht die Vorschau von TGA, DDS und BLP Dateien
	-- PNG/JPG/BMP funktionieren weiterhin wie gewohnt
	fn LoadImageForPreview imagePath =
	(
		if imagePath == undefined or imagePath == "" do return undefined
		
		-- If file not found at stored path, try scene-relative (common when
		-- opening .max files from another machine with different folder structure)
		if not (doesFileExist imagePath) then
		(
			local baseName = filenameFromPath imagePath
			local sceneDir = getFilenamePath maxFilePath
			if sceneDir != "" and sceneDir != undefined then
			(
				local scenePath = sceneDir + baseName
				if doesFileExist scenePath then
					imagePath = scenePath
				else
					return undefined
			)
			else
				return undefined
		)
		
		local ext = toLower (getFilenameType imagePath)
		
		-- PNG, JPG, BMP, GIF: Load via .NET FileStream to support Unicode paths
		-- (Chinese, Japanese, Korean etc. characters in folder/file names)
		if ext == ".png" or ext == ".jpg" or ext == ".jpeg" or ext == ".bmp" or ext == ".gif" then
		(
			try
			(
				local bytes = (dotNetClass "System.IO.File").ReadAllBytes imagePath
				local memStream = dotNetObject "System.IO.MemoryStream" bytes
				local dotNetBmp = dotNetObject "System.Drawing.Bitmap" memStream
				return dotNetBmp
			)
			catch
			(
				-- Fallback: load via 3ds Max openBitmap (handles Unicode natively)
				try
				(
					local maxBmp = openBitmap imagePath
					if maxBmp == undefined do return undefined
					local w = maxBmp.width
					local h = maxBmp.height
					local uniqueID = (timestamp() as string) + (random 1000 9999 as string)
					local tempPath = (getDir #temp) + "\\wc3mat_preview_" + uniqueID + ".png"
					local tempBmp = bitmap w h color:(color 0 0 0 0)
					copy maxBmp tempBmp
					close maxBmp
					tempBmp.filename = tempPath
					save tempBmp
					close tempBmp
					local dotNetBmp2 = dotNetObject "System.Drawing.Bitmap" tempPath
					try ( deleteFile tempPath ) catch ()
					return dotNetBmp2
				)
				catch ( return undefined )
			)
		)
		-- TGA, DDS, TIF, PSD, BLP (native): Über 3ds Max Bitmap laden und als temp PNG konvertieren
		else if ext == ".tga" or ext == ".dds" or ext == ".tif" or ext == ".tiff" or ext == ".psd" or (ext == ".blp" and ::NeoDexHasNativeBLP) then
		(
			try
			(
				-- For TGA: copy to temp file first to avoid file lock conflicts
				-- (Max may already have the file open for the Bitmaptexture)
				local actualPath = imagePath
				if ext == ".tga" then
				(
					local bytes = (dotNetClass "System.IO.File").ReadAllBytes imagePath
					local tempTga = (getDir #temp) + "\\wc3mat_tga_" + (timestamp() as string) + (random 1000 9999 as string) + ".tga"
					(dotNetClass "System.IO.File").WriteAllBytes tempTga bytes
					actualPath = tempTga
				)
				
				local maxBmp = openBitmap actualPath
				if maxBmp == undefined do
				(
					if actualPath != imagePath then try ( deleteFile actualPath ) catch ()
					return undefined
				)
				
				local w = maxBmp.width
				local h = maxBmp.height
				
				local uniqueID = (timestamp() as string) + (random 1000 9999 as string)
				local tempPath = (getDir #temp) + "\\wc3mat_preview_" + uniqueID + ".png"
				
				local tempBmp = bitmap w h color:(color 0 0 0 0)
				copy maxBmp tempBmp
				close maxBmp
				
				tempBmp.filename = tempPath
				save tempBmp
				close tempBmp
				
				-- Clean up temp TGA copy
				if actualPath != imagePath then try ( deleteFile actualPath ) catch ()
				
				local dotNetBmp = dotNetObject "System.Drawing.Bitmap" tempPath
				try ( deleteFile tempPath ) catch ()
				return dotNetBmp
			)
			catch
			(
				return undefined
			)
		)
		-- BLP Fallback: C# BLPHelper decoder (ohne blp.bmi)
		else if ext == ".blp" then
		(
			try
			(
				if not (ensureBLPHelper()) do return undefined
				
				local baseName = getFilenameFile imagePath
				local pngPath = g_blpTemp + baseName + ".png"
				
				local resultStr = g_blpCS.DecodeBLP imagePath pngPath
				local parts = filterString resultStr "|"
				if parts[1] != "OK" do return undefined
				
				local dotNetBmp = dotNetObject "System.Drawing.Bitmap" pngPath
				return dotNetBmp
			)
			catch
			(
				return undefined
			)
		)
		-- Unbekanntes Format: Versuche trotzdem mit .NET zu laden
		else
		(
			try
			(
				local dotNetBmp = dotNetObject "System.Drawing.Bitmap" imagePath
				return dotNetBmp
			)
			catch
			(
				return undefined
			)
		)
	)
	-- Updates the key count and time duration labels in the Animation rollout.
	-- mode 1 = flow animation, mode 2 = IFL/sequence animation
	fn RefreshTATime mode =
	(
		if mode == 1 then
		(
			try
			(
				local totalKeys = if this.FlowAnim7 then this.FlowAnim2 else (this.FlowAnim2 - this.FlowAnim1)
				local duration = totalKeys / 30.0
				this.window2.l68.caption = SJTJ_Front1 + " " + (totalKeys as string) + " " + SJTJ_After1
				this.window2.l74.caption = SJTJ_Front2 + " " + (duration as string) + " " + SJTJ_After2
			)
			catch
			(
				this.window2.l68.caption = SJTJ_Front1 + " 0 " + SJTJ_After1
				this.window2.l74.caption = SJTJ_Front2 + " 0 " + SJTJ_After2
			)
		)
		else
		(
			try
			(
				local iflFile = this.texture.bitmap.fileName
				local totalKeys = getIFLFileCount iflFile
				local duration = totalKeys / 30.0
				this.window2.l76.caption = SJTJ_Front1 + " " + (totalKeys as string) + " " + SJTJ_After1
				this.window2.l77.caption = SJTJ_Front2 + " " + (duration as string) + " " + SJTJ_After2
			)
			catch
			(
				this.window2.l76.caption = SJTJ_Front1 + " 0 " + SJTJ_After1
				this.window2.l77.caption = SJTJ_Front2 + " 0 " + SJTJ_After2
			)
		)
	)

	--------------------------------------------------------------------------------------------------

	-- Sets tangent types on all keys of a Bezier_float controller
	fn setBezierTangents ctrl tangentType =
	(
		if classof ctrl == Bezier_float do
			for i = 1 to ctrl.keys.count do
			(
				ctrl.keys[i].inTangentType = tangentType
				ctrl.keys[i].outTangentType = tangentType
			)
	)

	fn bnt_opacity_Instant_con =
	(
		try
		(
			if this.alpha.isAnimated != false then
			(
				-- Instant = Bezier with #step tangents; don't replace if already Bezier
				if classof this.alpha.controller != Bezier_float do
					this.alpha.controller = Bezier_float()
				setBezierTangents this.alpha.controller #step
				messagebox (MessageboxText2 + "    ") title:MessageboxTitle
			)else(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
		)catch()
	)

	fn bnt_opacity_linear_con =
	(
		try
		(
			if this.alpha.isAnimated != false then
			(
				this.alpha.controller = Linear_float ()
				messagebox (MessageboxText2 + "    ") title:MessageboxTitle
			)else(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
		)catch()
	)
	fn bnt_opacity_bezier_con =
	(
		try
		(
			if this.alpha.isAnimated != false then
			(
				-- Bezier smooth: don't replace if already Bezier, just change tangents
				if classof this.alpha.controller != Bezier_float do
					this.alpha.controller = Bezier_float()
				setBezierTangents this.alpha.controller #smooth
				messagebox (MessageboxText2 + "    ") title:MessageboxTitle
			)else(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
		)catch()
	)

	fn bnt_opacity_hermite_con =
	(
		try
		(
			if this.alpha.isAnimated != false then
			(
				this.alpha.controller = TCB_float ()
				messagebox (MessageboxText2 + "    ") title:MessageboxTitle
			)else(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
		)catch()
	)
	-----------------------------------------------------------------------------------------------------------------

	fn btn_tex_anim_instant =
	(
		try
		(
			local hasU = (this.texture.coords.U_offset.isAnimated != false)
			local hasV = (this.texture.coords.V_offset.isAnimated != false)
			if not hasU and not hasV do
			(
				messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				return()
			)
			-- Instant = Bezier with #step tangents
			if hasU do
			(
				if classof this.texture.coords.U_offset.controller != Bezier_float do
					this.texture.coords.U_offset.controller = Bezier_float()
				setBezierTangents this.texture.coords.U_offset.controller #step
				this.Wc3_U_Offset.controller = this.texture.coords.U_offset.controller
			)
			if hasV do
			(
				if classof this.texture.coords.V_offset.controller != Bezier_float do
					this.texture.coords.V_offset.controller = Bezier_float()
				setBezierTangents this.texture.coords.V_offset.controller #step
				this.Wc3_V_Offset.controller = this.texture.coords.V_offset.controller
			)
			messagebox (MessageboxText2 + "    ") title:MessageboxTitle
		)catch(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
	)

	fn btn_tex_anim_linear =
	(
		try
		(
			local hasU = (this.texture.coords.U_offset.isAnimated != false)
			local hasV = (this.texture.coords.V_offset.isAnimated != false)
			if not hasU and not hasV do
			(
				messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				return()
			)
			if hasU do
			(
				this.texture.coords.U_offset.controller = Linear_float()
				this.Wc3_U_Offset.controller = this.texture.coords.U_offset.controller
			)
			if hasV do
			(
				this.texture.coords.V_offset.controller = Linear_float()
				this.Wc3_V_Offset.controller = this.texture.coords.V_offset.controller
			)
			messagebox (MessageboxText2 + "    ") title:MessageboxTitle
		)catch(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
	)

	fn btn_tex_anim_bezier =
	(
		try
		(
			local hasU = (this.texture.coords.U_offset.isAnimated != false)
			local hasV = (this.texture.coords.V_offset.isAnimated != false)
			if not hasU and not hasV do
			(
				messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				return()
			)
			-- Bezier smooth: if already Bezier just change tangents, otherwise convert first
			if hasU do
			(
				if classof this.texture.coords.U_offset.controller != Bezier_float do
					this.texture.coords.U_offset.controller = Bezier_float()
				setBezierTangents this.texture.coords.U_offset.controller #smooth
				this.Wc3_U_Offset.controller = this.texture.coords.U_offset.controller
			)
			if hasV do
			(
				if classof this.texture.coords.V_offset.controller != Bezier_float do
					this.texture.coords.V_offset.controller = Bezier_float()
				setBezierTangents this.texture.coords.V_offset.controller #smooth
				this.Wc3_V_Offset.controller = this.texture.coords.V_offset.controller
			)
			messagebox (MessageboxText2 + "    ") title:MessageboxTitle
		)catch(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
	)

	fn btn_tex_anim_hermite =
	(
		try
		(
			local hasU = (this.texture.coords.U_offset.isAnimated != false)
			local hasV = (this.texture.coords.V_offset.isAnimated != false)
			if not hasU and not hasV do
			(
				messagebox (MessageboxText3 + "    ") title:MessageboxTitle
				return()
			)
			if hasU do
			(
				this.texture.coords.U_offset.controller = TCB_float()
				this.Wc3_U_Offset.controller = this.texture.coords.U_offset.controller
			)
			if hasV do
			(
				this.texture.coords.V_offset.controller = TCB_float()
				this.Wc3_V_Offset.controller = this.texture.coords.V_offset.controller
			)
			messagebox (MessageboxText2 + "    ") title:MessageboxTitle
		)catch(messagebox (MessageboxText3 + "    ") title:MessageboxTitle)
	)

	---------------------------------------------------------------------------------------------------
	
	fn materialControllersUpdate =
	(
		if this.texture == undefined then return false
		
		try
		(
			this.Wc3_U_offset.controller = this.texture.coords.U_offset.controller
			this.Wc3_V_offset.controller = this.texture.coords.V_offset.controller
		)
		catch()
		-- Rotation Controller synchronisieren
		try
		(
			this.Wc3_W_Angle.controller = this.texture.coords.W_Angle.controller
		)
		catch()
		-- Tiling Controller synchronisieren
		try
		(
			this.Wc3_U_Tiling.controller = this.texture.coords.U_Tiling.controller
			this.Wc3_V_Tiling.controller = this.texture.coords.V_Tiling.controller
		)
		catch()
	)
	
	fn textureControllersUpdate =
	(
		if this.texture == undefined then return false
		
		try
		(
			this.texture.coords.U_offset.controller = this.Wc3_U_offset.controller
			this.texture.coords.V_offset.controller = this.Wc3_V_offset.controller
		)
		catch()
		-- Rotation Controller synchronisieren
		try
		(
			this.texture.coords.W_Angle.controller = this.Wc3_W_Angle.controller
		)
		catch()
		-- Tiling Controller synchronisieren
		try
		(
			this.texture.coords.U_Tiling.controller = this.Wc3_U_Tiling.controller
			this.texture.coords.V_Tiling.controller = this.Wc3_V_Tiling.controller
		)
		catch()
	)
	
	parameters main rollout:window1
	(
		opacityTexture type:#texturemap
		-- Basic parameters --
		twosides		type:#boolean animatable:false default:false ui:flag1
		unshaded		type:#boolean animatable:false default:false ui:flag2
		unfogged		type:#boolean animatable:false default:false ui:flag3
		unselectable	type:#boolean animatable:false default:false ui:flag4
		NoDephTest		type:#boolean animatable:false default:false ui:flag5
		NoDephSet		type:#boolean animatable:false default:false ui:flag6
		ConstantColor	type:#boolean animatable:false default:false ui:flag7
		SphereEnvMap	type:#boolean animatable:false default:false ui:flag8
		FullResolution	type:#boolean animatable:false default:false ui:flag9
		SortPrimsFarZ		type:#integer animatable:false default:1	 ui:SortZ
		PriorityPlane	type:#integer animatable:false default:0	 ui:youxian
		-- Texture parameters --
		Wrap_Width		type:#boolean animatable:false default:false				ui:flag15
		Wrap_Height		type:#boolean animatable:false default:false				ui:flag16
		retexture		type:#integer animatable:false default:1					ui:assignReplaceable
		path 			type:#string  animatable:false default:""					ui:Pather
		texture			type:#texturemap											ui:NeoDexTexBtn
		Wc3_U_Offset	type:#float	  animatable:true
		Wc3_V_Offset	type:#float	  animatable:true
		Wc3_W_Angle		type:#float	  animatable:true
		Wc3_U_Tiling	type:#float	  animatable:true default:1.0
		Wc3_V_Tiling	type:#float	  animatable:true default:1.0
		UseCColor		type:#boolean animatable:false default:false
		MatColor		type:#color	  animatable:true  default:[0,0,0]

		-- Filter mode --
		filtermode		type:#integer animatable:false default:1	ui:filterbuttons
		-----------------------------------------------------------------------------------------------------
		on twosides set val do (try(delegate.twoSided = val)catch())
		on texture	set val do -- Führe nach dem Import der Texturen die folgenden Schritte aus.
		(
			try --Vermeide die Auswahl von Objekten wie Normalen, da deren coords-Werte nicht erfasst werden können.
			(
				
				this.opacityTexture = generateOpacity this.texture
				adjustDelegate this.retexture this.filtermode
				if val != undefined and (not isLoading) then
				(
					if delegate.diffuseMap != undefined then
					(
						this.Wrap_Width = this.texture.coords.V_Tile
						this.Wrap_Height = this.texture.coords.U_Tile
						this.window1.flag15.enabled = true
						this.window1.flag16.enabled = true
						this.window1.flag8.enabled = true
					)else
					(
						this.Wrap_Width = false
						this.Wrap_Height = false
						this.SphereEnvMap = false
						this.window1.flag15.enabled = false
						this.window1.flag16.enabled = false
						this.window1.flag8.enabled = false
					)
				)
				else isLoading = false
				local tmp = getFilenameType (this.texture.bitmap.fileName)
				if tmp == ".ifl" then (RefreshTATime 2)
			)catch()
				-- Sync diffuse display in Texture Maps rollout
			try
			(
				if val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
					this.reforgedRollout.btnDiffuseMap.text = filenameFromPath val.fileName
				else if val != undefined then
					this.reforgedRollout.btnDiffuseMap.text = "(Map)"
				else
					this.reforgedRollout.btnDiffuseMap.text = "None"
			) catch()
			-- Update preview PictureBox in Texture Maps rollout
			try
			(
				local rfImg = this.reforgedRollout.rfImgBox
				local rfBorder = this.reforgedRollout.rfPanel_Border
				if rfImg != undefined and val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
				(
					local rendered = renderMap val size:[120,120] filter:true
					if rendered != undefined then
					(
						local uniqueID = (timestamp() as string) + (random 1000 9999 as string)
						local tempPath = (getDir #temp) + "\\wc3mat_preview_" + uniqueID + ".png"
						rendered.filename = tempPath
						save rendered
						close rendered
						local dotNetBmp = dotNetObject "System.Drawing.Bitmap" tempPath
						try ( deleteFile tempPath ) catch ()
						if rfImg.image != undefined then rfImg.image.Dispose()
						rfImg.image = dotNetBmp
						rfImg.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
						rfBorder.visible = true
					)
					rfImg.Refresh()
				)
			) catch()
			materialControllersUpdate()
		)
		on Wc3_U_Offset set val do textureControllersUpdate()
		on Wc3_V_Offset set val do textureControllersUpdate()
		on Wc3_W_Offset set val do ()
		on path set val do
		(
			-- Sync prefix path to Texture Maps rollout
			try (this.reforgedRollout.edt_diffPath.text = if val != undefined then val else "") catch()
		)
		
		on retexture set val do
		(
			adjustDelegate val this.filtermode
			
			-- Update preview PictureBox in Texture Maps rollout
			try
			(
				local rfImg = this.reforgedRollout.rfImgBox
				local rfBorder = this.reforgedRollout.rfPanel_Border
				if rfImg == undefined then return()
				
				local previewBmp = undefined
				
				case val of
				(
					1: -- Normal: show diffuse texture
					(
						if this.texture != undefined and classof this.texture == Bitmaptexture and this.texture.fileName != undefined and this.texture.fileName != "" then
							previewBmp = LoadImageForPreview this.texture.fileName
					)
					2: -- Team Color: show diffuse texture (composited in viewport)
					(
						if this.texture != undefined and classof this.texture == Bitmaptexture and this.texture.fileName != undefined and this.texture.fileName != "" then
							previewBmp = LoadImageForPreview this.texture.fileName
					)
					3: -- Team Glow: show active team glow texture
					(
						if NeoDexWc3MaterialTeamGlowTextures != undefined and NeoDexWc3MaterialTeamGlowTextures.count == 16 then
						(
							local glowTex = NeoDexWc3MaterialTeamGlowTextures[NeoDexTeamColor]
							if glowTex != undefined and classof glowTex == Bitmaptexture and glowTex.fileName != undefined and glowTex.fileName != "" then
								previewBmp = LoadImageForPreview glowTex.fileName
						)
					)
					default: -- Other replaceables (Cliff, Trees, etc): no preview
					(
						previewBmp = undefined
					)
				)
				
				if rfImg.image != undefined then rfImg.image.Dispose()
				if previewBmp != undefined then
				(
					rfImg.image = previewBmp
					rfImg.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
					rfBorder.visible = true
				)
				else
				(
					rfImg.image = LoadImageForPreview (Icon_Path + "ndx_mat_none.png")
					rfImg.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
					rfBorder.visible = false
				)
			) catch ()
		)

		on filtermode set val do
		(
			adjustDelegate this.retexture val
			if (val == 1) or (val == 2) then 
			(
				this.NoDephSet = false
				this.window1.flag6.enabled = false
			)else
			(
				this.window1.flag6.enabled = true
			)
		)
		on unselectable set val do
		(
			local SelMattmp = medit.GetCurMtl()
			local Mat_obj = for o in objects where o.material == SelMattmp collect o
			if Mat_obj.count >= 1 then (for i in Mat_obj do (if val then (setUserProp i "Unselectable" 1) else (setUserProp i "Unselectable" 0))) else (val = false)
		)
		on SphereEnvMap set val do
		(
			try
			(
				if (val) then (this.texture.coords.mappingType = 1) else (this.texture.coords.mappingType = 0)
				
				this.opacityTexture = generateOpacity this.texture
				adjustFilterMode filterMode
			)catch
			(
				val = false
				this.window1.flag8.enabled = false
			)
		)
		on UseCColor set val do (try(delegate.useSelfIllumColor = val)catch())
		on MatColor set val do (try(delegate.selfIllumColor = val)catch())
		on Wrap_Width set val do
		(
			try
			(
				this.texture.coords.U_Tile = val
				this.opacityTexture = generateOpacity this.texture
				adjustFilterMode filterMode
			)catch
			(
				val = false
				this.window1.flag15.enabled = false
			)
		)
		
		on Wrap_Height set val do
		(
			try
			(
				this.texture.coords.V_Tile = val
				this.opacityTexture = generateOpacity this.texture
				adjustFilterMode filterMode
			)catch
			(
				val = false
				this.window1.flag16.enabled = false
			)
		)
		on NoDephTest set val do
		(
			if val then
			(
				this.window1.SortZ.enabled = true 
			)else
			(
				SortPrimsFarZ = 1
				this.window1.SortZ.enabled = false
			)
		)
	)
	parameters main rollout:window2
	(
		-- Sequence animation parameters --
		GenerateBtn1	type:#boolean	animatable:false	ui:chk_LDDH					default:false
		GenerateBtn2	type:#boolean	animatable:false	ui:chk_XLDH_Solo			default:true
		GenerateBtn3	type:#boolean	animatable:false	ui:chk_XLDH_Many			default:false
		FlowAnim1		type:#integer	animatable:false	ui:FlowAnim_StartTime		default:30
		FlowAnim2		type:#integer	animatable:false	ui:FlowAnim_EndTime			default:60
		FlowAnim3		type:#boolean	animatable:false	ui:FlowAnim_Up				default:false
		FlowAnim4		type:#boolean	animatable:false	ui:FlowAnim_Down			default:false
		FlowAnim5		type:#boolean	animatable:false	ui:FlowAnim_Left			default:false
		FlowAnim6		type:#boolean	animatable:false	ui:FlowAnim_Right			default:false
		FlowAnim7		type:#boolean	animatable:false	ui:FlowAnim_ON				default:false
		FlowAnim8		type:#boolean	animatable:false	ui:FlowAnim_OFF				default:true
		FlowAnim9		type:#boolean	animatable:false	ui:FlowAnim_Save_ON			default:false
		FlowAnim10		type:#boolean	animatable:false	ui:FlowAnim_Save_OFF		default:true
		FlowAnim11		type:#boolean	animatable:false	ui:FlowAnim_RotLeft			default:false
		FlowAnim12		type:#boolean	animatable:false	ui:FlowAnim_RotRight		default:false
		FlowAnim13		type:#boolean	animatable:false	ui:FlowAnim_ScaleUp			default:false
		FlowAnim14		type:#boolean	animatable:false	ui:FlowAnim_ScaleDown		default:false
		SqAnim_Solo1	type:#integer	animatable:false	ui:SQAnim_Solo_StartTime	default:30
		SqAnim_Solo2	type:#integer	animatable:false	ui:SQAnim_Solo_Loop			default:1
		SqAnim_Solo3	type:#integer	animatable:false	ui:SQAnim_Solo_Columns			default:2
		SqAnim_Solo4	type:#integer	animatable:false	ui:SQAnim_Solo_Rows			default:2
		SqAnim_Solo5	type:#integer	animatable:false	ui:SQAnim_Solo_StartKey		default:1
		SqAnim_Solo6	type:#integer	animatable:false	ui:SQAnim_Solo_EndKey		default:4
		SqAnim_Solo7	type:#integer	animatable:false	ui:SQAnim_Solo_Order		default:1
		SqAnim_Solo8	type:#integer	animatable:false	ui:SQAnim_Solo_Speed		default:3
		SqAnim_Solo9	type:#boolean	animatable:false	ui:SQAnim_Solo_ON			default:false
		SqAnim_Solo10	type:#boolean	animatable:false	ui:SQAnim_Solo_OFF			default:true
		SqAnim_Solo11	type:#boolean	animatable:false	ui:SQAnim_Save_ON			default:false
		SqAnim_Solo12	type:#boolean	animatable:false	ui:SQAnim_Save_OFF			default:true
		SqAnim_Solo13	type:#boolean	animatable:false	ui:SQAnim_Collapse_ON		default:true
		SqAnim_Solo14	type:#boolean	animatable:false	ui:SQAnim_Collapse_OFF		default:false
		SqAnim_Solo15	type:#integer	animatable:false	ui:SQAnim_Solo_Skinkey		default:1
		SqAnim_Many1	type:#integer	animatable:false	ui:SQAnim_Many_Order		default:1
		SqAnim_Many2	type:#integer	animatable:false	ui:SQAnim_Many_Speed		default:3
		SqAnim_Many3	type:#string	animatable:false	ui:SQAnim_Many_Path
		Wc3_W_Offset	type:#float	  animatable:true default:0.0 ui:spnWOffset
		Alpha			type:#float	  animatable:true  default:100	 ui:malpha
		
		on Alpha set val do (try(delegate.opacity = val)catch())
	)
	parameters reforged rollout:reforgedRollout
	(
		-- PBR Texture Maps (ui: binding enables drag & drop on mapbuttons)
		normal_map			type:#texturemap animatable:false ui:mb_normal
		orm_map				type:#texturemap animatable:false ui:mb_orm
		emissive_map		type:#texturemap animatable:false ui:mb_emissive
		reflection_map		type:#texturemap animatable:false ui:mb_reflection
		-- Reforged Original-Pfade (fuer Round-Trip Export)
		origNormalPath		type:#string default:"" animatable:false
		origOrmPath			type:#string default:"" animatable:false
		origEmissivePath	type:#string default:"" animatable:false
		origReflectionPath	type:#string default:"" animatable:false
		origDiffusePath		type:#string default:"" animatable:false
		-- PBR Prefix Paths (for export path construction)
		normalPrefixPath		type:#string default:"" animatable:false ui:edt_normalPath
		ormPrefixPath		type:#string default:"" animatable:false ui:edt_ormPath
		emissivePrefixPath	type:#string default:"" animatable:false ui:edt_emissivePath
		reflectionPrefixPath	type:#string default:"" animatable:false ui:edt_reflectionPath
		-- Reforged TeamColor Slot
		teamColorTexId		type:#integer default:0 animatable:false
		-- Reforged Material Parameters
		EmissiveGain		type:#float animatable:false default:1.0 ui:spn_emissiveGain
		FresnelColorR		type:#float animatable:false default:1.0 ui:spn_fresnelR
		FresnelColorG		type:#float animatable:false default:1.0 ui:spn_fresnelG
		FresnelColorB		type:#float animatable:false default:1.0 ui:spn_fresnelB
		FresnelOpacity		type:#float animatable:false default:0.0 ui:spn_fresnelOpacity
		FresnelTeamColor	type:#float animatable:false default:0.0 ui:spn_fresnelTeamColor

		-- Auto-update path strings when textures are assigned via drag & drop
		on normal_map set val do
		(
			if val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
				origNormalPath = val.fileName
			else if val == undefined then
				origNormalPath = ""
		)
		on orm_map set val do
		(
			if val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
				origOrmPath = val.fileName
			else if val == undefined then
				origOrmPath = ""
		)
		on emissive_map set val do
		(
			if val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
				origEmissivePath = val.fileName
			else if val == undefined then
				origEmissivePath = ""
		)
		on reflection_map set val do
		(
			if val != undefined and classof val == Bitmaptexture and val.fileName != undefined and val.fileName != "" then
				origReflectionPath = val.fileName
			else if val == undefined then
				origReflectionPath = ""
		)
	)
	------------------------------------------------------------------------------------
	rollout window1 "Material parameters"
	(
		global MatRolloutForMenu
		local self
		
		dotnetcontrol lbl_LOGO "System.Windows.Forms.PictureBox" width:318 height:90 align:#center pos:[4,7]
		group "Basic Parameters"
		(
			checkbox flag2 "UnShaded"        height:22 align:#left pos:[14,120]  tooltip:"In the game, it is not affected by lighting"
			checkbox flag8 "Sphere EnvMap"   height:22 align:#left pos:[107,120] enabled:false
			checkbox flag9 "Full Resolution" height:22 align:#left pos:[226,120] tooltip:"In the game, ignore the mipmap values of textures"
			checkbox flag3 "UnFogged"        height:22 align:#left pos:[14,147]  tooltip:"In the game, unaffected by the fog of war and terrain fog"
			checkbox flag4 "UnSelectable"    height:22 align:#left pos:[107,147] tooltip:"In the game, ignore the Collision Sphere and Collision Box attributes"
			checkbox flag6 "No Depth Set"    height:22 align:#left pos:[226,147] enabled:false
			checkbox flag1 "Two Sided"       height:22 align:#left pos:[14,174]
			checkbox flag7 "Constant Color"  height:22 align:#left pos:[107,174]
			checkbox flag5 "No Depth Test"   height:22 align:#left pos:[226,174] tooltip:"Ignore the distance relationship between layers, similar to placing a window at the top"

			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			label 		 lbl01 "No Depth Test Sort Order ..........." width:174 pos:[14,205] align:#left
			dropdownlist SortZ items:#("Not Used", "From near to far", "From far to near") width:122 height:20 pos:[190,201] align:#left enabled:false
			label 		 lbl51 "Priority Plane ........................................" pos:[14,231] align:#left
			spinner 	 youxian height:22 fieldwidth:59 range:[-20,20,0] type:#integer pos:[242,231] align:#left
			checkbox 	 flag15 "U_Tile(Wrap Width)" height:22 align:#left pos:[14,255] enabled:false
			checkbox 	 flag16 "V_Tile(Wrap Height)" height:22 align:#left pos:[191,255] enabled:false
			label 		 lbl05 "Replaceable Texture ................." height:22 align:#left pos:[14,287] width:174
			dropdownlist assignReplaceable items:#("Not Used", "Team Color", "Team Glow", "Cliff", "Lordaeron Tree", "Ashenvale Tree", "Barrens Tree", "Northrend Tree", "Mushroom Tree") width:122 height:20 align:#left pos:[190,284]
			label huanhang1 "" height:1 align:#center offset:[0,-1]
		)
		group "Filter Mode"
        (
            radiobuttons filterbuttons labels:#
            (
                "None",
                "Transparent",
                "Blend",
                "Additive",
                "Additive 2x",
                "Modulate",
                "Modulate 2x"
            ) 
            tooltip:#
            (
                "None",
                "Binary Transparency (Alpha Test). Alpha values from 192-255 are read as 255, all others are read as 0.",
                "Full Transparency (Alpha Blending). If multiple objects with this material are in view, you might need to adjust the material priority.",
                "Additive (Supports Alpha).\n[Background Color + Material Color]",
                "Additive 2x (Note: No functional difference from standard Additive has been found. The original plugin did not have this option, so it may be redundant).\n[Background Color + Material Color]",
                "Modulate (Multiply blend mode, does not use Alpha).\n[Background Color x Material Color / 255]",
                "Modulate 2x (Does not use Alpha).\n[Background Color x Material Color / (255 * 2)]"
            )
            columns:1 align:#left pos:[14,345] height:120
            label huanhang2 "" height:1 offset:[0,-1]
        )
		-- Hidden controls (parameter binding requires them to exist in window1)
		label 		 lbl02 "Prefix Path :" height:22 align:#left pos:[9999,0] width:70
		edittext  	 Pather				 labelOnTop:true width:175 height:20 align:#left pos:[9999,0]
		button 		 btnSelectPath  "▼" 	width:24 height:24 pos:[9999,0] tooltip:"Select prefix path"
		button 		 btnEditPath    "+"  width:24 height:24 pos:[9999,0] tooltip:"Edit shortcut prefix path"
		label 		 lbl03 "Texture File ............................" height:22 align:#left pos:[9999,0] width:174
		mapbutton 	 NeoDexTexBtn   						 width:122 height:20 align:#left pos:[9999,0]

		on Pather entered txt do
		(
			Pather.text = substituteString txt "\r" ""
			Pather.text = substituteString Pather.text "\n" ""
		)

		on btnSelectPath pressed do
		(
			MatRolloutForMenu = this
			local iniPath = GetDir #userScripts + "\\NeodexConfig\\MatPrefixPath.ini"
			if not (doesFileExist iniPath) then
			(
				setINISetting iniPath "PathMenu" "Count" "4"
				setINISetting iniPath "PathMenu" "Path1" "Textures\\\\"
				setINISetting iniPath "PathMenu" "Path2" "war3mapImported\\\\"
				setINISetting iniPath "PathMenu" "Path3" "ReplaceableTextures\\\\Shadows\\\\"
				setINISetting iniPath "PathMenu" "Path4" "ReplaceableTextures\\\\Cliff\\\\"
			)
			local PathCount = (getINISetting iniPath "PathMenu" "Count") as integer
			local code = "rcMenu pathMenu\n(\n"
			local lastMenu = "1"
			for i = 1 to PathCount do
			(
				code += "menuItem mi" + (i as string) + " \""+ (getINISetting iniPath "PathMenu" ("Path" + i as string)) + "\"\n"
				lastMenu = (i + 1) as string
			)
			code += "menuItem mi" + lastMenu + " \"" + "(Clear)" + "\"\n"
			for i = 1 to PathCount do
			(
				local tempstr = getINISetting iniPath "PathMenu" ("Path" + i as string)
				code += "on mi" + (i as string) + " picked do (\nMatRolloutForMenu.window1.Pather.text = \"" + tempstr + "\"\nMatRolloutForMenu.path = \"" + tempstr + "\"\n)\n"
			)
			code += "on mi" + lastMenu + " picked do (\nMatRolloutForMenu.window1.Pather.text = \"\"\nMatRolloutForMenu.path = \"\"\n)\n"
			code += ")\npopUpMenu pathMenu pos:mouse.screenpos"
			execute code
		)
		on btnEditPath pressed do
		(
			local processClass		  = dotNetClass "System.Diagnostics.Process"
			local startInfo			  = dotNetObject "System.Diagnostics.ProcessStartInfo"
			startInfo.FileName		  = "notepad.exe"
			startInfo.Arguments		  = GetDir #userScripts + "\\NeodexConfig\\MatPrefixPath.ini"
			startInfo.UseShellExecute = true
			process					  = processClass.Start(startInfo)
		)

		on window1 open do
		(
			self = this
			
			lbl_LOGO.image = LoadImageForPreview (Icon_Path + "Warcraft_Material.png")
			lbl_LOGO.sizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage


			---------------------------------------------------------------------------------------
			if NoDephTest do (SortZ.enabled = true)
			if (filtermode == 1) or (filtermode == 2) then () else (flag6.enabled = true)
			local SelMattmp = medit.GetCurMtl()
			local Mat_obj = for o in objects where o.material == SelMattmp collect o
			if Mat_obj.count > 0 then
			(
				(
					local tmp = getUserProp Mat_obj[1] "Unselectable"
					if tmp == 1 then this.unselectable = true else this.unselectable = false
				)
			)else(flag4.checked = false)
			
			if (classof this.texture == Bitmaptexture) then
			(
				flag8.enabled  = true
				flag15.enabled = true
				flag16.enabled = true
			)else
			(
				flag8.enabled  = false
				flag15.enabled = false
				flag16.enabled = false
			)
			try (local tmp = this.texture.coords.mappingType) catch (local tmp = 0)
			if (tmp == 1) then (flag8.checked = true) else (flag8.checked = false)
			try (tmp = this.texture.coords.U_Tile) catch (tmp = false)
			if (tmp) then (flag15.checked = true) else (flag15.checked = false)
			try (tmp = this.texture.coords.V_Tile) catch (tmp = false)
			if (tmp) then (flag16.checked = true) else (flag16.checked = false)
			-- Der Grund für zwei try-Blöcke ist, dass bei gleichen/duplizierten keys ein Fehler geworfen werden kann und die Ausführung abbricht. Würde alles in einem einzigen try stehen, würde der Wert von V nicht geladen.

			-- Localization
			if ::L != undefined then
			(
				window1.title = ::L.t "mat_material_parameters_title"
				-- Checkbox texts
				flag2.text = ::L.t "mat_unshaded_chk"
				flag8.text = ::L.t "mat_sphere_envmap_chk"
				flag9.text = ::L.t "mat_full_resolution_chk"
				flag3.text = ::L.t "mat_unfogged_chk"
				flag4.text = ::L.t "mat_unselectable_chk"
				flag6.text = ::L.t "mat_no_depth_set_chk"
				flag1.text = ::L.t "mat_two_sided_chk"
				flag7.text = ::L.t "mat_constant_color_chk"
				flag5.text = ::L.t "mat_no_depth_test_chk"
				flag15.text = ::L.t "mat_utilewrap_width_chk"
				flag16.text = ::L.t "mat_vtilewrap_height_chk"
				-- Checkbox tooltips
				flag2.tooltip = ::L.t "mat_in_the_game_it_is_not_affecte_tip"
				flag9.tooltip = ::L.t "mat_in_the_game_ignore_the_mipmap_tip"
				flag3.tooltip = ::L.t "mat_in_the_game_unaffected_by_the_tip"
				flag4.tooltip = ::L.t "mat_in_the_game_ignore_the_collis_tip"
				flag5.tooltip = ::L.t "mat_ignore_the_distance_relationsh_tip"
				-- Labels
				lbl01.text = ::L.t "mat_no_depth_test_sort_order_lbl"
				lbl51.text = ::L.t "mat_priority_plane_lbl"
				lbl02.text = ::L.t "mat_prefix_path_lbl"
				lbl03.text = ::L.t "mat_texture_file_lbl"
				lbl05.text = ::L.t "mat_replaceable_texture_lbl"
				-- Controller button tooltips
				btnSelectPath.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnEditPath.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
			)
		)
	)
	rollout window2 "Animation generation" height:455
	(
		-- ==================== Controller Options ====================
		spinner 	 malpha "Opacity :" height:22 fieldwidth:59 range:[0,100,100] pos:[14,8] align:#left
		checkbutton bnt_opacity_Instant_con tooltip:"Instant Controller" pos:[220,4] width:20 height:20 highlightColor:(color 155 35 35)
		checkbutton bnt_opacity_linear_con  tooltip:"Linear Controller"  pos:[244,4] width:20 height:20 highlightColor:(color 155 35 35)
		checkbutton bnt_opacity_bezier_con  tooltip:"Bezier Controller"  pos:[268,4] width:20 height:20 highlightColor:(color 155 35 35)
		checkbutton bnt_opacity_hermite_con tooltip:"Hermite Controller" pos:[292,4] width:20 height:20 highlightColor:(color 155 35 35)
		label 		 lbl53 "Texture Anim Controller ..........." height:22 align:#left pos:[14,36] width:174
		checkbutton btn_tex_anim_instant height:20 width:25 pos:[190,33] tooltip:"Instant Controller" highlightColor:(color 155 35 35)
		checkbutton btn_tex_anim_linear  height:20 width:25 pos:[222,33] tooltip:"Linear Controller" highlightColor:(color 155 35 35)
		checkbutton btn_tex_anim_bezier  height:20 width:25 pos:[255,33] tooltip:"Bezier Controller" highlightColor:(color 155 35 35)
		checkbutton btn_tex_anim_hermite height:20 width:25 pos:[287,33] tooltip:"Hermite Controller" highlightColor:(color 155 35 35)
		label 		 lblWOffset "W Offset ................................" height:22 align:#left pos:[14,62] width:174
		spinner 	 spnWOffset "" range:[-9999,9999,0] type:#float scale:0.01 width:122 align:#left pos:[190,60]
		-- ==================== UI Controls ====================
		checkbutton chk_LDDH	  "Flow Anim"	   align:#left pos:[14,90]  width:94 height:22 tooltip:"The water effect of the reference waterfall"	  highlightColor:(color 176 97 19) checked:false
		checkbutton chk_XLDH_Solo "SEQ Anim(Solo)" align:#left pos:[116,90]  width:94 height:22 tooltip:"Reference hit effect sequence"	   highlightColor:(color 51 131 65)   checked:true
		checkbutton chk_XLDH_Many "SEQ Anim(Many)" align:#left pos:[218,90]  width:94 height:22 tooltip:"Refer to the texture of Genshin Impact in Warcraft III"  highlightColor:(color 10 130 144) checked:false
		-- Flow Anim panel
		groupbox G1 width:317 height:180 pos:[999,34]
		groupbox G4 width:317 height:38	 pos:[999,214]
		HyperLink		l65			"Start time:"	  align:#left pos:[999,50]	width:65	  height:18 color:(color 255 165 86) enabled:false
		spinner			FlowAnim_StartTime		 align:#left pos:[999,50]   fieldwidth:50 height:18 range:[0,1e+008,0] type:#integer
		HyperLink 		l66			"End Time:"	  align:#left pos:[999,50]	width:65	  height:18 color:(color 255 165 86) enabled:false
		spinner			FlowAnim_EndTime		 align:#left pos:[999,50]  fieldwidth:50 height:18 range:[1,1e+008,30] type:#integer
		HyperLink		l67			"Direction ....................................." align:#left pos:[999,77]	width:200	height:18 color:(color 255 165 86) enabled:false
		checkbutton		FlowAnim_Up		"↑" align:#left pos:[999,77]	width:20 height:20 highlightColor:(color 155 35 35) checked:false
		checkbutton		FlowAnim_Down	"↓" align:#left pos:[999,77]	width:20 height:20 highlightColor:(color 155 35 35) checked:false
		checkbutton		FlowAnim_Left	"←" align:#left pos:[999,77]	width:20 height:20 highlightColor:(color 155 35 35) checked:false
		checkbutton		FlowAnim_Right	"→" align:#left pos:[999,77]	width:20 height:20 highlightColor:(color 155 35 35) checked:false
		HyperLink		l78			"Rotation ......................................." align:#left pos:[999,104]	width:200	height:18 color:(color 255 165 86) enabled:false
		checkbutton		FlowAnim_RotLeft	"↺" align:#left pos:[999,104]	width:30 height:20 highlightColor:(color 155 35 35) checked:false tooltip:"Rotate Left (Counter-Clockwise)"
		checkbutton		FlowAnim_RotRight	"↻" align:#left pos:[999,104]	width:30 height:20 highlightColor:(color 155 35 35) checked:false tooltip:"Rotate Right (Clockwise)"
		HyperLink		l79			"Scaling ........................................" align:#left pos:[999,131]	width:200	height:18 color:(color 255 165 86) enabled:false
		checkbutton		FlowAnim_ScaleUp	"+" align:#left pos:[999,131]	width:30 height:20 highlightColor:(color 155 35 35) checked:false tooltip:"Scale Up (Larger)"
		checkbutton		FlowAnim_ScaleDown	"-" align:#left pos:[999,131]	width:30 height:20 highlightColor:(color 155 35 35) checked:false tooltip:"Scale Down (Smaller)"
		label			l68			"Anim Keys: 30 F"	align:#left pos:[999,177]	width:100		   height:18 
		label			l74			"Anim Time: 1.0 S"	align:#left pos:[999,177]	width:160		   height:18 
		HyperLink		l69			"Global Animation ....................." align:#left pos:[999,158]	width:200	height:18 color:(color 255 165 86) enabled:false
		checkbutton		FlowAnim_ON		"ON"  height:20 width:52 pos:[999,158]	highlightColor:(color 76 141 0)	 checked:false
		checkbutton		FlowAnim_OFF	"OFF" height:20 width:52 pos:[999,158]	highlightColor:(color 144 34 34) checked:true
		HyperLink		l70			"Keep Existing Animation ................."	 align:#left pos:[999,185]	width:200	height:18 color:(color 255 165 86) enabled:false
		checkbutton		FlowAnim_Save_ON	"ON"  height:20 width:52 pos:[999,185]	highlightColor:(color 76 141 0)	 checked:false
		checkbutton		FlowAnim_Save_OFF	"OFF" height:20 width:52 pos:[999,185]	highlightColor:(color 144 34 34) checked:true
		-- SEQ Solo panel
		groupbox G2 width:317 height:231 pos:[999,34]
		groupbox G3 width:317 height:72  pos:[999,265]
		HyperLink l55			"Start time:"	  align:#left pos:[999,50]	width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_StartTime		 pos:[999,50]   fieldwidth:50 height:18 range:[0,1e+008,0] type:#integer
		HyperLink l56			"Loop:"	  align:#left pos:[999,50]	width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_Loop			 pos:[999,50]  fieldwidth:50 height:18 range:[1,10,1] type:#integer
		HyperLink l57			"Columns:"	  align:#left pos:[999,77]	width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_Columns			 pos:[999,77]   fieldwidth:50 height:18 range:[1,16,2] type:#integer
		HyperLink l58			"Rows:"	  align:#left pos:[999,77]	width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_Rows			 pos:[999,77]  fieldwidth:50 height:18 range:[1,16,2] type:#integer
		HyperLink l59			"Start Key:" align:#left pos:[999,104]	width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_StartKey		 pos:[999,104]  fieldwidth:50 height:18 range:[1,128,1] type:#integer
		HyperLink l60			"End Key:" align:#left pos:[999,104] width:65	  height:18 color:(color 106 225 127) enabled:false
		spinner   SQAnim_Solo_EndKey		 pos:[999,104] fieldwidth:50 height:18 range:[1,128,4] type:#integer
		HyperLink l80			"Frame Skipping ............................" align:#left pos:[999,131]	width:200	height:18 color:(color 106 225 127) enabled:false
		dropdownlist SQAnim_Solo_Skinkey "" items:#("0f", "1f", "2f", "3f", "4f", "5f", "6f", "7f", "8f")	 width:108 height:20 pos:[999,131]
		HyperLink l61			"Play Order .................................." align:#left pos:[999,158]	width:200	height:18 color:(color 106 225 127) enabled:false
		dropdownlist SQAnim_Solo_Order "" items:#("Forward Play", "Reverse Play")							 width:108 height:20 pos:[999,158]
		HyperLink l62			"Play Speed .................................." align:#left pos:[999,185]	width:200	height:18 color:(color 106 225 127) enabled:false
		dropdownlist SQAnim_Solo_Speed "" items:#("10F/S", "15F/S", "30F/S", "60F/S")	width:108 height:20 pos:[999,185]
		HyperLink l63			"Global Animation ..................." align:#left pos:[999,212]	width:200	height:18 color:(color 106 225 127) enabled:false
		checkbutton	SQAnim_Solo_ON	"ON"  height:20 width:52 pos:[999,212]	highlightColor:(color 76 141 0)	 checked:false
		checkbutton	SQAnim_Solo_OFF	"OFF" height:20 width:52 pos:[999,212]	highlightColor:(color 144 34 34) checked:true
		HyperLink l64			"Keep Existing Animation ..............." align:#left pos:[999,239]	width:200	height:18 color:(color 106 225 127) enabled:false
		checkbutton	SQAnim_Save_ON	"ON"  height:20 width:52 pos:[999,239]	highlightColor:(color 76 141 0)	 checked:false
		checkbutton	SQAnim_Save_OFF	"OFF" height:20 width:52 pos:[999,239]	highlightColor:(color 144 34 34) checked:true
		button	  btn_Model		"Generate UV Map" width:298 height:24 pos:[999,279]
		HyperLink l73			"Collapse modifier ................" align:#left pos:[999,310]	width:200	height:18 color:(color 106 225 127) enabled:false
		checkbutton	SQAnim_Collapse_ON	"ON"  height:20 width:52 pos:[999,310]	highlightColor:(color 76 141 0)	 checked:true
		checkbutton	SQAnim_Collapse_OFF	"OFF" height:20 width:52 pos:[999,310]	highlightColor:(color 144 34 34) checked:false
		-- SEQ Many panel
		groupbox G5 width:317 height:100 pos:[999,34]
		groupbox G6 width:317 height:58 pos:[999,134]
		groupbox G7 width:317 height:38 pos:[999,192]
		HyperLink l71				"Play Order .................................." align:#left  pos:[999,50]  width:200	height:18 color:(color 85 204 217) enabled:false
		dropdownlist SQAnim_Many_Order items:#("Forward Play", "Reverse Play")						    pos:[999,50]  width:108	 height:20
		HyperLink l72				"Play Speed .................................." align:#left  pos:[999,77]	 width:200	height:18 color:(color 85 204 217) enabled:false
		dropdownlist SQAnim_Many_Speed items:#("10F/S", "15F/S", "30F/S") pos:[999,77]	 width:108	height:20
		HyperLink l_pbrate			"Playback Rate ..............................." align:#left pos:[999,104] width:200 height:18 color:(color 85 204 217) enabled:false
		spinner   SQAnim_Many_PlaybackRate "" 													pos:[999,104] width:108 height:18 range:[0.01,10.0,1.0] type:#float scale:0.01
		HyperLink l75				"Sequence frame folder path:"		   align:#left  pos:[999,124] width:200	 height:18 color:(color 85 204 217) enabled:false
		edittext  SQAnim_Many_Path															   pos:[999,141] width:267	 height:20
		button	  SQAnim_Many_btn	"..."													   pos:[999,141] width:30	height:20
		label	  l76				"Anim Keys: 0 F"	align:#left pos:[999,180]	width:100		   height:18 
		label	  l77				"Anim Time: 0.0 S"	align:#left pos:[999,180]	width:160		   height:18 
		-- Generate button
		button btn_Generate "Start of production" width:317 height:24 pos:[4,425]

		-- ==================== Layout Helper Functions ====================
		-- Hidden position constant
		local hiddenPos = [999,999]
		
		-- Repositions an array of [control, position] pairs
		fn applyLayout layoutPairs =
		(
			for pair in layoutPairs do pair[1].pos = pair[2]
		)
		
		-- Hides all three sub-panels by moving them offscreen
		fn hideAllPanels =
		(
			local allControls = #(
				G1, G2, G3, G4, G5, G6, G7,
				l55, l56, l57, l58, l59, l60, l61, l62, l63, l64,
				l65, l66, l67, l68, l69, l70, l71, l72, l73, l74, l75, l76, l77,
				l78, l79, l80, l_pbrate,
				FlowAnim_StartTime, FlowAnim_EndTime,
				FlowAnim_Up, FlowAnim_Down, FlowAnim_Left, FlowAnim_Right,
				FlowAnim_RotLeft, FlowAnim_RotRight,
				FlowAnim_ScaleUp, FlowAnim_ScaleDown,
				FlowAnim_ON, FlowAnim_OFF,
				FlowAnim_Save_ON, FlowAnim_Save_OFF,
				SQAnim_Solo_StartTime, SQAnim_Solo_Loop,
				SQAnim_Solo_Columns, SQAnim_Solo_Rows,
				SQAnim_Solo_StartKey, SQAnim_Solo_EndKey,
				SQAnim_Solo_Skinkey, SQAnim_Solo_Order, SQAnim_Solo_Speed,
				SQAnim_Solo_ON, SQAnim_Solo_OFF,
				SQAnim_Save_ON, SQAnim_Save_OFF,
				btn_Model, SQAnim_Collapse_ON, SQAnim_Collapse_OFF,
				SQAnim_Many_Order, SQAnim_Many_Speed,
				SQAnim_Many_PlaybackRate, SQAnim_Many_Path, SQAnim_Many_btn
			)
			for ctrl in allControls do ctrl.pos = hiddenPos
		)
		
		-- Shows the Flow Animation sub-panel with proper positions
		fn showFlowPanel =
		(
			applyLayout #(
				#(G1, [4,116]),        #(G4, [4,296]),
				#(l65, [14,132]),      #(FlowAnim_StartTime, [139,132]),
				#(l66, [176,132]),     #(FlowAnim_EndTime, [301,132]),
				#(l67, [14,159]),
				#(FlowAnim_Up, [204,159]),    #(FlowAnim_Down, [233,159]),
				#(FlowAnim_Left, [263,159]),  #(FlowAnim_Right, [292,159]),
				#(l78, [14,186]),
				#(FlowAnim_RotLeft, [204,186]),  #(FlowAnim_RotRight, [244,186]),
				#(l79, [14,213]),
				#(FlowAnim_ScaleUp, [204,213]),  #(FlowAnim_ScaleDown, [244,213]),
				#(l69, [14,240]),
				#(FlowAnim_ON, [204,240]),   #(FlowAnim_OFF, [260,240]),
				#(l70, [14,267]),
				#(FlowAnim_Save_ON, [204,267]), #(FlowAnim_Save_OFF, [260,267]),
				#(l68, [14,313]),    #(l74, [157,313])
			)
			FlowAnim_StartTime.enabled = not FlowAnim_ON.checked
		)
		
		-- Shows the SEQ Solo sub-panel with proper positions
		fn showSeqSoloPanel =
		(
			applyLayout #(
				#(G2, [4,116]),        #(G3, [4,347]),
				#(l55, [14,132]),      #(SQAnim_Solo_StartTime, [139,132]),
				#(l56, [176,132]),     #(SQAnim_Solo_Loop, [301,132]),
				#(l57, [14,159]),      #(SQAnim_Solo_Columns, [139,159]),
				#(l58, [176,159]),     #(SQAnim_Solo_Rows, [301,159]),
				#(l59, [14,186]),     #(SQAnim_Solo_StartKey, [139,186]),
				#(l60, [176,186]),    #(SQAnim_Solo_EndKey, [301,186]),
				#(l80, [14,213]),     #(SQAnim_Solo_Skinkey, [204,213]),
				#(l61, [14,240]),     #(SQAnim_Solo_Order, [204,240]),
				#(l62, [14,267]),     #(SQAnim_Solo_Speed, [204,267]),
				#(l63, [14,294]),
				#(SQAnim_Solo_ON, [204,294]),  #(SQAnim_Solo_OFF, [260,294]),
				#(l64, [14,321]),
				#(SQAnim_Save_ON, [204,321]), #(SQAnim_Save_OFF, [260,321]),
				#(btn_Model, [14,361]),
				#(l73, [14,392]),
				#(SQAnim_Collapse_ON, [204,392]), #(SQAnim_Collapse_OFF, [260,392])
			)
			SQAnim_Solo_StartTime.enabled = not SQAnim_Solo_ON.checked
		)
		
		-- Shows the SEQ Many sub-panel with proper positions
		fn showSeqManyPanel =
		(
			applyLayout #(
				#(G5, [4,116]),         #(G6, [4,216]),       #(G7, [4,274]),
				#(l71, [14,132]),        #(SQAnim_Many_Order, [204,132]),
				#(l72, [14,159]),        #(SQAnim_Many_Speed, [204,159]),
				#(l_pbrate, [14,186]),  #(SQAnim_Many_PlaybackRate, [300,186]),
				#(l75, [14,228]),
				#(SQAnim_Many_Path, [14,245]), #(SQAnim_Many_btn, [282,245]),
				#(l76, [14,289]),       #(l77, [157,289])
			)
			try ( SQAnim_Many_PlaybackRate.value = if this.texture != undefined then this.texture.playbackRate else 1.0 ) catch()
		)
		
		-- Activates one of the three modes and shows the corresponding panel
		fn activateMode modeIndex =
		(
			chk_LDDH.checked      = (modeIndex == 1)
			chk_XLDH_Solo.checked = (modeIndex == 2)
			chk_XLDH_Many.checked = (modeIndex == 3)
			hideAllPanels()
			case modeIndex of
			(
				1: showFlowPanel()
				2: showSeqSoloPanel()
				3: showSeqManyPanel()
			)
		)

		-- ==================== Mutual Exclusion Helpers ====================
		-- Ensures two checkbuttons act as a radio pair
		fn enforceTogglePair btnOn btnOff state =
		(
			btnOn.checked = state
			btnOff.checked = not state
		)

		-- ==================== Animation Generation Functions ====================
		
		-- Purges existing keyframes on a controller and inserts a single key at frame 0
		fn resetControllerKeys ctrl initialVal =
		(
			if ctrl != undefined do
			(
				deleteKeys ctrl #allKeys
				local k = addNewKey ctrl 0
				k.value = initialVal
			)
		)

		-- Generates Flow (scrolling/rotating/scaling) texture animation
		fn generateFlowAnimation =
		(
			-- Require at least one transform to be selected
			local hasDirection = (FlowAnim_Up.checked or FlowAnim_Down.checked or FlowAnim_Left.checked or FlowAnim_Right.checked)
			local hasRotation  = (FlowAnim_RotLeft.checked or FlowAnim_RotRight.checked)
			local hasScale     = (FlowAnim_ScaleUp.checked or FlowAnim_ScaleDown.checked)
			if not hasDirection and not hasRotation and not hasScale do
			(
				messagebox "Please select at least one direction, rotation or scaling option!" title:MessageboxTitle
				return false
			)
			
			-- Enable wrapping based on scroll direction
			if (FlowAnim_Left.checked or FlowAnim_Right.checked) do 
			(
				this.Wrap_Width = true
				this.texture.coords.U_Tile = true
			)
			if (FlowAnim_Up.checked or FlowAnim_Down.checked) do 
			(
				this.Wrap_Height = true
				this.texture.coords.V_Tile = true
			)
			
			-- Assign linear controllers for offset channels
			this.texture.coords.U_Offset.controller = Linear_float()
			this.texture.coords.V_Offset.controller = Linear_float()
			
			-- Create rotation controller if rotation is requested
			local needsRotation = (FlowAnim_RotLeft.checked or FlowAnim_RotRight.checked)
			if needsRotation do
				this.texture.coords.W_Angle.controller = Linear_float()
			
			-- Create scale controllers if scaling is requested
			local needsScale = (FlowAnim_ScaleUp.checked or FlowAnim_ScaleDown.checked)
			if needsScale do
			(
				this.texture.coords.U_Tiling.controller = Linear_float()
				this.texture.coords.V_Tiling.controller = Linear_float()
			)
			
			-- Optionally clear old keys and set initial values at frame 0
			if FlowAnim_Save_OFF.checked or FlowAnim_ON.checked then
			(
				resetControllerKeys this.texture.coords.U_Offset.controller 0.0
				resetControllerKeys this.texture.coords.V_Offset.controller 0.0
				if needsRotation do
					try ( resetControllerKeys this.texture.coords.W_Angle.controller 0.0 ) catch()
				if needsScale do
				(
					try ( resetControllerKeys this.texture.coords.U_Tiling.controller 1.0 ) catch()
					try ( resetControllerKeys this.texture.coords.V_Tiling.controller 1.0 ) catch()
				)
			)
			
			-- Set ORT to constant (will change to cycle if global anim is on)
			setAfterORT this.texture.coordinates.U_Offset.controller #constant
			setAfterORT this.texture.coordinates.V_Offset.controller #constant
			try ( if needsRotation do setAfterORT this.texture.coords.W_Angle.controller #constant ) catch()
			try ( if needsScale do (setAfterORT this.texture.coords.U_Tiling.controller #constant; setAfterORT this.texture.coords.V_Tiling.controller #constant) ) catch()
			
			-- Compute target values based on direction/rotation/scale
			local targetU = 0.0
			local targetV = 0.0
			if FlowAnim_Up.checked    do targetV =  1.0
			if FlowAnim_Down.checked  do targetV = -1.0
			if FlowAnim_Left.checked  do targetU = -1.0
			if FlowAnim_Right.checked do targetU =  1.0
			
			local targetAngle = 0.0
			if FlowAnim_RotLeft.checked  do targetAngle = -360.0
			if FlowAnim_RotRight.checked do targetAngle =  360.0
			
			local targetScaleU = 1.0
			local targetScaleV = 1.0
			if FlowAnim_ScaleUp.checked   do ( targetScaleU = 2.0; targetScaleV = 2.0 )
			if FlowAnim_ScaleDown.checked do ( targetScaleU = 0.5; targetScaleV = 0.5 )
			
			-- Helper: writes all channel values at a given time
			fn writeFlowKeyframe theTime uVal vVal angleVal scaleU scaleV doRot doScale theMat =
			(
				at time theTime
				(
					theMat.texture.coordinates.U_Offset = uVal
					theMat.texture.coordinates.V_Offset = vVal
					if doRot do theMat.texture.coords.W_Angle = angleVal
					if doScale do ( theMat.texture.coords.U_Tiling = scaleU; theMat.texture.coords.V_Tiling = scaleV )
				)
			)
			
			-- Generate keyframes
			local useGlobal = FlowAnim_ON.checked
			animate on 
			(
				if not useGlobal then
				(
					-- Non-global: key at start and end times
					writeFlowKeyframe FlowAnim_StartTime.value 0.0 0.0 0.0 1.0 1.0 needsRotation needsScale this
					writeFlowKeyframe FlowAnim_EndTime.value targetU targetV targetAngle targetScaleU targetScaleV needsRotation needsScale this
				)
				else
				(
					-- Global animation: key only at computed duration, then cycle
					local dur = FlowAnim_EndTime.value
					writeFlowKeyframe dur targetU targetV targetAngle targetScaleU targetScaleV needsRotation needsScale this
					setAfterORT this.texture.coordinates.U_Offset.controller #cycle
					setAfterORT this.texture.coordinates.V_Offset.controller #cycle
					try ( if needsRotation do setAfterORT this.texture.coords.W_Angle.controller #cycle ) catch()
					try ( if needsScale do (setAfterORT this.texture.coords.U_Tiling.controller #cycle; setAfterORT this.texture.coords.V_Tiling.controller #cycle) ) catch()
				)
			)
			materialControllersUpdate()
		)
		
		-- Generates SEQ Solo (single spritesheet) animation
		fn generateSeqSoloAnimation =
		(
			local colCount  = SQAnim_Solo_Columns.value
			local rowCount  = SQAnim_Solo_Rows.value
			local totalCells = colCount * rowCount
			local cellW = 1.0 / colCount
			local cellH = 1.0 / rowCount

			-- Compute time step from speed selection
			local timeStep = case SQAnim_Solo_Speed.selection of
			(
				1: 3.0;  2: 2.0;  3: 1.0;  4: 0.5
			)

			-- Assign bezier controllers for step interpolation
			this.texture.coords.U_Offset.controller = Bezier_float()
			this.texture.coords.V_Offset.controller = Bezier_float()

			-- Clear existing keys if requested
			if SQAnim_Save_OFF.checked or SQAnim_Solo_ON.checked then
			(
				resetControllerKeys this.texture.coords.U_Offset.controller 0.0
				resetControllerKeys this.texture.coords.V_Offset.controller 0.0
			)
			setAfterORT this.texture.coordinates.U_Offset.controller #constant
			setAfterORT this.texture.coordinates.V_Offset.controller #constant

			-- Step 1: Build UV data for every cell in reading order (left-to-right, top-to-bottom)
			struct CellUV (cellIndex, uOff, vOff)
			local cellTable = #()
			local uAccum = cellW  -- will subtract first so first cell = 0
			local vAccum = 0.0 - cellH
			for row = 1 to rowCount do
			(
				vAccum += cellH
				for col = 1 to colCount do
				(
					uAccum -= cellW
					append cellTable (CellUV cellIndex:(cellTable.count + 1) uOff:uAccum vOff:vAccum)
				)
				uAccum = cellW
			)

			-- Step 2: Trim to user-defined key range
			local firstKey = amax 1 SQAnim_Solo_StartKey.value
			local lastKey  = amin totalCells SQAnim_Solo_EndKey.value
			if firstKey > lastKey do
			(
				messageBox "Start key cannot be greater than end key!" title:"Error"
				return false
			)
			local rangedCells = for idx = firstKey to lastKey collect cellTable[idx]

			-- Step 3: Apply frame skipping
			local skipInterval = SQAnim_Solo_Skinkey.selection
			local filteredCells = for idx = 1 to rangedCells.count where (mod (idx - 1) skipInterval) == 0 collect rangedCells[idx]
			if filteredCells.count == 0 do
			(
				messageBox "Frame skipping resulted in no valid frames!\nPlease adjust the skip or range settings." title:"Warning"
				return false
			)

			-- Step 4: Assign timing to each surviving cell
			-- Timing starts at (StartTime - 1) and increments BEFORE each use,
			-- matching the original's seq_key pattern: first frame = StartTime - 1 + step
			struct TimedFrame (t, u, v)
			local timedData = #()
			local currentTime = SQAnim_Solo_StartTime.value - 1
			for cell in filteredCells do
			(
				currentTime += timeStep
				append timedData (TimedFrame t:currentTime u:cell.uOff v:cell.vOff)
			)

			-- Step 5: Handle reverse playback (swap time assignments)
			if SQAnim_Solo_Order.selection == 2 do
			(
				local timeSlots = for item in timedData collect item.t
				local reversedData = #()
				for idx = 1 to timedData.count do
				(
					local srcIdx = timedData.count + 1 - idx
					append reversedData (TimedFrame t:timeSlots[idx] u:timedData[srcIdx].u v:timedData[srcIdx].v)
				)
				timedData = reversedData
			)

			-- Step 6: Write keyframes, handling loops
			local loopCount = SQAnim_Solo_Loop.value
			local useGlobal = SQAnim_Solo_ON.checked
			local frameDuration = (timedData[timedData.count].t - timedData[1].t) + timeStep

			-- Helper to write one pass of keys
			fn writeSeqPass frameList timeOffset isGlobal baseMat =
			(
				animate on
				(
					for fr in frameList do
					(
						local keyTime = if isGlobal then (fr.t - frameList[1].t + timeOffset) else (fr.t + timeOffset)
						at time keyTime
						(
							baseMat.texture.coordinates.U_Offset = fr.u
							baseMat.texture.coordinates.V_Offset = fr.v
						)
					)
				)
			)

			-- First pass (loop 1)
			writeSeqPass timedData 0 useGlobal this

			-- Additional loop passes
			if loopCount > 1 do
			(
				for loopIdx = 1 to (loopCount - 1) do
					writeSeqPass timedData (frameDuration * loopIdx) useGlobal this
			)

			-- Set ORT to cycle if global animation is active
			if useGlobal do
			(
				setAfterORT this.texture.coordinates.U_Offset.controller #cycle
				setAfterORT this.texture.coordinates.V_Offset.controller #cycle
			)

			-- Apply step tangents so sprites switch instantly
			local uKeys = this.texture.coordinates.U_Offset.controller.keys
			local vKeys = this.texture.coordinates.V_Offset.controller.keys
			for idx = 1 to uKeys.count do
			(
				uKeys[idx].inTangentType  = #step
				uKeys[idx].outTangentType = #step
				vKeys[idx].inTangentType  = #step
				vKeys[idx].outTangentType = #step
			)

			-- Reset cached UV values so rollout refreshes correctly next time
			try
			(
				this.Wc3_U_offset.controller.keys = #()
				this.Wc3_U_offset.controller       = undefined
				this.Wc3_V_offset.controller.keys = #()
				this.Wc3_V_offset.controller       = undefined
			) catch ()
		)
		
		-- Generates SEQ Many (multi-file IFL) animation
		fn generateSeqManyAnimation =
		(
			local folderPath = SQAnim_Many_Path.text
			-- Remove any pre-existing IFL files in the target folder
			for existingIFL in (getFiles (folderPath + "\\*.ifl")) do deletefile existingIFL
			
			local imageFiles = getFiles (folderPath + "\\*.*")
			local isReverse = (SQAnim_Many_Order.selection == 2)
			
			-- Build ordered file list and determine IFL filename
			local orderedFiles
			local iflName
			if isReverse then
			(
				iflName = "\\" + (getFilenameFile folderPath) + "_Reverse.ifl"
				orderedFiles = for idx = imageFiles.count to 1 by -1 collect imageFiles[idx]
			)
			else
			(
				iflName = "\\" + (getFilenameFile folderPath) + "_Forward.ifl"
				orderedFiles = imageFiles
			)
			
			-- Write each filename into the IFL
			local iflFullPath = folderPath + iflName
			for imgFile in orderedFiles do format_txt iflFullPath (filenameFromPath imgFile)
			
			-- Assign the IFL as the material's texture
			this.texture = Bitmaptexture fileName:iflFullPath
			this.texture.playbackRate = SQAnim_Many_PlaybackRate.value
		)

		-- ==================== Event Handlers ====================
		on btn_Model pressed do
		(
			undo on
			(
				local selObjects = selection as array
				if selObjects.count == 0 do
				(
					messagebox (MessageboxText5 + "    ") title:MessageboxTitle
					return()
				)
				local shouldCollapse = SQAnim_Collapse_ON.checked
				for obj in selObjects do
				(
					if shouldCollapse then
					(
						addModifier obj (UVW_Xform()) before:obj.modifiers.count
						local modIdx = obj.modifiers.count
						obj.modifiers[modIdx].U_Tile = 1.0 / SQAnim_Solo_Columns.value
						obj.modifiers[modIdx].V_Tile = 1.0 / SQAnim_Solo_Rows.value
						obj.modifiers[modIdx].V_Offset = obj.modifiers[modIdx].V_Tile * (SQAnim_Solo_Rows.value - 1)
						maxOps.CollapseNodeTo obj modIdx off
					)
					else
					(
						addModifier obj (UVW_Xform())
						obj.modifiers[1].U_Tile = 1.0 / SQAnim_Solo_Columns.value
						obj.modifiers[1].V_Tile = 1.0 / SQAnim_Solo_Rows.value
						obj.modifiers[1].V_Offset = obj.modifiers[1].V_Tile * (SQAnim_Solo_Rows.value - 1)
					)
				)
			)
		)
		
		-- Spinner constraints
		on FlowAnim_StartTime changed state do
		(
			if FlowAnim_EndTime.value <= FlowAnim_StartTime.value do
				FlowAnim_EndTime.value = FlowAnim_StartTime.value + 1
			RefreshTATime 1
		)
		on FlowAnim_EndTime changed state do
		(
			if FlowAnim_StartTime.value >= FlowAnim_EndTime.value do
				FlowAnim_StartTime.value = FlowAnim_EndTime.value - 1
			RefreshTATime 1
		)
		
		-- Collapse modifier toggle
		on SQAnim_Collapse_ON changed state  do enforceTogglePair SQAnim_Collapse_ON SQAnim_Collapse_OFF true
		on SQAnim_Collapse_OFF changed state do enforceTogglePair SQAnim_Collapse_ON SQAnim_Collapse_OFF false
		
		-- Direction mutual exclusion
		on FlowAnim_Up changed state    do (FlowAnim_Down.checked = false)
		on FlowAnim_Down changed state  do (FlowAnim_Up.checked = false)
		on FlowAnim_Left changed state  do (FlowAnim_Right.checked = false)
		on FlowAnim_Right changed state do (FlowAnim_Left.checked = false)
		on FlowAnim_RotLeft changed state  do (FlowAnim_RotRight.checked = false)
		on FlowAnim_RotRight changed state do (FlowAnim_RotLeft.checked = false)
		on FlowAnim_ScaleUp changed state   do (FlowAnim_ScaleDown.checked = false)
		on FlowAnim_ScaleDown changed state do (FlowAnim_ScaleUp.checked = false)
		
		-- Mode tab switching
		on chk_LDDH changed state      do activateMode 1
		on chk_XLDH_Solo changed state  do activateMode 2
		on chk_XLDH_Many changed state  do activateMode 3
		
		-- Flow Anim save/global toggles
		on FlowAnim_Save_ON changed state  do enforceTogglePair FlowAnim_Save_ON FlowAnim_Save_OFF true
		on FlowAnim_Save_OFF changed state do enforceTogglePair FlowAnim_Save_ON FlowAnim_Save_OFF false
		on FlowAnim_ON changed state do
		(
			enforceTogglePair FlowAnim_ON FlowAnim_OFF true
			FlowAnim_StartTime.enabled = false
			RefreshTATime 1
		)
		on FlowAnim_OFF changed state do
		(
			enforceTogglePair FlowAnim_ON FlowAnim_OFF false
			FlowAnim_StartTime.enabled = true
			RefreshTATime 1
		)
		
		-- SEQ Solo save/global toggles
		on SQAnim_Solo_ON changed state do
		(
			enforceTogglePair SQAnim_Solo_ON SQAnim_Solo_OFF true
			SQAnim_Solo_StartTime.enabled = false
		)
		on SQAnim_Solo_OFF changed state do
		(
			enforceTogglePair SQAnim_Solo_ON SQAnim_Solo_OFF false
			SQAnim_Solo_StartTime.enabled = true
		)
		on SQAnim_Save_ON changed state  do enforceTogglePair SQAnim_Save_ON SQAnim_Save_OFF true
		on SQAnim_Save_OFF changed state do enforceTogglePair SQAnim_Save_ON SQAnim_Save_OFF false
		
		-- Auto-update end key when grid dimensions change
		on SQAnim_Solo_Columns changed arg do (SQAnim_Solo_EndKey.value = SQAnim_Solo_Columns.value * SQAnim_Solo_Rows.value)
		on SQAnim_Solo_Rows changed arg    do (SQAnim_Solo_EndKey.value = SQAnim_Solo_Columns.value * SQAnim_Solo_Rows.value)
		
		-- SEQ Many folder browser
		on SQAnim_Many_btn pressed do
		(
			local iniPath = getdir #userscripts + "\\InitialDir.ini"
			local startDir = undefined
			if doesFileExist iniPath then
				startDir = getINISetting iniPath "InitialDir" "MatSequenceDir"
			else
				setINISetting iniPath "InitialDir" "MatSequenceDir" "C:\\Users\\Administrator\\Desktop"
			
			local chosenPath = getSavePath caption:"Select a folder to store multiple sequence frames" initialDir:startDir
			if chosenPath != undefined do
			(
				SQAnim_Many_Path.text = chosenPath
				setINISetting iniPath "InitialDir" "MatSequenceDir" chosenPath
			)
		)
		
		-- Playback rate sync
		on SQAnim_Many_PlaybackRate changed val do
		(
			try ( if this.texture != undefined do this.texture.playbackRate = val ) catch()
			try ( ::SequenceManager.scanGlobalSequences(); ::SequenceManager.mainRollout.setListItems() ) catch()
		)
		on SQAnim_Many_Speed selected sel do
		(
			local rate = case sel of ( 1: 0.333333; 2: 0.5; 3: 1.0; default: 1.0 )
			SQAnim_Many_PlaybackRate.value = rate
			try ( if this.texture != undefined do this.texture.playbackRate = rate ) catch()
			try ( ::SequenceManager.scanGlobalSequences(); ::SequenceManager.mainRollout.setListItems() ) catch()
		)
		
		-- Main generate button
		on btn_Generate pressed do
		(
			try
			(
				-- Pre-validate: Flow Anim requires at least one transform
				if chk_LDDH.checked do
				(
					local hasAnyTransform = (FlowAnim_Up.checked or FlowAnim_Down.checked or FlowAnim_Left.checked or FlowAnim_Right.checked \
						or FlowAnim_RotLeft.checked or FlowAnim_RotRight.checked \
						or FlowAnim_ScaleUp.checked or FlowAnim_ScaleDown.checked)
					if not hasAnyTransform do
					(
						messagebox ("Please select at least one direction, rotation or scaling option!    ") title:MessageboxTitle
						return()
					)
				)
				
				local result = undefined
				undo on
				(
					if chk_LDDH.checked      do result = generateFlowAnimation()
					if chk_XLDH_Solo.checked do result = generateSeqSoloAnimation()
					if chk_XLDH_Many.checked do result = generateSeqManyAnimation()
					
					-- Skip post-processing if generation was aborted
					if result == false do return result
					
					-- Refresh opacity channel
					if (this.opacityTexture != undefined and isValidNode this.opacityTexture) do (delete this.opacityTexture)
					this.opacityTexture = generateOpacity this.texture
					adjustFilterMode filterMode
					
					-- Force material editor refresh
					meditMaterials[activeMeditSlot] = Standardmaterial()
					meditMaterials[activeMeditSlot] = this
					materialControllersUpdate()
					
					-- Update SequenceManager if available
					try ( ::SequenceManager.scanGlobalSequences(); ::SequenceManager.mainRollout.setListItems() ) catch()
				)
				if result != false do
					messagebox (MessageboxText1 + "    ") title:MessageboxTitle
			)
			catch ( messagebox (MessageboxText4 + "    ") title:MessageboxTitle )
		)
		
		-- ==================== Rollout Open ====================
		on bnt_opacity_Instant_con changed state do
		(
			local hasAnim = (try(this.alpha.isAnimated != false)catch(false))
			this.bnt_opacity_Instant_con()
			bnt_opacity_Instant_con.checked = hasAnim
			bnt_opacity_linear_con.checked = false
			bnt_opacity_bezier_con.checked = false
			bnt_opacity_hermite_con.checked = false
		)
		on bnt_opacity_linear_con changed state do
		(
			local hasAnim = (try(this.alpha.isAnimated != false)catch(false))
			this.bnt_opacity_linear_con()
			bnt_opacity_Instant_con.checked = false
			bnt_opacity_linear_con.checked = hasAnim
			bnt_opacity_bezier_con.checked = false
			bnt_opacity_hermite_con.checked = false
		)
		on bnt_opacity_bezier_con changed state do
		(
			local hasAnim = (try(this.alpha.isAnimated != false)catch(false))
			this.bnt_opacity_bezier_con()
			bnt_opacity_Instant_con.checked = false
			bnt_opacity_linear_con.checked = false
			bnt_opacity_bezier_con.checked = hasAnim
			bnt_opacity_hermite_con.checked = false
		)
		on bnt_opacity_hermite_con changed state do
		(
			local hasAnim = (try(this.alpha.isAnimated != false)catch(false))
			this.bnt_opacity_hermite_con()
			bnt_opacity_Instant_con.checked = false
			bnt_opacity_linear_con.checked = false
			bnt_opacity_bezier_con.checked = false
			bnt_opacity_hermite_con.checked = hasAnim
		)
		on btn_tex_anim_instant changed state do
		(
			local hasAnim = (try(this.texture.coords.U_offset.isAnimated != false or this.texture.coords.V_offset.isAnimated != false)catch(false))
			this.btn_tex_anim_instant()
			btn_tex_anim_instant.checked = hasAnim
			btn_tex_anim_linear.checked = false
			btn_tex_anim_bezier.checked = false
			btn_tex_anim_hermite.checked = false
		)
		on btn_tex_anim_linear changed state do
		(
			local hasAnim = (try(this.texture.coords.U_offset.isAnimated != false or this.texture.coords.V_offset.isAnimated != false)catch(false))
			this.btn_tex_anim_linear()
			btn_tex_anim_instant.checked = false
			btn_tex_anim_linear.checked = hasAnim
			btn_tex_anim_bezier.checked = false
			btn_tex_anim_hermite.checked = false
		)
		on btn_tex_anim_bezier changed state do
		(
			local hasAnim = (try(this.texture.coords.U_offset.isAnimated != false or this.texture.coords.V_offset.isAnimated != false)catch(false))
			this.btn_tex_anim_bezier()
			btn_tex_anim_instant.checked = false
			btn_tex_anim_linear.checked = false
			btn_tex_anim_bezier.checked = hasAnim
			btn_tex_anim_hermite.checked = false
		)
		on btn_tex_anim_hermite changed state do
		(
			local hasAnim = (try(this.texture.coords.U_offset.isAnimated != false or this.texture.coords.V_offset.isAnimated != false)catch(false))
			this.btn_tex_anim_hermite()
			btn_tex_anim_instant.checked = false
			btn_tex_anim_linear.checked = false
			btn_tex_anim_bezier.checked = false
			btn_tex_anim_hermite.checked = hasAnim
		)
		on spnWOffset changed val do (this.Wc3_W_Offset = val)
		
		on window2 open do
		(
			-- Load controller button icons
			bnt_opacity_Instant_con.images = #(Icon_Path + "ndx_none.bmp"       , undefined, 2, 1,2,1,2, True)
			bnt_opacity_linear_con.images = #(Icon_Path + "ndx_linear.bmp"     , undefined, 2, 1,2,1,2, True)
			bnt_opacity_bezier_con.images = #(Icon_Path + "ndx_bezier.bmp"     , undefined, 2, 1,2,1,2, True)
			bnt_opacity_hermite_con.images = #(Icon_Path + "ndx_hermite.bmp"   , undefined, 2, 1,2,1,2, True)
			btn_tex_anim_instant.images = #(Icon_Path + "ndx_none_big.bmp"     , undefined, 2, 1,2,1,2, True)
			btn_tex_anim_linear.images = #(Icon_Path + "ndx_linear_big.bmp"    , undefined, 2, 1,2,1,2, True)
			btn_tex_anim_bezier.images = #(Icon_Path + "ndx_bezier_big.bmp"    , undefined, 2, 1,2,1,2, True)
			btn_tex_anim_hermite.images = #(Icon_Path + "ndx_hermite_big.bmp"  , undefined, 2, 1,2,1,2, True)
			-- Load direction button icons (strip: image1=unchecked, image2=checked)
			FlowAnim_Up.images    = #(Icon_Path + "ndx_up.bmp",    undefined, 2, 1,2,1,2, True)
			FlowAnim_Down.images  = #(Icon_Path + "ndx_down.bmp",  undefined, 2, 1,2,1,2, True)
			FlowAnim_Left.images  = #(Icon_Path + "ndx_left.bmp",  undefined, 2, 1,2,1,2, True)
			FlowAnim_Right.images = #(Icon_Path + "ndx_right.bmp", undefined, 2, 1,2,1,2, True)
			
			-- Determine which mode to show based on stored parameter values
			local modeToActivate = if GenerateBtn1 then 1
			                       else if GenerateBtn2 then 2
			                       else 3
			activateMode modeToActivate

			-- Localization
			if ::L != undefined then
			(
				window2.title = ::L.t "mat_animation_generation_title"
				chk_LDDH.text = ::L.t "mat_flow_anim_btn"
				chk_LDDH.tooltip = ::L.t "mat_the_water_effect_of_the_refere_tip"
				chk_XLDH_Solo.text = ::L.t "mat_seq_animsolo_btn"
				chk_XLDH_Solo.tooltip = ::L.t "mat_reference_hit_effect_sequence_tip"
				chk_XLDH_Many.text = ::L.t "mat_seq_animmany_btn"
				chk_XLDH_Many.tooltip = ::L.t "mat_refer_to_the_texture_of_genshi_tip"
				FlowAnim_RotLeft.tooltip = ::L.t "mat_rotate_left_counterclockwise_tip"
				FlowAnim_RotRight.tooltip = ::L.t "mat_rotate_right_clockwise_tip"
				FlowAnim_ScaleUp.tooltip = ::L.t "mat_scale_up_larger_tip"
				FlowAnim_ScaleDown.tooltip = ::L.t "mat_scale_down_smaller_tip"
				btn_Model.text = ::L.t "mat_generate_uv_map_btn"
				btn_Generate.text = ::L.t "mat_start_of_production_btn"
				-- Flow Anim labels
				l65.text = ::L.t "mat_start_time_lbl"
				l66.text = ::L.t "mat_end_time_lbl"
				l67.text = ::L.t "mat_direction_lbl"
				l78.text = ::L.t "mat_rotation_lbl"
				l79.text = ::L.t "mat_scaling_lbl"
				l69.text = ::L.t "mat_global_animation_lbl"
				l70.text = ::L.t "mat_keep_existing_animation_lbl"
				-- SEQ Solo labels
				l55.text = ::L.t "mat_start_time_lbl_2"
				l56.text = ::L.t "mat_loop_lbl"
				l57.text = ::L.t "mat_columns_lbl"
				l58.text = ::L.t "mat_rows_lbl"
				l59.text = ::L.t "mat_start_key_lbl"
				l60.text = ::L.t "mat_end_key_lbl"
				l80.text = ::L.t "mat_frame_skipping_lbl"
				l61.text = ::L.t "mat_play_order_lbl"
				l62.text = ::L.t "mat_play_speed_lbl"
				l63.text = ::L.t "mat_global_animation_lbl_2"
				l64.text = ::L.t "mat_keep_existing_animation_lbl_2"
				l73.text = ::L.t "mat_collapse_modifier_lbl"
				-- SEQ Many labels
				l71.text = ::L.t "mat_play_order_lbl_2"
				l72.text = ::L.t "mat_play_speed_lbl_2"
				l_pbrate.text = ::L.t "mat_playback_rate_lbl"
				l75.text = ::L.t "mat_sequence_frame_folder_path_lbl"
				-- Controller option labels
				malpha.caption = ::L.t "mat_opacity_lbl"
				lbl53.text = ::L.t "mat_texture_anim_controller_lbl"
				lblWOffset.text = ::L.t "mat_w_offset_lbl"
				bnt_opacity_Instant_con.tooltip = ::L.t "mat_instant_controller_tip"
				bnt_opacity_linear_con.tooltip = ::L.t "mat_linear_controller_tip"
				bnt_opacity_bezier_con.tooltip = ::L.t "mat_bezier_controller_tip"
				bnt_opacity_hermite_con.tooltip = ::L.t "mat_hermite_controller_tip"
				btn_tex_anim_instant.tooltip = ::L.t "mat_instant_controller_tip_2"
				btn_tex_anim_linear.tooltip = ::L.t "mat_linear_controller_tip_2"
				btn_tex_anim_bezier.tooltip = ::L.t "mat_bezier_controller_tip_2"
				btn_tex_anim_hermite.tooltip = ::L.t "mat_hermite_controller_tip_2"
			)
		)
	)

	rollout reforgedRollout "Texture Maps"
	(
		global MatRolloutForMenu_RF
		
		-- ============================================================================
		-- HELPER FUNCTIONS
		-- ============================================================================
		
		-- Opens the prefix path INI file in notepad for editing
		fn openPrefixINI =
		(
			local iniPath = GetDir #userScripts + "\\NeodexConfig\\MatPrefixPath.ini"
			if not (doesFileExist iniPath) then
			(
				makeDir (getFilenamePath iniPath) all:true
				setINISetting iniPath "PathMenu" "Count" "4"
				setINISetting iniPath "PathMenu" "Path1" "Textures\\\\"
				setINISetting iniPath "PathMenu" "Path2" "war3mapImported\\\\"
				setINISetting iniPath "PathMenu" "Path3" "ReplaceableTextures\\\\Shadows\\\\"
				setINISetting iniPath "PathMenu" "Path4" "ReplaceableTextures\\\\Cliff\\\\"
			)
			local startInfo = dotNetObject "System.Diagnostics.ProcessStartInfo"
			startInfo.FileName = "notepad.exe"
			startInfo.Arguments = iniPath
			startInfo.UseShellExecute = true
			(dotNetClass "System.Diagnostics.Process").Start(startInfo)
		)
		
		-- Shows prefix path popup menu for a named parameter
		fn showPbrPrefixMenu paramName menuName =
		(
			local iniPath = GetDir #userScripts + "\\NeodexConfig\\MatPrefixPath.ini"
			if not (doesFileExist iniPath) then
			(
				makeDir (getFilenamePath iniPath) all:true
				setINISetting iniPath "PathMenu" "Count" "4"
				setINISetting iniPath "PathMenu" "Path1" "Textures\\\\"
				setINISetting iniPath "PathMenu" "Path2" "war3mapImported\\\\"
				setINISetting iniPath "PathMenu" "Path3" "ReplaceableTextures\\\\Shadows\\\\"
				setINISetting iniPath "PathMenu" "Path4" "ReplaceableTextures\\\\Cliff\\\\"
			)
			local q = bit.intAsChar 34
			local PathCount = (getINISetting iniPath "PathMenu" "Count") as integer
			local code = "rcMenu " + menuName + "\n(\n"
			local lastMenu = (PathCount + 1) as string
			for i = 1 to PathCount do
			(
				local pval = getINISetting iniPath "PathMenu" ("Path" + i as string)
				code += "menuItem mi" + (i as string) + " " + q + pval + q + "\n"
			)
			code += "menuItem mi" + lastMenu + " " + q + "(Clear)" + q + "\n"
			for i = 1 to PathCount do
			(
				local tempstr = getINISetting iniPath "PathMenu" ("Path" + i as string)
				code += "on mi" + (i as string) + " picked do (MatRolloutForMenu_RF." + paramName + " = " + q + tempstr + q + ")\n"
			)
			code += "on mi" + lastMenu + " picked do (MatRolloutForMenu_RF." + paramName + " = " + q + q + ")\n"
			code += ")\npopUpMenu " + menuName + " pos:mouse.screenpos"
			execute code
		)
		
		-- ============================================================================
		-- DIFFUSE TEXTURE (with preview at top)
		-- ============================================================================
		group "Diffuse Texture"
		(
			dotNetControl rfPanel_Border "System.Windows.Forms.Panel" width:124 height:124 pos:[98,26]
			dotnetcontrol rfImgBox "System.Windows.Forms.PictureBox" width:120 height:120 pos:[100,28]
			label 		lbl_rf_diff "Texture File ............................" height:22 align:#left pos:[14,156] width:174
			button 		btnDiffBrowse "⚙" width:24 height:20 align:#left pos:[190,153] tooltip:"Open Texture Browser"
			button 		btnDiffuseMap "None" width:94 height:20 align:#left pos:[218,153] tooltip:"Click to select a diffuse texture file"
			label 		lbl_rf_diffpfx "Prefix Path :" height:22 align:#left pos:[14,182] width:70
			edittext 	edt_diffPath "" labelOnTop:true width:175 height:20 align:#left pos:[79,179]
			button 		btnDiffSelectPath "▼" width:24 height:24 pos:[259,177] tooltip:"Select prefix path"
			button 		btnDiffEditPath "+" width:24 height:24 pos:[288,177] tooltip:"Edit shortcut prefix path"
			label huanhang_rf0 "" height:1 align:#center offset:[0,-1]
		)
		
		-- ============================================================================
		-- PBR TEXTURE MAPS (each with its own Prefix Path)
		-- ============================================================================
		group "PBR Texture Maps"
		(
			label 		lbl_rf_03 "Normal Map ............................." height:22 align:#left pos:[14,238] width:174
			button 		btnNormalBrowse "⚙" width:24 height:20 align:#left pos:[190,235] tooltip:"Open Texture Browser"
			mapbutton 	mb_normal "" width:94 height:20 align:#left pos:[218,235]
			label 		lbl_rf_nrmpfx "Prefix Path :" height:22 align:#left pos:[14,262] width:70
			edittext 	edt_normalPath "" labelOnTop:true width:175 height:20 align:#left pos:[79,259]
			button 		btnSelPathN "▼" width:24 height:24 pos:[259,257] tooltip:"Select prefix path"
			button 		btnEditPathN "+" width:24 height:24 pos:[288,257] tooltip:"Edit shortcut prefix path"
			
			label 		lbl_rf_04 "ORM Map ................................." height:22 align:#left pos:[14,290] width:174
			button 		btnOrmBrowse "⚙" width:24 height:20 align:#left pos:[190,287] tooltip:"Open Texture Browser"
			mapbutton 	mb_orm "" width:94 height:20 align:#left pos:[218,287]
			label 		lbl_rf_ormpfx "Prefix Path :" height:22 align:#left pos:[14,314] width:70
			edittext 	edt_ormPath "" labelOnTop:true width:175 height:20 align:#left pos:[79,311]
			button 		btnSelPathO "▼" width:24 height:24 pos:[259,309] tooltip:"Select prefix path"
			button 		btnEditPathO "+" width:24 height:24 pos:[288,309] tooltip:"Edit shortcut prefix path"
			
			label 		lbl_rf_05 "Emissive Map .........................." height:22 align:#left pos:[14,342] width:174
			button 		btnEmissiveBrowse "⚙" width:24 height:20 align:#left pos:[190,339] tooltip:"Open Texture Browser"
			mapbutton 	mb_emissive "" width:94 height:20 align:#left pos:[218,339]
			label 		lbl_rf_emipfx "Prefix Path :" height:22 align:#left pos:[14,366] width:70
			edittext 	edt_emissivePath "" labelOnTop:true width:175 height:20 align:#left pos:[79,363]
			button 		btnSelPathE "▼" width:24 height:24 pos:[259,361] tooltip:"Select prefix path"
			button 		btnEditPathE "+" width:24 height:24 pos:[288,361] tooltip:"Edit shortcut prefix path"
			
			label 		lbl_rf_06 "Environment Map ....................." height:22 align:#left pos:[14,394] width:174
			button 		btnReflectionBrowse "⚙" width:24 height:20 align:#left pos:[190,391] tooltip:"Open Texture Browser"
			mapbutton 	mb_reflection "" width:94 height:20 align:#left pos:[218,391]
			label 		lbl_rf_reflpfx "Prefix Path :" height:22 align:#left pos:[14,418] width:70
			edittext 	edt_reflectionPath "" labelOnTop:true width:175 height:20 align:#left pos:[79,415]
			button 		btnSelPathR "▼" width:24 height:24 pos:[259,413] tooltip:"Select prefix path"
			button 		btnEditPathR "+" width:24 height:24 pos:[288,413] tooltip:"Edit shortcut prefix path"
			
			label 		lbl_rf_07 "TeamColor Slot (Binding #4) ......" height:22 align:#left pos:[14,446] width:174
			checkbox	chk_teamColorSlot "aktiv (replaceableId=1)" height:20 align:#left pos:[190,446]
			label huanhang_rf1 "" height:1 align:#center offset:[0,-1]
		)
		
		-- ============================================================================
		-- REFORGED SETTINGS
		-- ============================================================================
		group "Reforged Settings"
		(
			label 		lbl_rf_10 "Emissive Gain .........................." height:22 align:#left pos:[14,504] width:174
			spinner 	spn_emissiveGain "" fieldwidth:59 range:[0,100,1.0] type:#float pos:[242,504] align:#left
			label 		lbl_rf_11 "Fresnel Color R ........................." height:22 align:#left pos:[14,530] width:174
			spinner 	spn_fresnelR "" fieldwidth:59 range:[0,1,1.0] type:#float pos:[242,530] align:#left
			label 		lbl_rf_12 "Fresnel Color G ........................." height:22 align:#left pos:[14,556] width:174
			spinner 	spn_fresnelG "" fieldwidth:59 range:[0,1,1.0] type:#float pos:[242,556] align:#left
			label 		lbl_rf_13 "Fresnel Color B ........................." height:22 align:#left pos:[14,582] width:174
			spinner 	spn_fresnelB "" fieldwidth:59 range:[0,1,1.0] type:#float pos:[242,582] align:#left
			label 		lbl_rf_14 "Fresnel Opacity .........................." height:22 align:#left pos:[14,608] width:174
			spinner 	spn_fresnelOpacity "" fieldwidth:59 range:[0,1,0.0] type:#float pos:[242,608] align:#left
			label 		lbl_rf_15 "Fresnel Team Color ...................." height:22 align:#left pos:[14,634] width:174
			spinner 	spn_fresnelTeamColor "" fieldwidth:59 range:[0,1,0.0] type:#float pos:[242,634] align:#left
			label huanhang_rf2 "" height:1 align:#center offset:[0,-1]
		)
		
		-- ============================================================================
		-- EVENT HANDLERS
		-- ============================================================================
		
		on chk_teamColorSlot changed state do
			this.teamColorTexId = if state then 1 else 0
		
		-- Diffuse Texture button: opens file dialog
		on btnDiffuseMap pressed do
		(
			local f = getOpenFileName caption:"Select Texture" types:"Image Files (*.blp;*.tga;*.dds;*.png;*.jpg;*.bmp)|*.blp;*.tga;*.dds;*.png;*.jpg;*.bmp|All Files (*.*)|*.*"
			if f != undefined do
			(
				this.texture = Bitmaptexture fileName:f
				btnDiffuseMap.text = filenameFromPath f
				-- Update preview
				try
				(
					local BmpTemp = LoadImageForPreview f
					if BmpTemp != undefined then
					(
						if rfImgBox.image != undefined then rfImgBox.image.Dispose()
						rfImgBox.image = BmpTemp
						rfImgBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
						rfPanel_Border.visible = true
					)
				) catch()
				rfImgBox.Refresh()
			)
		)
		
		-- Diffuse Prefix Path: sync to actual parameter in window1
		on edt_diffPath entered txt do
		(
			local cleaned = substituteString txt "\r" ""
			cleaned = substituteString cleaned "\n" ""
			edt_diffPath.text = cleaned
			this.path = cleaned
		)
		
		-- Texture Browser buttons (open MPQ/CASC browser with slot target)
		on btnDiffBrowse pressed do
		(
			try (::NeoDexTexBrowserTarget = #(this, "diffuse"); ::NeoDexTexBrowser.show())
			catch (messageBox "Texture Browser not available.")
		)
		on btnNormalBrowse pressed do
		(
			try (::NeoDexTexBrowserTarget = #(this, "normal"); ::NeoDexTexBrowser.show())
			catch (messageBox "Texture Browser not available.")
		)
		on btnOrmBrowse pressed do
		(
			try (::NeoDexTexBrowserTarget = #(this, "orm"); ::NeoDexTexBrowser.show())
			catch (messageBox "Texture Browser not available.")
		)
		on btnEmissiveBrowse pressed do
		(
			try (::NeoDexTexBrowserTarget = #(this, "emissive"); ::NeoDexTexBrowser.show())
			catch (messageBox "Texture Browser not available.")
		)
		on btnReflectionBrowse pressed do
		(
			try (::NeoDexTexBrowserTarget = #(this, "reflection"); ::NeoDexTexBrowser.show())
			catch (messageBox "Texture Browser not available.")
		)
		
		-- Diffuse Prefix Path dropdown (same INI as window1)
		on btnDiffSelectPath pressed do
		(
			MatRolloutForMenu_RF = this
			local iniPath = GetDir #userScripts + "\\NeodexConfig\\MatPrefixPath.ini"
			if not (doesFileExist iniPath) then
			(
				makeDir (getFilenamePath iniPath) all:true
				setINISetting iniPath "PathMenu" "Count" "4"
				setINISetting iniPath "PathMenu" "Path1" "Textures\\\\"
				setINISetting iniPath "PathMenu" "Path2" "war3mapImported\\\\"
				setINISetting iniPath "PathMenu" "Path3" "ReplaceableTextures\\\\Shadows\\\\"
				setINISetting iniPath "PathMenu" "Path4" "ReplaceableTextures\\\\Cliff\\\\"
			)
			local q = bit.intAsChar 34
			local PathCount = (getINISetting iniPath "PathMenu" "Count") as integer
			local code = "rcMenu pathMenuRF\n(\n"
			local lastMenu = "1"
			for i = 1 to PathCount do
			(
				local pval = getINISetting iniPath "PathMenu" ("Path" + i as string)
				code += "menuItem mi" + (i as string) + " " + q + pval + q + "\n"
				lastMenu = (i + 1) as string
			)
			code += "menuItem mi" + lastMenu + " " + q + "(Clear)" + q + "\n"
			for i = 1 to PathCount do
			(
				local tempstr = getINISetting iniPath "PathMenu" ("Path" + i as string)
				code += "on mi" + (i as string) + " picked do (\nMatRolloutForMenu_RF.reforgedRollout.edt_diffPath.text = " + q + tempstr + q + "\nMatRolloutForMenu_RF.path = " + q + tempstr + q + "\n)\n"
			)
			code += "on mi" + lastMenu + " picked do (\nMatRolloutForMenu_RF.reforgedRollout.edt_diffPath.text = " + q + q + "\nMatRolloutForMenu_RF.path = " + q + q + "\n)\n"
			code += ")\npopUpMenu pathMenuRF pos:mouse.screenpos"
			execute code
		)
		
		-- Diffuse Prefix Path edit button
		on btnDiffEditPath pressed do openPrefixINI()
		
		-- PBR Prefix Path entered handlers (strip newlines)
		on edt_normalPath entered txt do (edt_normalPath.text = substituteString (substituteString txt "\r" "") "\n" "")
		on edt_ormPath entered txt do (edt_ormPath.text = substituteString (substituteString txt "\r" "") "\n" "")
		on edt_emissivePath entered txt do (edt_emissivePath.text = substituteString (substituteString txt "\r" "") "\n" "")
		on edt_reflectionPath entered txt do (edt_reflectionPath.text = substituteString (substituteString txt "\r" "") "\n" "")
		
		-- PBR Prefix Path ▼ buttons (select from INI presets)
		on btnSelPathN pressed do (MatRolloutForMenu_RF = this; showPbrPrefixMenu "normalPrefixPath" "prefMenuN")
		on btnSelPathO pressed do (MatRolloutForMenu_RF = this; showPbrPrefixMenu "ormPrefixPath" "prefMenuO")
		on btnSelPathE pressed do (MatRolloutForMenu_RF = this; showPbrPrefixMenu "emissivePrefixPath" "prefMenuE")
		on btnSelPathR pressed do (MatRolloutForMenu_RF = this; showPbrPrefixMenu "reflectionPrefixPath" "prefMenuR")
		
		-- PBR Prefix Path + buttons (edit INI file)
		on btnEditPathN pressed do openPrefixINI()
		on btnEditPathO pressed do openPrefixINI()
		on btnEditPathE pressed do openPrefixINI()
		on btnEditPathR pressed do openPrefixINI()
		
		-- ============================================================================
		-- ROLLOUT OPEN
		-- ============================================================================
		on reforgedRollout open do
		(
			-- Setup preview image
			rfPanel_Border.BackColor = (dotNetClass "System.Drawing.Color").Black
			rfImgBox.BackColor = rfImgBox.BackColor.FromArgb 255 32 32 32
			rfImgBox.sizeMode = (dotNetClass "System.Windows.Forms.PictureBoxSizeMode").StretchImage
			
			-- Load texture preview (respects Replaceable Texture selection)
			try
			(
				local previewPath = undefined
				
				if this.retexture == 3 then
				(
					-- Team Glow: show active team glow texture
					if NeoDexWc3MaterialTeamGlowTextures != undefined and NeoDexWc3MaterialTeamGlowTextures.count == 16 then
					(
						local glowTex = NeoDexWc3MaterialTeamGlowTextures[NeoDexTeamColor]
						if glowTex != undefined and classof glowTex == Bitmaptexture then
							previewPath = glowTex.fileName
					)
				)
				else
				(
					-- Normal / Team Color / Others: show diffuse texture
					if this.texture != undefined and classof this.texture == Bitmaptexture and this.texture.fileName != undefined and this.texture.fileName != "" then
						previewPath = this.texture.fileName
				)
				
				if previewPath != undefined and previewPath != "" then
				(
					local BmpTemp = LoadImageForPreview previewPath
					if BmpTemp != undefined then
					(
						if rfImgBox.image != undefined then rfImgBox.image.Dispose()
						rfImgBox.image = BmpTemp
						rfImgBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
						rfPanel_Border.visible = true
					)
					else throw "no image"
				)
				else throw "no texture"
			)
			catch
			(
				rfImgBox.image = LoadImageForPreview (Icon_Path + "ndx_mat_none.png")
				rfImgBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
				rfPanel_Border.visible = false
			)
			
			-- Sync diffuse button text
			try
			(
				if this.texture != undefined and classof this.texture == Bitmaptexture and this.texture.fileName != undefined and this.texture.fileName != "" then
					btnDiffuseMap.text = filenameFromPath this.texture.fileName
				else if this.texture != undefined then
					btnDiffuseMap.text = "(Map)"
				else
					btnDiffuseMap.text = "None"
			) catch (btnDiffuseMap.text = "None")
			
			-- Sync diffuse prefix path
			try (edt_diffPath.text = if this.path != undefined then this.path else "") catch()
			
			-- Sync PBR mapbutton texts
			try (if this.normal_map != undefined and classof this.normal_map == Bitmaptexture and this.normal_map.fileName != undefined then mb_normal.text = filenameFromPath this.normal_map.fileName) catch()
			try (if this.orm_map != undefined and classof this.orm_map == Bitmaptexture and this.orm_map.fileName != undefined then mb_orm.text = filenameFromPath this.orm_map.fileName) catch()
			try (if this.emissive_map != undefined and classof this.emissive_map == Bitmaptexture and this.emissive_map.fileName != undefined then mb_emissive.text = filenameFromPath this.emissive_map.fileName) catch()
			try (if this.reflection_map != undefined and classof this.reflection_map == Bitmaptexture and this.reflection_map.fileName != undefined then mb_reflection.text = filenameFromPath this.reflection_map.fileName) catch()
			
			-- Sync TeamColor checkbox
			try (chk_teamColorSlot.checked = (this.teamColorTexId > 0)) catch()
			
			-- Enable/disable texture browser buttons based on configured archive paths
			local browserAvailable = false
			try
			(
				-- Check if MPQ directory is configured and valid
				if ::NeoDexMPQ != undefined and ::NeoDexMPQ.getDirectory() != "" and ::NeoDexMPQ.validateDirectory() then
					browserAvailable = true
				-- Check if CASC path is configured in Settings INI
				if not browserAvailable then
				(
					local cascIni = getDir #plugcfg + "\\NeoDex_Settings.ini"
					local cascDir = getINISetting cascIni "CASC" "W3Path"
					if cascDir != "" and doesFileExist (cascDir + "\\.build.info") then
						browserAvailable = true
				)
			) catch()
			btnDiffBrowse.enabled = browserAvailable
			btnNormalBrowse.enabled = browserAvailable
			btnOrmBrowse.enabled = browserAvailable
			btnEmissiveBrowse.enabled = browserAvailable
			btnReflectionBrowse.enabled = browserAvailable

			-- Localization
			if ::L != undefined then
			(
				reforgedRollout.title = ::L.t "mat_texture_maps_title"
				lbl_rf_diff.text = ::L.t "mat_texture_file_lbl"
				lbl_rf_diffpfx.text = ::L.t "mat_prefix_path_lbl"
				btnDiffSelectPath.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnDiffEditPath.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
				lbl_rf_03.text = ::L.t "mat_normal_map_lbl"
				lbl_rf_nrmpfx.text = ::L.t "mat_prefix_path_lbl"
				btnSelPathN.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnEditPathN.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
				lbl_rf_04.text = ::L.t "mat_orm_map_lbl"
				lbl_rf_ormpfx.text = ::L.t "mat_prefix_path_lbl"
				btnSelPathO.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnEditPathO.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
				lbl_rf_05.text = ::L.t "mat_emissive_map_lbl"
				lbl_rf_emipfx.text = ::L.t "mat_prefix_path_lbl"
				btnSelPathE.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnEditPathE.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
				lbl_rf_06.text = ::L.t "mat_environment_map_lbl"
				lbl_rf_reflpfx.text = ::L.t "mat_prefix_path_lbl"
				btnSelPathR.tooltip = ::L.t "mat_select_prefix_path_tip"
				btnEditPathR.tooltip = ::L.t "mat_edit_shortcut_prefix_path_tip"
				lbl_rf_07.text = ::L.t "mat_teamcolor_slot_binding_4_lbl"
				chk_teamColorSlot.text = ::L.t "mat_aktiv_replaceableid1_chk"
				lbl_rf_10.text = ::L.t "mat_emissive_gain_lbl"
				lbl_rf_11.text = ::L.t "mat_fresnel_color_r_lbl"
				lbl_rf_12.text = ::L.t "mat_fresnel_color_g_lbl"
				lbl_rf_13.text = ::L.t "mat_fresnel_color_b_lbl"
				lbl_rf_14.text = ::L.t "mat_fresnel_opacity_lbl"
				lbl_rf_15.text = ::L.t "mat_fresnel_team_color_lbl"
			)
		)
	)
	---------------------------------------------------------------------------------------
	on load do
	(
		isLoading = true
		append NeoDexMaterials this
		isLoading = false
	)
	

	on update do
	(
		if version == 2 then
		(
			this.unknown1 = false
			this.unknown2 = false
		)
	)
	
	on window1 reload do
	(
		theColor.visible = false
	)

	on create do
	(
		-- setup initial material
		append NeoDexMaterials this
		delegate.shaderType = 1 --Must be Blinn always
	)

)