on run
	set sourceFolder to choose folder with prompt "Select Folder with X3F files"
	set sourcePath to POSIX path of sourceFolder

	set outputChoice to button returned of (display dialog "DNG出力先フォルダを設定してください。" buttons {"ソースと同じ (Same as Source)", "フォルダを選択... (Choose...)"} default button "ソースと同じ (Same as Source)" with title "X3F Conversion Settings")
	if outputChoice is "フォルダを選択... (Choose...)" then
		set outputFolder to choose folder with prompt "DNG出力先フォルダを選択"
		set outputPath to POSIX path of outputFolder
	else
		set outputPath to sourcePath
	end if

	set settingsResult to (display dialog "同時並列処理数 (Parallel Jobs):" default answer "4" buttons {"キャンセル (Cancel)", "OK"} default button "OK" with title "X3F Conversion Settings")
	if button returned of settingsResult is not "OK" then return
	set concurrency to text returned of settingsResult
	
	set denoiseResult to (display dialog "デノイズ処理（Denoise）を適用しますか？" buttons {"適用しない (No)", "適用する (Yes)"} default button "適用する (Yes)" with title "X3F Conversion Settings")
	if button returned of denoiseResult is "適用する (Yes)" then
		set useDenoise to "true"
	else
		set useDenoise to "false"
	end if

	set ljpegResult to (display dialog "Lossless JPEG (LJPEG) 圧縮を適用しますか？" & return & "（ファイルサイズ約60%削減・画質劣化なし）" buttons {"適用しない (No)", "適用する (Yes)"} default button "適用する (Yes)" with title "X3F Conversion Settings")
	if button returned of ljpegResult is "適用する (Yes)" then
		set useLJPEG to "true"
	else
		set useLJPEG to "false"
	end if

	set normalizeResult to (display dialog "ホワイトレベルの正規化 (Normalize White Level) を使用しますか？" & return & "（Capture One のハイライト問題を修正します）" buttons {"使用しない (No)", "使用する (Yes)"} default button "使用する (Yes)" with title "X3F Conversion Settings")
	if button returned of normalizeResult is "使用する (Yes)" then
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
	set resourcesPath to POSIX path of (parentPath & "X3F_Resources:")
	
	set binaryPath to resourcesPath & "bin/x3f_extract"
	set exiftoolPath to resourcesPath & "bin/exiftool"
	set convertScriptPath to resourcesPath & "convert.sh"
	
	display notification "バックグラウンドで処理中" with title "X3F Converter" subtitle "X3F変換を開始します..."
	
	set cmd to "bash " & quoted form of convertScriptPath & " " & quoted form of sourcePath & " " & quoted form of outputPath & " " & quoted form of binaryPath & " " & useLJPEG & " " & useDenoise & " " & quoted form of concurrency & " " & quoted form of exiftoolPath & " " & useNormalizeWL
	
	try
		do shell script cmd
		
		display notification "Capture Oneへのインポートを開始します..." with title "X3F Converter"
		
		tell application "Capture One"
			activate
		end tell
		
		try
			set importScript to "tell application \"Capture One\" to import (POSIX file \"" & outputPath & "\")"
			run script importScript
		end try
		
		display alert "Success" message "X3Fファイルの変換が完了しました！" as informational
	on error errMsg
		display alert "Error" message "変換に失敗しました。" & return & return & "詳細: " & errMsg & return & return & "場所: " & resourcesPath as critical
	end try
end run
