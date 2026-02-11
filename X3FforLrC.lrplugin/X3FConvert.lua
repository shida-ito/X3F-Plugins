local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrDate = import 'LrDate'

local logger = LrLogger('X3FforLrC')
logger:enable("logfile") 

local function getExtractionBinary()
    local pluginPath = _PLUGIN.path
    local binaryPath = LrPathUtils.child(pluginPath, "bin")
    binaryPath = LrPathUtils.child(binaryPath, "x3f_extract")
    return binaryPath
end

local function getCpuCoreCount()
    if not MAC_ENV then return 1 end
    
    local tempFile = LrPathUtils.child(LrPathUtils.getStandardFilePath('temp'), "lr_cpu_count.txt")
    local cmd = "sysctl -n hw.ncpu > " .. string.format("%q", tempFile)
    
    local status = LrTasks.execute(cmd)
    local count = 1
    
    if status == 0 then
        local content = LrFileUtils.readFile(tempFile)
        if content then
            count = tonumber(content:match("%d+")) or 1
        end
        LrFileUtils.delete(tempFile)
    end
    
    logger:info("Detected CPU Core Count: " .. tostring(count))
    return count
end

local function main()
    LrTasks.startAsyncTask(function()
    LrFunctionContext.callWithContext('X3FConvert', function(context)
        logger:info("Starting X3F Conversion process")
        local catalog = LrApplication.activeCatalog()
        local binary = getExtractionBinary()

        if not LrFileUtils.exists(binary) then
            LrDialogs.message("Error", "Could not find x3f_extract binary at: " .. binary, "critical")
            return
        end

        if MAC_ENV then
             LrTasks.execute("chmod +x " .. string.format("%q", binary))
        end

        -- 1. Select Source Folder
        local result = LrDialogs.runOpenPanel({
            title = "Select Folder with X3F Files",
            canChooseDirectories = true,
            canChooseFiles = false,
            allowsMultipleSelection = false,
        })
        if not result then return end
        local sourceDir = result[1]

        -- 2. Detect Cores and Prepare Settings UI
        local coreCount = getCpuCoreCount()
        local recommendedConcurrency = math.max(1, math.floor(coreCount / 2))
        
        local concurrencyItems = {}
        for i = 1, coreCount do
            table.insert(concurrencyItems, { title = tostring(i), value = i })
        end

        local f = LrView.osFactory()
        local properties = LrBinding.makePropertyTable(context)
        properties.useParallel = true
        properties.concurrency = recommendedConcurrency
        properties.outputDir = sourceDir
        properties.useLJPEG = true
        properties.useDenoise = true

        local c = f:column {
            spacing = f:control_spacing(),
            bind_to_object = properties,
            f:row {
                f:static_text { title = "Parallel Processing:", width = LrView.share "label_width" },
                f:checkbox { value = LrView.bind "useParallel" },
                f:static_text { title = "Run multiple conversions simultaneously" },
            },
            f:row {
                f:static_text { title = "Concurrent Jobs:", width = LrView.share "label_width" },
                f:popup_menu {
                    value = LrView.bind "concurrency",
                    items = concurrencyItems,
                    enabled = LrView.bind "useParallel",
                },
                f:static_text { title = "(Max: " .. coreCount .. ", Recommended: " .. recommendedConcurrency .. ")" },
            },
            f:row {
                f:static_text { title = "Compression:", width = LrView.share "label_width" },
                f:checkbox { title = "Use Lossless JPEG (Smaller DNGs)", value = LrView.bind "useLJPEG" },
            },
            f:row {
                f:static_text { title = "Denoise:", width = LrView.share "label_width" },
                f:checkbox { title = "Apply denoise during conversion", value = LrView.bind "useDenoise" },
            },
            f:separator { fill_horizontal = 1 },
            f:row {
                f:static_text { title = "Output Folder:", width = LrView.share "label_width" },
                f:edit_field { value = LrView.bind "outputDir", fill_horizontal = 1 },
                f:push_button {
                    title = "Browse...",
                    action = function()
                        local outResult = LrDialogs.runOpenPanel({
                            title = "Select Output Folder",
                            canChooseDirectories = true,
                            canChooseFiles = false,
                            allowsMultipleSelection = false,
                        })
                        if outResult then
                            properties.outputDir = outResult[1]
                        end
                    end,
                },
            },
        }

        local dialogResult = LrDialogs.presentModalDialog({
            title = "X3F Conversion Settings",
            contents = c,
        })

        if dialogResult == "cancel" then return end

        local outputDir = properties.outputDir
        local useLJPEG = properties.useLJPEG
        local useDenoise = properties.useDenoise
        local recursive = true
        local maxConcurrency = properties.useParallel and properties.concurrency or 1

        -- 3. Collect Files
        local x3fFiles = {}
        local function collectFiles(dir)
            for file in LrFileUtils.directoryEntries(dir) do
                if LrFileUtils.exists(file) == "file" then
                    if string.lower(LrPathUtils.extension(file) or "") == "x3f" then
                        table.insert(x3fFiles, file)
                    end
                elseif recursive and LrFileUtils.exists(file) == "directory" then
                    collectFiles(file)
                end
            end
        end
        collectFiles(sourceDir)

        if #x3fFiles == 0 then
            LrDialogs.message("Info", "No .x3f files found in selected folder.")
            return
        end

        -- 4. Process Files (Parallel Worker Pattern)
        local progressScope = LrProgressScope({
            title = "Converting X3F Files (Kalpanika)",
        })
        progressScope:setPortionComplete(0, #x3fFiles)

        local startTime = LrDate.currentTime()
        local convertedCount = 0
        local errors = {}
        local fileIndex = 1
        local activeWorkers = 0
        
        -- Fallback for LrTasks.createSemaphore (added in Lr 6.0)
        local lock
        if LrTasks.createSemaphore then
            lock = LrTasks.createSemaphore(1)
        else
            -- Simple fallback lock using a boolean and sleep
            local isLocked = false
            lock = {
                wait = function()
                    while isLocked do LrTasks.sleep(0.01) end
                    isLocked = true
                end,
                post = function()
                    isLocked = false
                end
            }
        end

        local function processOneFile(x3fPath)
            local filename = LrPathUtils.leafName(x3fPath)
            local dngFilename = LrPathUtils.replaceExtension(filename, "dng")
            local dngPath = LrPathUtils.child(outputDir, dngFilename)
            local success = false

            if LrFileUtils.exists(dngPath) then
                logger:info("DNG already exists for " .. filename)
                success = true
            else
                local compressFlag = useLJPEG and " -ljpeg" or ""
                local denoiseFlag = useDenoise and "" or " -no-denoise"
                local cmd = string.format('"%s" -dng%s%s -o "%s" "%s"', binary, compressFlag, denoiseFlag, outputDir, x3fPath)
                logger:info("Executing: " .. cmd)
                local retval = LrTasks.execute(cmd)
                
                if retval == 0 then
                    local rawOutput = LrPathUtils.child(outputDir, filename .. ".dng")
                    local rawOutputUpper = LrPathUtils.child(outputDir, filename .. ".DNG")

                    local function waitForFile(path)
                        for attempt = 1, 30 do -- Up to 3 seconds with 0.1s steps
                            if LrFileUtils.exists(path) then return true end
                            LrTasks.sleep(0.1)
                        end
                        return false
                    end

                    local detectedArtifact = nil
                    if waitForFile(rawOutput) then
                        detectedArtifact = rawOutput
                    elseif waitForFile(rawOutputUpper) then
                        detectedArtifact = rawOutputUpper
                    elseif LrFileUtils.exists(dngPath) then
                        success = true
                    end

                    if detectedArtifact then
                        local renamed, reason = LrFileUtils.move(detectedArtifact, dngPath)
                        if renamed then
                            success = true
                            
                            -- Exiftool
                            local exiftoolPath = LrPathUtils.child(_PLUGIN.path, "bin")
                            exiftoolPath = LrPathUtils.child(exiftoolPath, "exiftool")
                            local exiftoolCmd
                            if LrFileUtils.exists(exiftoolPath) then
                                if MAC_ENV then LrTasks.execute("chmod +x " .. string.format("%q", exiftoolPath)) end
                                exiftoolCmd = string.format('"%s" -overwrite_original -tagsfromfile "%s" -all:all "%s"', exiftoolPath, x3fPath, dngPath)
                            else
                                exiftoolCmd = string.format('exiftool -overwrite_original -tagsfromfile "%s" -all:all "%s"', x3fPath, dngPath)
                            end
                            LrTasks.execute(exiftoolCmd)
                        end
                    end
                end
            end

            lock:wait()
            if success then
                convertedCount = convertedCount + 1
            else
                table.insert(errors, filename)
            end
            progressScope:setPortionComplete(convertedCount + #errors, #x3fFiles)
            progressScope:setCaption(string.format("Processing... (%d/%d)", convertedCount + #errors, #x3fFiles))
            lock:post()
        end

        local function worker()
            while true do
                local currentFile = nil
                lock:wait()
                if fileIndex <= #x3fFiles and not progressScope:isCanceled() then
                    currentFile = x3fFiles[fileIndex]
                    fileIndex = fileIndex + 1
                end
                lock:post()

                if not currentFile then break end
                processOneFile(currentFile)
            end
            
            lock:wait()
            activeWorkers = activeWorkers - 1
            lock:post()
        end

        activeWorkers = maxConcurrency
        for i = 1, maxConcurrency do
            LrTasks.startAsyncTask(worker)
        end

        -- Wait for all workers to finish
        while true do
            local done = false
            lock:wait()
            if activeWorkers == 0 then done = true end
            lock:post()
            if done then break end
            LrTasks.sleep(0.2)
        end

        -- 5. Final Summary
        local endTime = LrDate.currentTime()
        local duration = endTime - startTime
        local minutes = math.floor(duration / 60)
        local seconds = math.floor(duration % 60)
        local timeString = string.format("%d min %d sec", minutes, seconds)
        if minutes == 0 then
            timeString = string.format("%d sec", seconds)
        end

        progressScope:done()
        local summary = string.format("Processed %d files.\nConverted: %d\nTotal Time: %s", #x3fFiles, convertedCount, timeString)
        if #errors > 0 then
            local logPath = ""
            if MAC_ENV then
                logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('home'), "Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FforLrC.log")
            else
                logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "X3FforLrC.log")
            end
            summary = summary .. string.format("\n\nFailed: %d\n\nPlease check the log file at:\n%s", #errors, logPath)
        end
        
        if not progressScope:isCanceled() then
            LrDialogs.message("X3F Conversion Complete", summary)
        end
    end)
    end)
end

main()
