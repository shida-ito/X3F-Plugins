local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrLogger = import 'LrLogger'
local LrProgressScope = import 'LrProgressScope'

local logger = LrLogger('X3FConvert')
logger:enable("logfile") 

local function getExtractionBinary()
    local pluginPath = _PLUGIN.path
    -- Depending on how the plugin is structured, bin might be directly under plugin root
    -- or in a specified subfolder. We put it in 'bin'.
    local binaryPath = LrPathUtils.child(pluginPath, "bin")
    binaryPath = LrPathUtils.child(binaryPath, "x3f_extract")
    return binaryPath
end

local function main()
    LrTasks.startAsyncTask(function()
        local catalog = LrApplication.activeCatalog()
        local binary = getExtractionBinary()

        if not LrFileUtils.exists(binary) then
            LrDialogs.message("Error", "Could not find x3f_extract binary at: " .. binary, "critical")
            return
        end

        -- Ensure binary is executable (macOS/Linux)
        if MAC_ENV then
             local status = LrTasks.execute("chmod +x " .. string.format("%q", binary))
        end

        local result = LrDialogs.runOpenPanel({
            title = "Select Folder with X3F Files",
            canChooseDirectories = true,
            canChooseFiles = false, -- Only folders
            allowsMultipleSelection = false,
        })

        if not result then return end
        local sourceDir = result[1]

        logger:info("Selected source dir: " .. sourceDir)

        -- Output Directory Selection
        local outputDir = sourceDir
        local verb = LrDialogs.confirm(
            "Output Folder",
            "Do you want to save DNG files in the same folder as the X3F files?\n(Default is the same folder)",
            "Yes (Default)",
            "Select Different Folder"
        )
        
        if verb == "cancel" then
            local outResult = LrDialogs.runOpenPanel({
                title = "Select Output Folder for DNG Files",
                canChooseDirectories = true,
                canChooseFiles = false,
                allowsMultipleSelection = false,
            })
            if outResult then
                outputDir = outResult[1]
                logger:info("Selected output dir: " .. outputDir)
            else
                -- User cancelled output selection
                return 
            end
        end

        local x3fFiles = {}
        for file in LrFileUtils.directoryEntries(sourceDir) do
            if string.lower(LrPathUtils.extension(file)) == "x3f" then
                table.insert(x3fFiles, file)
            end
        end

        if #x3fFiles == 0 then
            LrDialogs.message("Info", "No .x3f files found in selected folder.")
            return
        end

        local progressScope = LrProgressScope({
            title = "Converting X3F Files (Kalpanika)",
        })
        progressScope:setPortionComplete(0, #x3fFiles)

        local convertedCount = 0
        local errors = {}

        for i, x3fPath in ipairs(x3fFiles) do
            if progressScope:isCanceled() then break end

            local filename = LrPathUtils.leafName(x3fPath)
            progressScope:setCaption("Processing: " .. filename)

            -- Calculate Output Paths
            local dngFilename = LrPathUtils.replaceExtension(filename, "dng")
            local dngPath = LrPathUtils.child(outputDir, dngFilename)
            local success = false

            -- Check if DNG exists (clean name)
            if LrFileUtils.exists(dngPath) then
                logger:info("DNG already exists for " .. filename)
                -- success = true -- No need to set this here, as it's only used in the 'else' block
            else
                -- Convert
                 -- Command: x3f_extract -dng -o <dir> <x3f_file>
                 -- Explicitly specifying output directory
                local cmd = string.format('"%s" -dng -o "%s" "%s"', binary, outputDir, x3fPath)
                
                logger:info("Executing: " .. cmd)

                local retval = LrTasks.execute(cmd)
                
                local success = false
                if retval == 0 then
                    -- The tool outputs 'filename.X3F.dng' (appending extension) in the output dir
                    local rawOutput = LrPathUtils.child(outputDir, filename .. ".dng")
                    local rawOutputUpper = LrPathUtils.child(outputDir, filename .. ".DNG") -- just in case

                    -- Retry loop for file existence
                    local function waitForFile(path)
                        for attempt = 1, 10 do
                            if LrFileUtils.exists(path) then return true end
                            LrTasks.sleep(0.5) -- wait 500ms
                        end
                        return false
                    end

                    -- Check for raw output and rename it
                    local detectedArtifact = nil
                    if waitForFile(rawOutput) then
                        detectedArtifact = rawOutput
                    elseif waitForFile(rawOutputUpper) then
                        detectedArtifact = rawOutputUpper
                    -- Fallback: maybe it named it correctly directly? (unlikely for this tool but possible)
                    elseif waitForFile(dngPath) then
                         success = true -- It IS correct already
                    end

                    if detectedArtifact then
                        -- Rename to clean .dng
                        local renamed, reason = LrFileUtils.move(detectedArtifact, dngPath)
                        if renamed then
                            success = true
                            logger:info("Renamed " .. LrPathUtils.leafName(detectedArtifact) .. " to " .. LrPathUtils.leafName(dngPath))
                            
                            -- Copy Metadata using exiftool
                            local exiftoolPath = LrPathUtils.child(_PLUGIN.path, "bin")
                            exiftoolPath = LrPathUtils.child(exiftoolPath, "exiftool")
                            
                            local exiftoolCmd
                            if LrFileUtils.exists(exiftoolPath) then
                                -- Ensure executable permission for bundled exiftool
                                if MAC_ENV then
                                    LrTasks.execute("chmod +x " .. string.format("%q", exiftoolPath))
                                end
                                exiftoolCmd = string.format('"%s" -overwrite_original -tagsfromfile "%s" -all:all "%s"', exiftoolPath, x3fPath, dngPath)
                            else
                                -- Fallback to system exiftool
                                exiftoolCmd = string.format('/usr/local/bin/exiftool -overwrite_original -tagsfromfile "%s" -all:all "%s"', x3fPath, dngPath)
                            end

                            logger:info("Copying metadata: " .. exiftoolCmd)
                            local exitStatus = LrTasks.execute(exiftoolCmd)
                            if exitStatus ~= 0 then
                                logger:warn("Bundled Exiftool failed with exit code: " .. exitStatus .. ". Trying system exiftool...")
                                -- Try just 'exiftool' without path or explicit /usr/local/bin
                                local fallbackCmd = string.format('/usr/local/bin/exiftool -overwrite_original -tagsfromfile "%s" -all:all "%s"', x3fPath, dngPath)
                                if not LrFileUtils.exists("/usr/local/bin/exiftool") then
                                     fallbackCmd = string.format('exiftool -overwrite_original -tagsfromfile "%s" -all:all "%s"', x3fPath, dngPath)
                                end
                                
                                logger:info("Retrying with system exiftool: " .. fallbackCmd)
                                exitStatus = LrTasks.execute(fallbackCmd)
                                if exitStatus ~= 0 then
                                     logger:warn("System Exiftool retry failed with exit code: " .. exitStatus)
                                else
                                     logger:info("Metadata copied successfully using system exiftool.")
                                end
                            else
                                logger:info("Metadata copied successfully.")
                            end

                        else
                            logger:error("Failed to rename " .. detectedArtifact .. " to " .. dngPath .. ": " .. (reason or "unknown"))
                            -- If delete fails, we might still have the artifact, but we consider this a partial failure or success?
                            -- If we can't rename, let's at least leave it and count as success but warn?
                            -- User wants .dng, so this is an error condition for strictness.
                        end
                    end
                end

                if success then
                    convertedCount = convertedCount + 1
                else
                    logger:error("Conversion failed for " .. filename .. " (retval: " .. retval .. ")")
                    if retval == 0 then
                         logger:error("File was not found or could not be renamed. Expected final path: " .. dngPath)
                         -- Debug: List files in directory to see what was created
                         logger:error("Files in directory:")
                         for entry in LrFileUtils.directoryEntries(sourceDir) do
                             logger:error("  - " .. LrPathUtils.leafName(entry))
                         end
                    end
                    table.insert(errors, filename)
                end
            end
            
            progressScope:setPortionComplete(i, #x3fFiles)
        end

        local summary = "Processed " .. #x3fFiles .. " files.\nConverted: " .. convertedCount
        if #errors > 0 then
            local logPath = ""
            if MAC_ENV then
                logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('home'), "Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FConvert.log")
            else
                 -- Fallback for Windows (usually in Documents)
                 logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "X3FConvert.log")
            end
            
            summary = summary .. "\nFailed: " .. #errors .. "\n\nPlease check the log file at:\n" .. logPath
        end
        
        local canceled = progressScope:isCanceled()
        progressScope:done()
        
        if not canceled then
            LrDialogs.message("X3F Conversion Complete", summary)
        end

    end) 
end

main()
