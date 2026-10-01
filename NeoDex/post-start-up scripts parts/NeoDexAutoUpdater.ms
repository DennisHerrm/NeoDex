/*
 * NeoDex Auto-Updater
 * -------------------
 * Prueft, ob auf GitHub eine neuere NeoDex-Version bereitliegt.
 * Alle UI-Texte laufen ueber ::L.t.
 *
 * Warum als Struct statt als Klammerblock:
 * Der Check laeuft jetzt zeitversetzt ueber einen Timer. Ein Timer-Callback
 * kann keine lokalen Funktionen eines Klammerblocks sehen - die Helfer muessen
 * also auf Struct-Ebene liegen und ueber this. erreichbar sein.
 *
 * Einstiegspunkte (unveraendert nach aussen):
 *   - Beim Laden ueber das Manifest  -> verzoegerter Check per Timer
 *   - fileIn aus dem Settings-Dialog -> sofortiger Check, wenn
 *                                       ::_ndxForceUpdateCheck gesetzt ist
 */

-- Timer und Handler muessen global sein, sonst raeumt MaxScript sie ab,
-- sobald der Interpreter dieses Skript verlassen hat.
global _ndxUpdTimer
global _ndxUpdOnTick

fn _ndxUpdOnTick sender args =
(
	try (::_ndxUpdTimer.Stop()) catch()
	try (::NeoDexAutoUpdater.runCheck()) catch
	(
		format "[NeoDex Updater] Fehler bei der Pruefung: %\n" (getCurrentException())
	)
	ok
)

