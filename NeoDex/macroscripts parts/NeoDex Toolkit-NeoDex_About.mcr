macroScript NeoDex_About
buttonText:"About..."
category:"NeoDex Toolkit"
internalCategory:"NeoDex Toolkit"
(
	global neodex_aboutForm = undefined

	fn findIconFolder =
	(
		local srcFile = getSourceFileName()
		if srcFile != undefined and srcFile != "" then
		(
			local scriptDir = getFilenamePath srcFile
			local p1 = scriptDir + "neodex_icons\\"
			if doesFileExist p1 then return p1
			local parentDir = pathConfig.removePathLeaf (trimRight scriptDir "\\")
			local p2 = parentDir + "\\neodex_icons\\"
			if doesFileExist p2 then return p2
		)

		local searchPaths = #()
		append searchPaths ((getDir #userScripts) + "\\neodex_icons\\")
		append searchPaths ((getDir #scripts) + "\\neodex_icons\\")
		append searchPaths ((getDir #maxroot) + "\\neodex_icons\\")

		for p in searchPaths do
			if doesFileExist p then return p

		return undefined
	)

	fn getNeoDexVersion =
	(
		local ver = "?.?.?"
		try (
			local p = undefined
			local subKey = (dotNetClass "Microsoft.Win32.Registry").CurrentUser.OpenSubKey "Software\\NeoDex"
			if subKey != undefined then ( p = subKey.GetValue "InstallPath"; subKey.Close() )
			if p == undefined then
				p = (dotNetClass "System.Environment").GetFolderPath (dotNetClass "System.Environment+SpecialFolder").ApplicationData + "\\Autodesk\\ApplicationPlugins\\NeoDex"
			local vf = p + "\\version.txt"
			if doesFileExist vf then (
				local f = openFile vf mode:"r"
				if f != undefined then ( ver = trimRight (trimLeft (readLine f)); close f )
			)
		) catch ()
		ver
	)

	fn imgToBase64 filePath =
	(
		if not doesFileExist filePath then return ""
		try
		(
			local bytes = (dotNetClass "System.IO.File").ReadAllBytes filePath
			(dotNetClass "System.Convert").ToBase64String bytes
		)
		catch ( "" )
	)

	fn buildHTML =
	(
		local iconFolder = findIconFolder()
		local paypalB64 = ""
		local youtubeB64 = ""
		local hivewsB64 = ""
		local discordB64 = ""
		local alipayB64 = ""
		local wechatB64 = ""
		local githubB64 = ""
		local bilibiliB64 = ""

		if iconFolder != undefined then
		(
			local ppPath = iconFolder + "paypal.png"
			local ytPath = iconFolder + "youtube.png"
			local hwPath = iconFolder + "Hiveworkshop.png"
			local dcPath = iconFolder + "Discord.png"
			local apPath = iconFolder + "alipay.png"
			local wcPath = iconFolder + "wechatpay.png"
			local ghPath = iconFolder + "GitHub-logo.png"
			local blPath = iconFolder + "Bilibili-logo.png"
			if doesFileExist ppPath then paypalB64 = imgToBase64 ppPath
			if doesFileExist ytPath then youtubeB64 = imgToBase64 ytPath
			if doesFileExist hwPath then hivewsB64 = imgToBase64 hwPath
			if doesFileExist dcPath then discordB64 = imgToBase64 dcPath
			if doesFileExist apPath then alipayB64 = imgToBase64 apPath
			if doesFileExist wcPath then wechatB64 = imgToBase64 wcPath
			if doesFileExist ghPath then githubB64 = imgToBase64 ghPath
			if doesFileExist blPath then bilibiliB64 = imgToBase64 blPath
		)

		local paypalSrc = if paypalB64 != "" then ("data:image/png;base64," + paypalB64) else ""
		local youtubeSrc = if youtubeB64 != "" then ("data:image/png;base64," + youtubeB64) else ""
		local hivewsSrc = if hivewsB64 != "" then ("data:image/png;base64," + hivewsB64) else ""
		local discordSrc = if discordB64 != "" then ("data:image/png;base64," + discordB64) else ""
		local alipaySrc = if alipayB64 != "" then ("data:image/png;base64," + alipayB64) else ""
		local wechatSrc = if wechatB64 != "" then ("data:image/png;base64," + wechatB64) else ""
		local githubSrc = if githubB64 != "" then ("data:image/png;base64," + githubB64) else ""
		local bilibiliSrc = if bilibiliB64 != "" then ("data:image/png;base64," + bilibiliB64) else ""

		local html = "<!DOCTYPE html>\n"
		html += "<html>\n<head>\n<meta http-equiv='X-UA-Compatible' content='IE=edge'>\n"
		html += "<style>\n"

		html += "* { margin: 0; padding: 0; box-sizing: border-box; }\n"
		html += "body {\n"
		html += "  background: #2b2b2b;\n"
		html += "  font-family: 'Segoe UI', Tahoma, sans-serif;\n"
		html += "  color: #e0e0e0;\n"
		html += "  padding: 28px 36px;\n"
		html += "  overflow-y: auto;\n"
		html += "  -webkit-user-select: none; user-select: none;\n"
		html += "}\n"

		html += "::-webkit-scrollbar { width: 6px; }\n"
		html += "::-webkit-scrollbar-track { background: #2b2b2b; }\n"
		html += "::-webkit-scrollbar-thumb { background: #555; border-radius: 3px; }\n"

		html += ".header { text-align: center; margin-bottom: 24px; }\n"
		html += ".header h1 { font-size: 28px; font-weight: 600; color: #fff; margin-bottom: 6px; letter-spacing: 2px; }\n"
		html += ".header .accent-line { width: 80px; height: 3px; background: linear-gradient(90deg, #0070ba, #00a2ff); margin: 0 auto 14px auto; border-radius: 2px; }\n"
		html += ".header p { font-size: 14px; color: #999; line-height: 1.6; }\n"

		html += ".card { background: #363636; border: 1px solid #444; border-radius: 8px; padding: 22px 28px; margin-bottom: 16px; text-align: center; }\n"
		html += ".card-icon { max-height: 50px; width: auto; margin-bottom: 14px; }\n"
		html += ".card-title { font-size: 13px; color: #888; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 12px; }\n"

		html += ".license-card { text-align: left; }\n"
		html += ".license-card .card-title { text-align: center; }\n"
		html += ".license-text { font-family: 'Consolas', 'Courier New', monospace; font-size: 12px; color: #bbb; line-height: 1.7; white-space: pre-wrap; word-wrap: break-word; }\n"

		html += ".credits-card { text-align: left; }\n"
		html += ".credits-card .card-title { text-align: center; }\n"
		html += ".credits-section { margin-bottom: 14px; }\n"
		html += ".credits-section:last-child { margin-bottom: 0; }\n"
		html += ".credits-label { font-size: 11px; color: #0099dd; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 6px; font-weight: 600; }\n"
		html += ".credits-names { font-size: 14px; color: #ccc; line-height: 1.7; }\n"
		html += ".credits-names .lead { color: #fff; font-weight: 600; }\n"
		html += ".credits-divider { border: none; border-top: 1px solid #444; margin: 14px 0; }\n"

		html += ".btn { display: block; width: 100%; padding: 14px 28px; border: none; border-radius: 6px; font-size: 15px; font-weight: 600; cursor: pointer; text-decoration: none; color: #fff; text-align: center; letter-spacing: 0.5px; margin-bottom: 8px; }\n"
		html += ".btn:last-child { margin-bottom: 0; }\n"
		html += ".btn-paypal { background: linear-gradient(135deg, #0070ba, #003087); }\n"
		html += ".btn-paypal:hover { background: linear-gradient(135deg, #008cdd, #0050a0); }\n"
		html += ".btn-alipay { background: linear-gradient(135deg, #1677ff, #0958d9); }\n"
		html += ".btn-alipay:hover { background: linear-gradient(135deg, #4096ff, #1677ff); }\n"
		html += ".btn-wechat { background: linear-gradient(135deg, #07c160, #059a4c); }\n"
		html += ".btn-wechat:hover { background: linear-gradient(135deg, #2adb78, #07c160); }\n"
		html += ".btn-youtube { background: linear-gradient(135deg, #ff0000, #cc0000); }\n"
		html += ".btn-youtube:hover { background: linear-gradient(135deg, #ff3333, #dd0000); }\n"
		html += ".btn-hive { background: linear-gradient(135deg, #e68a00, #b36b00); }\n"
		html += ".btn-hive:hover { background: linear-gradient(135deg, #ffaa00, #cc8800); }\n"
		html += ".btn-discord { background: linear-gradient(135deg, #5865F2, #4752C4); }\n"
		html += ".btn-discord:hover { background: linear-gradient(135deg, #6d79ff, #5865F2); }\n"
		html += ".btn-github { background: linear-gradient(135deg, #333, #24292e); }\n"
		html += ".btn-github:hover { background: linear-gradient(135deg, #555, #333); }\n"
		html += ".btn-bilibili { background: linear-gradient(135deg, #00a1d6, #0080b0); }\n"
		html += ".btn-bilibili:hover { background: linear-gradient(135deg, #20c0f0, #00a1d6); }\n"

		html += ".qr-img { max-width: 160px; border-radius: 8px; margin-bottom: 10px; }\n"
		html += ".cn-notice { font-size: 12px; color: #999; margin-top: 12px; line-height: 1.6; padding: 10px; background: #2b2b2b; border-radius: 4px; border: 1px solid #444; }\n"

		html += ".donate-section-divider { border: none; border-top: 1px solid #444; margin: 16px 0; }\n"
		html += ".donate-subtitle { font-size: 12px; color: #666; margin-bottom: 10px; }\n"

		html += ".footer { text-align: center; font-size: 13px; color: #555; margin-top: 18px; }\n"
		html += ".footer span { color: #e74c3c; }\n"

		html += "</style>\n"
		html += "</head>\n<body>\n"

		-- HEADER
		local ndxVer = getNeoDexVersion()
		html += "<div class='header'>\n"
		html += "  <h1>NEODEX</h1>\n"
		html += "  <div class='accent-line'></div>\n"
		html += "  <p style='font-size:16px; color:#0099dd; margin-bottom:10px;'>Version " + ndxVer + "</p>\n"
		html += "  <p>A comprehensive Warcraft III modeling toolkit<br>"
		html += "for Autodesk 3ds Max.<br><br>"
		html += "Import and export MDX/MDL models, manage materials,<br>"
		html += "particle emitters, animations, attachments, lights,<br>"
		html += "collision shapes, cameras and more.</p>\n"
		html += "</div>\n"

		-- DOWNLOADS (Hive + GitHub combined)
		html += "<div class='card'>\n"
		html += "  <div class='card-title'>Get Latest Version &amp; Source Code</div>\n"
		if hivewsSrc != "" then
			html += "  <img class='card-icon' src='" + hivewsSrc + "' /><br>\n"
		html += "  <a class='btn btn-hive' href='action:hive'>Download from Hive Workshop</a>\n"
		html += "  <hr class='donate-section-divider'>\n"
		if githubSrc != "" then
			html += "  <img class='card-icon' src='" + githubSrc + "' /><br>\n"
		html += "  <a class='btn btn-github' href='action:github'>View on GitHub</a>\n"
		html += "</div>\n"

		-- DONATIONS
		html += "<div class='card'>\n"
		html += "  <div class='card-title'>Support the Project</div>\n"

		-- PayPal
		if paypalSrc != "" then
			html += "  <img class='card-icon' src='" + paypalSrc + "' /><br>\n"
		html += "  <a class='btn btn-paypal' href='action:paypal'>Donate via PayPal</a>\n"

		-- Divider
		html += "  <hr class='donate-section-divider'>\n"
		html += "  <div class='donate-subtitle'>Chinese Payment Methods / &#x4E2D;&#x56FD;&#x652F;&#x4ED8;&#x65B9;&#x5F0F;</div>\n"

		-- Alipay
		if alipaySrc != "" then
			html += "  <img class='qr-img' src='" + alipaySrc + "' /><br>\n"
		html += "  <a class='btn btn-alipay' href='#' onclick='return false;'>Donate via Alipay / &#x652F;&#x4ED8;&#x5B9D;</a>\n"

		-- WeChat Pay
		if wechatSrc != "" then
			html += "  <img class='qr-img' src='" + wechatSrc + "' style='margin-top:16px;' /><br>\n"
		html += "  <a class='btn btn-wechat' href='#' onclick='return false;'>Donate via WeChat Pay / &#x5FAE;&#x4FE1;&#x652F;&#x4ED8;</a>\n"

		-- Chinese notice
		html += "  <div class='cn-notice'>\n"
		html += "    &#x4E0D;&#x6392;&#x9664;&#x4F1A;&#x51FA;&#x73B0;&#x652F;&#x4ED8;&#x5931;&#x8D25;&#x7684;&#x60C5;&#x51B5;&#xFF0C;&#x5982;&#x679C;&#x5931;&#x8D25;&#x8BF7;&#x8054;&#x7CFB; QQ ID: 707400208<br>\n"
		html += "    <span style='color:#666;'>Payment issues may occur. If payment fails, please contact QQ ID: 707400208</span>\n"
		html += "  </div>\n"

		html += "</div>\n"

		-- VIDEO CHANNELS (YouTube + Bilibili combined)
		html += "<div class='card'>\n"
		html += "  <div class='card-title'>Learn More about NeoDex</div>\n"
		if youtubeSrc != "" then
			html += "  <img class='card-icon' src='" + youtubeSrc + "' /><br>\n"
		html += "  <a class='btn btn-youtube' href='action:youtube'>Visit YouTube Channel</a>\n"
		html += "  <hr class='donate-section-divider'>\n"
		if bilibiliSrc != "" then
			html += "  <img class='card-icon' src='" + bilibiliSrc + "' /><br>\n"
		html += "  <a class='btn btn-bilibili' href='action:bilibili'>Visit Bilibili Channel</a>\n"
		html += "</div>\n"

		-- DISCORD
		html += "<div class='card'>\n"
		if discordSrc != "" then
			html += "  <img class='card-icon' src='" + discordSrc + "' /><br>\n"
		html += "  <div class='card-title'>Join the Community</div>\n"
		html += "  <a class='btn btn-discord' href='action:discord'>Join Discord Server</a>\n"
		html += "</div>\n"

		-- LICENSE
		html += "<div class='card license-card'>\n"
		html += "  <div class='card-title'>License</div>\n"
		html += "  <div class='license-text'>"
		html += "MIT License\n\n"
		html += "Copyright (c) 2026, DennisH &amp; Benson\n\n"
		html += "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\n"
		html += "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n"
		html += "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
		html += "</div>\n"
		html += "</div>\n"

		-- DISCLAIMER
		html += "<div class='card license-card'>\n"
		html += "  <div class='card-title'>Disclaimer</div>\n"
		html += "  <div class='license-text'>"
		html += "NeoDex Toolkit is a community-developed, fan-made modding tool for Warcraft III. It is not affiliated with, endorsed by, or in any way officially connected to Blizzard Entertainment, Inc. or any of its subsidiaries or affiliates.\n\n"
		html += "Warcraft, Warcraft III, Blizzard, and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc.\n\n"
		html += "Autodesk and 3ds Max are trademarks or registered trademarks of Autodesk, Inc.\n\n"
		html += "All other trademarks are the property of their respective owners."
		html += "</div>\n"
		html += "</div>\n"

		-- CREDITS
		html += "<div class='card credits-card'>\n"
		html += "  <div class='card-title'>Credits</div>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>Lead Developers</div>\n"
		html += "    <div class='credits-names'>\n"
		html += "      <span class='lead'>DennisH</span><br>\n"
		html += "      <span class='lead'>BenSen</span>\n"
		html += "    </div>\n"
		html += "  </div>\n"

		html += "  <hr class='credits-divider'>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>Author</div>\n"
		html += "    <div class='credits-names'>BlinkBoy <span style='color:#666;'>(Fernando Sahmkow)</span></div>\n"
		html += "  </div>\n"

		html += "  <hr class='credits-divider'>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>Contributors</div>\n"
		html += "    <div class='credits-names'>\n"
		html += "      BlinkBoy (Fernando Sahmkow) <span style='color:#666;'>(original author)</span><br>\n"
		html += "      Republicola <span style='color:#666;'>(original dexporter)</span><br>\n"
		html += "      Igni <span style='color:#666;'>(Bipped Support and fixes)</span><br>\n"
		html += "      BenSen <span style='color:#666;'>(new features and fixes)</span><br>\n"
		html += "      LxX'Studio <span style='color:#666;'>(Plugins and fixes)</span><br>\n"
		html += "      HuoHuoXiaoMao <span style='color:#666;'>(Plugins and fixes)</span><br>\n"
		html += "      &#x6653;&#x6708;&#x771F; XYZmoon <span style='color:#666;'>(Icons)</span>\n"
		html += "    </div>\n"
		html += "  </div>\n"

		html += "  <hr class='credits-divider'>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>Beta Testers</div>\n"
		html += "    <div class='credits-names'>\n"
		html += "      Adiktuz<br>\n"
		html += "      BallisticTerrain<br>\n"
		html += "      Manoo<br>\n"
		html += "      skrab<br>\n"
		html += "      GhostHeroine<br>\n"
		html += "      Black_XeSHTeG<br>\n"
		html += "      Gluma<br>\n"
		html += "      &#x2510;(&#xFFE3;&#x30D8;&#xFFE3;)&#x250C;\n"
		html += "    </div>\n"
		html += "  </div>\n"

		html += "</div>\n"

		-- THIRD-PARTY NOTICES
		html += "<div class='card credits-card'>\n"
		html += "  <div class='card-title'>Third-Party Software</div>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>WhiteoutTexCLI</div>\n"
		html += "    <div class='credits-names'>\n"
		html += "      BLP texture conversion powered by <span class='lead'>WhiteoutTexCLI.exe</span><br>\n"
		html += "      <span style='color:#666;'>Part of the WhiteoutTex project</span><br>\n"
		html += "      <a href='action:whiteoutlib' style='color:#0099dd; text-decoration:none;'>View WhiteoutLib License</a>\n"
		html += "    </div>\n"
		html += "  </div>\n"

		html += "  <hr class='credits-divider'>\n"

		html += "  <div class='credits-section'>\n"
		html += "    <div class='credits-label'>Included Libraries</div>\n"
		html += "    <div class='credits-names'>\n"
		html += "      <span class='lead'>Dear ImGui</span> <span style='color:#666;'>&#x2014; Omar Cornut (MIT)</span><br>\n"
		html += "      <span class='lead'>SDL</span> <span style='color:#666;'>&#x2014; Sam Lantinga (zlib)</span><br>\n"
		html += "      <span class='lead'>CascLib</span> <span style='color:#666;'>&#x2014; Ladislav Zezula (MIT)</span><br>\n"
		html += "      <span class='lead'>ncnn</span> <span style='color:#666;'>&#x2014; Tencent (BSD 3-Clause)</span><br>\n"
		html += "      <span class='lead'>Real-ESRGAN ncnn Vulkan</span> <span style='color:#666;'>&#x2014; Xintao Wang (MIT)</span>\n"
		html += "    </div>\n"
		html += "  </div>\n"

		html += "</div>\n"

		html += "<div class='footer'>Made with <span>&hearts;</span> by the NeoDex Team</div>\n"
		html += "</body>\n</html>"

		return html
	)

	on execute do
	(
		if neodex_aboutForm != undefined then
			try ( neodex_aboutForm.Close() ) catch ()

		local form = dotNetObject "System.Windows.Forms.Form"
		-- Localization
		local aboutTitle = "NeoDex - About"
		if ::L != undefined then aboutTitle = ::L.t "about_about_macbtn"
		form.Text = aboutTitle
		form.Width = 500
		form.Height = 1100
		form.StartPosition = (dotNetClass "System.Windows.Forms.FormStartPosition").CenterScreen
		form.FormBorderStyle = (dotNetClass "System.Windows.Forms.FormBorderStyle").FixedToolWindow
		form.BackColor = (dotNetClass "System.Drawing.Color").FromArgb 43 43 43
		form.ShowInTaskbar = false
		form.TopMost = true

		local wb = dotNetObject "System.Windows.Forms.WebBrowser"
		wb.Dock = (dotNetClass "System.Windows.Forms.DockStyle").Fill
		wb.ScrollBarsEnabled = true
		wb.IsWebBrowserContextMenuEnabled = false
		wb.AllowNavigation = true
		wb.ScriptErrorsSuppressed = true

		wb.DocumentText = buildHTML()

		dotNet.addEventHandler wb "Navigating" \
		(
			fn onNavigating sender args =
			(
				local url = args.Url.ToString()

				if (findString url "action:paypal") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://www.paypal.com/donate/?cmd=_s-xclick&hosted_button_id=PQQQB3CHQ5FRG&source=url&ssrt=1727510939761" ""
				)
				else if (findString url "action:youtube") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://www.youtube.com/@Wc3Tutorials" ""
				)
				else if (findString url "action:hive") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://www.hiveworkshop.com/threads/neodex-3-2.354942/page-2" ""
				)
				else if (findString url "action:discord") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://discord.gg/9xDRYYrPV3" ""
				)
				else if (findString url "action:github") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://github.com/DennisHerrm/NeoDex" ""
				)
				else if (findString url "action:bilibili") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://space.bilibili.com/3546757094968048" ""
				)
				else if (findString url "action:whiteoutlib") != undefined then
				(
					args.Cancel = true
					shellLaunch "https://github.com/FernandoS27/WhiteoutLib/blob/master/LICENSE-AI.md" ""
				)
				else if (findString url "about:blank") == undefined then
				(
					args.Cancel = true
				)
			)
		)

		form.Controls.Add wb
		neodex_aboutForm = form
		form.Show()
	)
)
