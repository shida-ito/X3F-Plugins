on run
	try
		set sourceFolder to choose folder with prompt "Select Folder with X3F files"
	on error number -128
		return
	end try
	set sourcePath to POSIX path of sourceFolder

	-- CPU コア数から並列処理数のデフォルトを計算（LR プラグインと同じ方式）
	set cpuCount to (do shell script "sysctl -n hw.logicalcpu") as integer
	set defaultJobs to (cpuCount div 2)
	if defaultJobs < 1 then set defaultJobs to 1

	-- 全設定を1つのダイアログで表示（各行: ラベル: 値）
	set defaultSettings to "Jobs: " & (defaultJobs as string) & return & "LJPEG: yes" & return & "Denoise: yes" & return & "Normalize WL: yes"
	set settingsResult to display dialog "X3F Conversion Settings" & return & return & "各項目のコロン右の値を編集してください（yes / no）：" ¬
		default answer defaultSettings ¬
		buttons {"キャンセル (Cancel)", "OK"} default button "OK" ¬
		with title "X3F Conversion Settings"
	if button returned of settingsResult is not "OK" then return
	set settingsText to text returned of settingsResult

	-- 各行に分割して設定値を取得
	set AppleScript's text item delimiters to return
	set settingsLines to text items of settingsText
	set AppleScript's text item delimiters to ": "
	set concurrency to text item 2 of (item 1 of settingsLines)
	set ljpegRaw to text item 2 of (item 2 of settingsLines)
	set denoiseRaw to text item 2 of (item 3 of settingsLines)
	set normRaw to text item 2 of (item 4 of settingsLines)
	set AppleScript's text item delimiters to ""

	-- ブール変換（yes / y / YES → true）
	if ljpegRaw is "yes" or ljpegRaw is "y" or ljpegRaw is "Yes" or ljpegRaw is "Y" or ljpegRaw is "YES" then
		set useLjpeg to "true"
	else
		set useLjpeg to "false"
	end if
	if denoiseRaw is "no" or denoiseRaw is "n" or denoiseRaw is "No" or denoiseRaw is "N" or denoiseRaw is "NO" then
		set useDenoise to "false"
	else
		set useDenoise to "true"
	end if
	if normRaw is "yes" or normRaw is "y" or normRaw is "Yes" or normRaw is "Y" or normRaw is "YES" then
		set useNormalizeWL to "true"
	else
		set useNormalizeWL to "false"
	end if

	-- Resource path resolution (Relative to the script file)
	set myPath to (path to me as string)
	set AppleScript's text item delimiters to ":"
	set pathItems to text items of myPath
	if (last text item of myPath is "") then
		-- Directory
		set parentPath to (items 1 thru -3 of pathItems as string) & ":"
	else
		-- File
		set parentPath to (items 1 thru -2 of pathItems as string) & ":"
	end if
	set AppleScript's text item delimiters to ""
	set resourcesPath to POSIX path of (parentPath & "X3F_Resources:")

	set binaryPath to resourcesPath & "bin/x3f_extract"
	set exiftoolPath to resourcesPath & "bin/exiftool"
	set convertScriptPath to resourcesPath & "convert.sh"

	display notification "バックグラウンドで処理中" with title "X3F Converter" subtitle "X3F変換を開始します..."

	set cmd to "bash " & quoted form of convertScriptPath & " " & quoted form of sourcePath & " " & quoted form of sourcePath & " " & quoted form of binaryPath & " " & useLjpeg & " " & useDenoise & " " & quoted form of concurrency & " " & quoted form of exiftoolPath & " " & useNormalizeWL

	try
		do shell script cmd

		display notification "Capture Oneへのインポートを開始します..." with title "X3F Converter"

		tell application "Capture One"
			activate
		end tell

		try
			set importScript to "tell application \"Capture One\" to import (POSIX file \"" & sourcePath & "\")"
			run script importScript
		end try

		display alert "Success" message "X3Fファイルの変換が完了しました！" as informational
	on error errMsg
		display alert "Error" message "変換に失敗しました。" & return & return & "詳細: " & errMsg & return & return & "場所: " & resourcesPath as critical
	end try
end run