struct NeoDexAutoUpdaterStruct
(
	public githubUser  = "DennisHerrm",
	public githubRepo  = "NeoDex",

	-- Mindestabstand zwischen zwei automatischen Pruefungen, in Sekunden
	public checkIntervalSeconds = 86400,
	-- Verzoegerung nach dem Start, bevor geprueft wird
	public startupDelayMs = 12000,
	-- Timeout fuer die GitHub-Abfrage
	public requestTimeoutMs = 8000,

	fn getInstallPath =
	(
		local p = undefined
		try
		(
			local subKey = (dotNetClass "Microsoft.Win32.Registry").CurrentUser.OpenSubKey "Software\\NeoDex"
			if subKey != undefined then (p = subKey.GetValue "InstallPath" ; subKey.Close())
		)
		catch()
		if p == undefined then
			p = (dotNetClass "System.Environment").GetFolderPath \
			    (dotNetClass "System.Environment+SpecialFolder").ApplicationData + \
			    "\\Autodesk\\ApplicationPlugins\\NeoDex"
		p
	),

	fn getIniFile = ((this.getInstallPath()) + "\\NeoDex_Settings.ini"),

	fn getLocalVersion =
	(
		local vf = (this.getInstallPath()) + "\\version.txt"
		local ver = "0.0.0"
		if doesFileExist vf then
		(
			local f = openFile vf mode:"r"
			if f != undefined then
			(
				try (ver = trimRight (trimLeft (readLine f))) catch()
				close f
			)
		)
		if ver == undefined or ver == "" then ver = "0.0.0"
		ver
	),

	-- Rueckgabe: 1 wenn rv neuer als lv, -1 wenn aelter, 0 wenn gleich
	fn compareVersions lv rv =
	(
		local lP = filterString lv "."
		local rP = filterString rv "."
		local res = 0
		local n = amax lP.count rP.count
		for i = 1 to n while res == 0 do
		(
			local a = if i <= lP.count then (try (lP[i] as integer) catch 0) else 0
			local b = if i <= rP.count then (try (rP[i] as integer) catch 0) else 0
			if b > a then res = 1
			else if b < a then res = -1
		)
		res
	),

	-- Sekunden seit der letzten Pruefung. -1 = noch nie geprueft.
	fn secondsSinceLastCheck =
	(
		local elapsed = -1.0
		try
		(
			local ini = this.getIniFile()
			if doesFileExist ini then
			(
				local s = getINISetting ini "Updater" "LastCheck"
				if s != undefined and s != "" then
				(
					local dt = (dotNetClass "System.DateTime").Parse s
					elapsed = ((dotNetClass "System.DateTime").UtcNow.Subtract dt).TotalSeconds
					-- Systemuhr zurueckgestellt: als "faellig" behandeln
					if elapsed < 0 then elapsed = -1.0
				)
			)
		)
		catch (elapsed = -1.0)
		elapsed
	),

	fn markChecked =
	(
		try
		(
			setINISetting (this.getIniFile()) "Updater" "LastCheck" \
			              ((dotNetClass "System.DateTime").UtcNow.ToString "o") forceUTF16:false
		)
		catch()
		ok
	),

	-- force:true ueberspringt Intervall und AutoCheck-Schalter
	fn shouldCheck force =
	(
		if force then return true

		local ini = this.getIniFile()
		if doesFileExist ini then
		(
			local autoCheck = getINISetting ini "Updater" "AutoCheck"
			if autoCheck == "0" then return false
		)

		local elapsed = this.secondsSinceLastCheck()
		if elapsed >= 0 and elapsed < this.checkIntervalSeconds then return false
		true
	),

	-- Waehlt aus den Release-Assets die passende Setup-Datei.
	-- Bevorzugt einen Dateinamen, der "setup" enthaelt; sonst die erste .exe.
	fn pickSetupAsset responseText =
	(
		local best = undefined
		local firstExe = undefined
		try
		(
			local rx = dotNetClass "System.Text.RegularExpressions.Regex"
			local ms = rx.Matches responseText "\"browser_download_url\"\\s*:\\s*\"([^\"]+\\.exe)\""
			for i = 0 to (ms.Count - 1) do
			(
				local u = ms.Item[i].Groups.Item[1].Value
				if firstExe == undefined then firstExe = u
				if best == undefined and (matchPattern u pattern:"*setup*" ignoreCase:true) then best = u
			)
		)
		catch()
		if best != undefined then best else firstExe
	),

	-- Fragt GitHub ab. Rueckgabe: #(version, downloadUrl), beide ggf. undefined.
	fn queryGitHub =
	(
		local result = #(undefined, undefined)
		local reader = undefined
		local resp = undefined
		try
		(
			local url = "https://api.github.com/repos/" + this.githubUser + "/" + this.githubRepo + "/releases/latest"

			-- HttpWebRequest statt WebClient: WebClient hat den Timeout fest auf
			-- 100 Sekunden verdrahtet und legt ihn nicht offen. Bei stehendem Netz
			-- haette das den Max-Start so lange blockiert.
			local req = (dotNetClass "System.Net.WebRequest").Create url
			req.Timeout = this.requestTimeoutMs
			try (req.ReadWriteTimeout = this.requestTimeoutMs) catch()
			-- User-Agent ist ein "restricted header" und muss ueber die Property
			-- gesetzt werden, Headers.Add wirft hier.
			req.UserAgent = "NeoDex-Updater"
			try (req.Accept = "application/vnd.github+json") catch()

			resp = req.GetResponse()
			reader = dotNetObject "System.IO.StreamReader" (resp.GetResponseStream())
			local text = reader.ReadToEnd()

			local rx = dotNetClass "System.Text.RegularExpressions.Regex"
			local tm = rx.Match text "\"tag_name\"\\s*:\\s*\"([^\"]+)\""
			if tm.Success then
			(
				local v = tm.Groups.Item[1].Value
				if v.count > 1 and (v[1] == "v" or v[1] == "V") then v = substring v 2 (v.count - 1)
				result[1] = v
			)
			result[2] = this.pickSetupAsset text
		)
		catch
		(
			format "[NeoDex Updater] GitHub-Abfrage fehlgeschlagen: %\n" (getCurrentException())
		)
		try (if reader != undefined then reader.Close()) catch()
		try (if resp   != undefined then resp.Close())   catch()
		result
	),

	fn downloadAndInstall dlUrl ver =
	(
		local tmpDir  = (dotNetClass "System.IO.Path").GetTempPath()
		local dlFile  = tmpDir + "NeoDex_Setup_v" + ver + ".exe"
		local batFile = tmpDir + "NeoDex_AutoInstall.bat"
		try
		(
			progressStart (::L.t "upd_downloading")
			-- Fuer den Download bleibt WebClient: der Nutzer hat ihn angestossen
			-- und wartet bewusst, ein kurzer Timeout waere hier schaedlich.
			local wc = dotNetObject "System.Net.WebClient"
			wc.Headers.Add "User-Agent" "NeoDex-Updater"
			wc.DownloadFile dlUrl dlFile
			wc.Dispose()
			progressEnd()

			if doesFileExist dlFile then
			(
				if queryBox ((::L.t "upd_close_max_msg") + "\n\n" + (::L.t "upd_save_work_msg")) title:(::L.t "upd_title") then
				(
					local bat = "@echo off\n"
					bat += ":WAIT\n"
					bat += "tasklist /FI \"IMAGENAME eq 3dsmax.exe\" 2>NUL | find /I \"3dsmax.exe\" >NUL\n"
					bat += "if %ERRORLEVEL%==0 (\n"
					bat += "    timeout /t 2 /nobreak >NUL\n"
					bat += "    goto WAIT\n"
					bat += ")\n"
					bat += "timeout /t 1 /nobreak >NUL\n"
					bat += "start \"\" \"" + dlFile + "\" /NORESTART /NOCLOSEAPPLICATIONS\n"
					bat += "del \"%~f0\"\n"

					local f = createFile batFile
					format "%" bat to:f
					close f

					local psi = dotNetObject "System.Diagnostics.ProcessStartInfo"
					psi.FileName = batFile
					psi.WindowStyle = (dotNetClass "System.Diagnostics.ProcessWindowStyle").Hidden
					psi.CreateNoWindow = true
					(dotNetClass "System.Diagnostics.Process").Start psi

					quitMax #prompt
				)
			)
			else
				messageBox (::L.t "upd_download_failed") title:(::L.t "upd_title") beep:false
		)
		catch
		(
			progressEnd()
			format "[NeoDex Updater] Download fehlgeschlagen: %\n" (getCurrentException())
		)
		ok
	),

	fn runCheck force:false =
	(
		if not (this.shouldCheck force) then
		(
			format "[NeoDex Updater] Pruefung nicht faellig.\n"
			return ok
		)

		format "[NeoDex Updater] Suche nach Updates ...\n"
		local localVer = this.getLocalVersion()
		format "[NeoDex Updater] Installierte Version: %\n" localVer

		local info      = this.queryGitHub()
		local remoteVer = info[1]
		local dlUrl     = info[2]

		-- Nur bei erfolgreicher Abfrage merken, sonst wird bei Netzausfall
		-- einen Tag lang nicht mehr geprueft.
		if remoteVer != undefined then this.markChecked()

		if remoteVer == undefined then
		(
			format "[NeoDex Updater] Version auf GitHub nicht ermittelbar.\n"
			return ok
		)

		format "[NeoDex Updater] Verfuegbare Version: %\n" remoteVer

		if (this.compareVersions localVer remoteVer) > 0 then
		(
			format "[NeoDex Updater] Neue Version verfuegbar: % -> %\n" localVer remoteVer

			local msg = (::L.t "upd_new_version_msg") + "\n\n"
			msg += (::L.t "upd_installed") + "  v" + localVer + "\n"
			msg += (::L.t "upd_available") + "   v" + remoteVer + "\n\n"
			msg += (::L.t "upd_changelog_at") + "\ngithub.com/" + this.githubUser + "/" + this.githubRepo + "/releases\n\n"
			msg += (::L.t "upd_install_now")

			if queryBox msg title:(::L.t "upd_title_available") then
			(
				if dlUrl != undefined then
					this.downloadAndInstall dlUrl remoteVer
				else
					ShellLaunch ("https://github.com/" + this.githubUser + "/" + this.githubRepo + "/releases/latest") ""
			)
		)
		else
			format "[NeoDex Updater] Version ist aktuell.\n"
		ok
	),

	-- Startet den Check zeitversetzt, damit der Max-Start nicht darauf wartet.
	fn scheduleCheck =
	(
		try
		(
			if ::_ndxUpdTimer != undefined then
			(
				try (::_ndxUpdTimer.Stop())    catch()
				try (::_ndxUpdTimer.Dispose()) catch()
			)
		)
		catch()
		try
		(
			::_ndxUpdTimer = dotNetObject "System.Windows.Forms.Timer"
			::_ndxUpdTimer.Interval = this.startupDelayMs
			dotNet.addEventHandler ::_ndxUpdTimer "Tick" ::_ndxUpdOnTick
			::_ndxUpdTimer.Start()
			format "[NeoDex Updater] Pruefung in % Sekunden geplant.\n" (this.startupDelayMs / 1000)
		)
		catch
		(
			format "[NeoDex Updater] Timer konnte nicht gestartet werden: %\n" (getCurrentException())
		)
		ok
	)
)

global NeoDexAutoUpdater = NeoDexAutoUpdaterStruct()

-- ============================================================
-- Einstieg
-- ============================================================
(
	local forced = false
	try (forced = (::_ndxForceUpdateCheck == true)) catch (forced = false)

	if forced then
	(
		-- "Jetzt pruefen" aus dem Settings-Dialog: der Nutzer wartet auf
		-- eine Antwort, also sofort und ohne Intervallsperre.
		::_ndxForceUpdateCheck = false
		::NeoDexAutoUpdater.runCheck force:true
	)
	else
		::NeoDexAutoUpdater.scheduleCheck()
)
