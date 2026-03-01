use framework "AppKit"
use framework "Foundation"
use scripting additions

on run
	set sourceFolder to choose folder with prompt "Select Folder with X3F files"
	set sourcePath to POSIX path of sourceFolder

	-- CPU コア数から並列処理数のデフォルトを計算（LR プラグインと同じ方式）
	set cpuCount to (do shell script "sysctl -n hw.logicalcpu") as integer
	set defaultJobs to (cpuCount div 2)
	if defaultJobs < 1 then set defaultJobs to 1

	-- チェックボックス付き設定ダイアログを構築
	set accessoryView to current application's NSView's alloc()'s initWithFrame_({{0, 0}, {360, 140}})

	-- Concurrent Jobs ラベルとテキストフィールド
	set jobsLabel to current application's NSTextField's labelWithString_("Concurrent Jobs:")
	jobsLabel's setFrame_({{0, 110}, {140, 22}})

	set jobsField to current application's NSTextField's alloc()'s initWithFrame_({{150, 108}, {55, 24}})
	jobsField's setStringValue_((defaultJobs as string))
	jobsField's setBezeled_(true)
	jobsField's setDrawsBackground_(true)
	jobsField's setEditable_(true)

	-- チェックボックス
	set cbLjpeg to current application's NSButton's checkboxWithTitle_target_action_("LJPEG Compression  (reduce file size ~60%)", missing value, missing value)
	cbLjpeg's setFrame_({{0, 78}, {360, 22}})
	cbLjpeg's setState_(1)

	set cbDenoise to current application's NSButton's checkboxWithTitle_target_action_("Denoise", missing value, missing value)
	cbDenoise's setFrame_({{0, 50}, {360, 22}})
	cbDenoise's setState_(1)

	set cbNormalize to current application's NSButton's checkboxWithTitle_target_action_("Normalize WL  (fix Capture One yellow highlights)", missing value, missing value)
	cbNormalize's setFrame_({{0, 22}, {360, 22}})
	cbNormalize's setState_(0)

	accessoryView's addSubview_(jobsLabel)
	accessoryView's addSubview_(jobsField)
	accessoryView's addSubview_(cbLjpeg)
	accessoryView's addSubview_(cbDenoise)
	accessoryView's addSubview_(cbNormalize)

	-- アラートを作成して表示
	set theAlert to current application's NSAlert's new()
	theAlert's setMessageText_("X3F Conversion Settings")
	theAlert's addButtonWithTitle_("OK")
	theAlert's addButtonWithTitle_("キャンセル (Cancel)")
	theAlert's setAccessoryView_(accessoryView)
	theAlert's layout()

	set response to theAlert's runModal()
	if response as integer is not 1000 then return -- キャンセル (NSAlertFirstButtonReturn = 1000)

	-- 各値を取得
	set concurrency to jobsField's stringValue() as string
	if cbLjpeg's state() as integer is 1 then
		set useLjpeg to "true"
	else
		set useLjpeg to "false"
	end if
	if cbDenoise's state() as integer is 1 then
		set useDenoise to "true"
	else
		set useDenoise to "false"
	end if
	if cbNormalize's state() as integer is 1 then
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
