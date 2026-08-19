-- ============================================================================
--  BACKUP-TO-BOX  v2.3.7   "Backup Your Data to Box"
--  Executive Support — MAC-MAINT / MAC-HANDOFF family
--
--  v2.3.7 CHANGE:
--    • NEW MODE ⑥ CUSTOM BACKUP + DEFAULT FOLDERS (ZIP): the fixed standard set
--      (Desktop + Documents + Movies + Music + Pictures + Bookmarks) like Mode ①,
--      but the user CHOOSES the destination (Box / Network / OneDrive / external /
--      any writable path). No "Legal Hold" wording. ZIP, not RAW.
--
--  v2.3.6 CHANGE:
--    • NEW MODE ⑤ CUSTOM BACKUP + CHOOSE DESTINATION (ZIP): like Mode ②, the
--      user multi-selects folders, but ALSO picks the destination themselves —
--      Box, a mounted NETWORK share, ONEDRIVE, an external drive, or any
--      writable location. A Backup_<timestamp> folder is created inside the
--      chosen destination. Box is NOT required for this mode.
--
--  v2.3.5: Apple-default awareness — count only meaningful user files.
--  v2.3.4: scan file count first; auto-skip empty/missing standard folders.
--  v2.3.3: Standard set = Desktop + Documents + Movies + Music + Pictures + bookmarks.
--  v2.3.2: logs/receipts under /Users/Shared/BACKUP-TO-BOX (fallback ~/ then /tmp).
--  v2.3.1: FDA detection via SYSTEM TCC.db; bookmark status driven by real copy.
--    NOTE: the exported .app must itself be added to Full Disk Access.
--
--  MODES:
--    ① STANDARD CORPORATE BACKUP (ZIP) → Box — Desktop + Documents + Movies +
--       Music + Pictures + Safari/Chrome bookmarks. USE CASE: Legal Hold.
--    ② CUSTOM BACKUP (ZIP) → Box — user multi-selects folders (+ bookmarks).
--    ③ STANDARD CORPORATE — RAW (UNCOMPRESSED) → Box. USE CASE: Box-first migration.
--    ④ RESTORE — BOOKMARKS ONLY — restores Safari/Chrome bookmarks for new device.
--    ⑤ CUSTOM BACKUP + CHOOSE DESTINATION (ZIP) — user picks folders AND the
--    ⑥ CUSTOM BACKUP + DEFAULT FOLDERS (ZIP) — standard set (Desktop + Documents +
--       Movies + Music + Pictures + Bookmarks) → user picks destination (Box / Network / OneDrive / external).
--       destination (Box / network / OneDrive / external / any writable path).
--
--  Build:  Script Editor > paste > Export > Application > Sign to Run Locally.
-- ============================================================================

property appTitle : "Backup Your Data to Box"
property appVersion : "2.3.7"
property personalFolderName : "01. My Personal Folder"
property backupSubfolder : "recentBackup"
property LARGE_FILE_BYTES : 2.147483648E+9
property LONG_PATH_LIMIT : 240
property FREESPACE_HEADROOM : 1.1

global consoleUser, homeDir, serialNum, hostName, osVer, osBuild
global boxRoot, destDir, spaceRoot, destLabel, backupFolderName, outDir, logPath, htmlPath, runLog, ts, nowH
global findName, findSev, findDetail
global fdaGranted, backupMode, snapshotDir

on run
        set consoleUser to do shell script "/usr/bin/stat -f%Su /dev/console"
        set homeDir to (POSIX path of (path to home folder))
        if homeDir ends with "/" then set homeDir to text 1 thru -2 of homeDir
        set serialNum to do shell script "system_profiler SPHardwareDataType 2>/dev/null | awk '/Serial Number/{print $NF; exit}'"
        if serialNum is "" then set serialNum to "UNKNOWN"
        set hostName to do shell script "scutil --get ComputerName 2>/dev/null || hostname"
        set osVer to do shell script "sw_vers -productVersion"
        set osBuild to do shell script "sw_vers -buildVersion"
        set ts to do shell script "date +%Y-%m-%d_%H%M%S"
        set nowH to do shell script "date '+%b %d, %Y %I:%M %p %Z'"
        set findName to {}
        set findSev to {}
        set findDetail to {}
        set boxRoot to ""
        set destDir to ""
        set spaceRoot to ""
        set destLabel to ""

        set outDir to "/Users/Shared/BACKUP-TO-BOX/" & ts & "_" & serialNum
        try
                do shell script "mkdir -p " & quoted form of outDir
        end try
        try
                do shell script "test -w " & quoted form of outDir
        on error
                set outDir to homeDir & "/BACKUP-TO-BOX/" & ts & "_" & serialNum
                do shell script "mkdir -p " & quoted form of outDir
        end try
        try
                do shell script "test -w " & quoted form of outDir
        on error
                set outDir to (do shell script "mktemp -d /tmp/BACKUP-TO-BOX.XXXXXX")
        end try
        set snapshotDir to outDir & "/pre_restore_snapshot"
        set logPath to outDir & "/backup.log"
        set runLog to outDir & "/BoxBackupLog_" & ts & ".txt"
        set htmlPath to outDir & "/Backup_Receipt_" & ts & ".html"
        do shell script "echo '' > " & quoted form of logPath
        try
                do shell script "chmod -R 0777 " & quoted form of outDir & " 2>/dev/null || true"
        end try
        my logLine("=== " & appTitle & " v" & appVersion & " started ===")
        my logLine("User " & consoleUser & " | Host " & hostName & " | Serial " & serialNum & " | macOS " & osVer & " (" & osBuild & ")")
        my logLine("Output dir: " & outDir)

        display dialog "⚠️ Before continuing, make sure this app has the necessary permissions:" & return & return & "1. Privacy & Security ▸ Files and Folders (or Full Disk Access)." & return & "2. Privacy & Security ▸ Accessibility." & return & "3. Privacy & Security ▸ Full Disk Access (REQUIRED for bookmarks)." & return & return & "IMPORTANT: add THIS app (Backup Your Data to Box) to Full Disk Access — access granted to Script Editor does not transfer to the exported app." & return & return & "Click OK when you're ready to continue." buttons {"OK"} default button "OK" with title appTitle with icon note

        set fdaGranted to my hasFullDiskAccess()
        my logLine("Full Disk Access granted: " & fdaGranted)
        if not fdaGranted then
                try
                        set r to display dialog "🔒  Full Disk Access is not enabled for THIS app." & return & return & "Browser bookmarks (backup AND restore) require Full Disk Access for the app you are running (Backup Your Data to Box), not just Script Editor." & return & return & "Click 'Open Settings', add + enable this app, then QUIT and RE-RUN. You may continue now (folders still work; bookmarks skipped)." buttons {"Open Settings", "Continue Anyway"} default button "Open Settings" with title (appTitle & " — Full Disk Access") with icon caution
                        if button returned of r is "Open Settings" then
                                try
                                        do shell script "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'"
                                end try
                                display dialog "After enabling Full Disk Access for THIS app, QUIT and RE-RUN it so the change takes effect." buttons {"Quit", "Continue Anyway"} default button "Quit" with title appTitle with icon note
                                if button returned of result is "Quit" then return
                        end if
                on error number -128
                end try
        end if

        my writeModeInfo()
        try
                do shell script "open " & quoted form of (outDir & "/Backup_Modes_" & ts & ".html")
        end try

        set mode1 to "① Standard Corporate Backup — ZIP  (Legal Hold: Desktop + Documents + Movies + Music + Pictures + Bookmarks → Box)"
        set mode2 to "② Custom Backup — ZIP  (you choose the folders → Box)"
        set mode3 to "③ Standard Corporate — RAW / Uncompressed  (System Update / Box-first migration → Box)"
        set mode4 to "④ Restore — Bookmarks Only  (Safari & Chrome, for a new device)"
        set mode5 to "⑤ Custom Backup + Choose Destination — ZIP  (you pick the folders AND where to save: Box / Network / OneDrive / external)"
        set mode6 to "⑥ Custom Backup + Default Folders — ZIP  (Desktop + Documents + Movies + Music + Pictures + Bookmarks → you pick where to save: Box / Network / OneDrive / external)"
        set modeChoice to (choose from list {mode1, mode2, mode3, mode4, mode5, mode6} with prompt "Select a mode." & return & "(A detailed info page just opened.)" default items {mode1} with title (appTitle & " — Choose Mode") without empty selection allowed)
        if modeChoice is false then my bailOut("Cancelled at mode selection.")
        set chosen to item 1 of modeChoice
        if chosen starts with "①" then
                set backupMode to "Standard-ZIP"
        else if chosen starts with "②" then
                set backupMode to "Custom-ZIP"
        else if chosen starts with "③" then
                set backupMode to "Standard-RAW"
        else if chosen starts with "④" then
                set backupMode to "Restore-Bookmarks"
        else if chosen starts with "⑥" then
                set backupMode to "Standard-Dest"
        else
                set backupMode to "Custom-Dest"
        end if
        my logLine("Mode: " & backupMode)

        if backupMode is not "Custom-Dest" and backupMode is not "Standard-Dest" then
                set boxRoot to my detectBoxRoot()
                my logLine("Box root: " & boxRoot)
                if boxRoot is "" then
                        my addFinding("Box destination", "BLOCKER", "Could not find your Box folder. Make sure Box Drive is running and signed in.")
                        my writeReceipt(0, "0 B", "0 B", "NO-GO", "Not started", "Not captured")
                        try
                                do shell script "open " & quoted form of htmlPath
                        end try
                        display dialog "⚠️  Could not find your Box folder. Make sure Box Drive is running and signed in, then try again." buttons {"OK"} default button "OK" with title (appTitle & " — Box Not Found") with icon stop
                        return
                end if
                set destDir to boxRoot & "/" & personalFolderName & "/" & backupSubfolder
                set spaceRoot to boxRoot
                set destLabel to "Box ▸ " & personalFolderName & " ▸ " & backupSubfolder
        end if

        if backupMode is "Restore-Bookmarks" then
                my runRestoreBookmarks()
                return
        end if

        set isRaw to (backupMode is "Standard-RAW")

        set sourceFolders to {}
        if (backupMode is "Custom-ZIP") or (backupMode is "Custom-Dest") then
                display dialog "Tip: hold ⌘ (Command) to select multiple folders." buttons {"OK"} default button "OK" with title appTitle with icon note
                set picked to {}
                try
                        set picked to (choose folder with prompt "Select the folders you want to back up (hold ⌘ to select multiple):" with multiple selections allowed)
                on error number -128
                        my bailOut("Cancelled at folder selection.")
                end try
                if (count of picked) is 0 then my bailOut("No folders were selected.")
                repeat with f in picked
                        set end of sourceFolders to (POSIX path of f)
                end repeat

                if backupMode is "Custom-Dest" then
                        display dialog "Now choose the DESTINATION where the backup will be saved." & return & return & "This can be your Box folder, a mounted NETWORK share, OneDrive, an external drive, or any writable folder." buttons {"Choose Destination"} default button "Choose Destination" with title appTitle with icon note
                        set chosenDest to ""
                        try
                                set chosenDest to POSIX path of (choose folder with prompt "Choose the destination folder for this backup:" default location (path to home folder))
                        on error number -128
                                my bailOut("Cancelled at destination selection.")
                        end try
                        if chosenDest ends with "/" then set chosenDest to text 1 thru -2 of chosenDest
                        set destWritable to false
                        try
                                do shell script "test -d " & quoted form of chosenDest & " && test -w " & quoted form of chosenDest
                                set destWritable to true
                        end try
                        if not destWritable then
                                my addFinding("Chosen destination", "BLOCKER", chosenDest & " is not writable")
                                my writeReceipt(0, "-", "-", "NO-GO", "Not started", "Not captured")
                                try
                                        do shell script "open " & quoted form of htmlPath
                                end try
                                display dialog "⚠️  The destination you chose is not writable:" & return & return & chosenDest & return & return & "Pick a location you have write access to, then run again." buttons {"OK"} default button "OK" with title (appTitle & " — Destination Not Writable") with icon stop
                                return
                        end if
                        set destDir to chosenDest
                        set spaceRoot to chosenDest
                        set destLabel to chosenDest
                        my logLine("Custom destination: " & chosenDest)
                        my addFinding("Chosen destination", "OK", chosenDest)
                end if
        else
                set stdCandidates to {homeDir & "/Desktop", homeDir & "/Documents", homeDir & "/Movies", homeDir & "/Music", homeDir & "/Pictures"}
                repeat with c in stdCandidates
                        set cp to (c as text)
                        set folderLeaf to do shell script "basename " & quoted form of cp
                        set existsDir to false
                        try
                                do shell script "test -d " & quoted form of cp
                                set existsDir to true
                        end try
                        if existsDir then
                                set fcount to my effectiveFileCount(cp)
                                if fcount > 0 then
                                        set end of sourceFolders to cp
                                        my addFinding("Included: " & folderLeaf, "OK", (fcount as text) & " user file(s) — Apple defaults ignored")
                                        my logLine("Standard set INCLUDE " & folderLeaf & " (" & fcount & " meaningful files)")
                                else
                                        my addFinding("Skipped: " & folderLeaf, "WARN", "Only Apple default items (.localized / empty library) — automatically skipped")
                                        my logLine("Standard set SKIP " & folderLeaf & " (no meaningful user files)")
                                end if
                        else
                                my addFinding("Skipped missing: " & folderLeaf, "WARN", cp & " not found — automatically skipped")
                                my logLine("Standard set SKIP " & folderLeaf & " (missing)")
                        end if
                end repeat
                if (count of sourceFolders) is 0 then my bailOut("None of the standard folders (Desktop/Documents/Movies/Music/Pictures) contained any meaningful user files to back up.")
                if backupMode is "Standard-Dest" then
                        display dialog "Now choose the DESTINATION where the backup will be saved." & return & return & "This can be your Box folder, a mounted NETWORK share, OneDrive, an external drive, or any writable folder." buttons {"Choose Destination"} default button "Choose Destination" with title appTitle with icon note
                        set chosenDest to ""
                        try
                                set chosenDest to POSIX path of (choose folder with prompt "Choose the destination folder for this backup:" default location (path to home folder))
                        on error number -128
                                my bailOut("Cancelled at destination selection.")
                        end try
                        if chosenDest ends with "/" then set chosenDest to text 1 thru -2 of chosenDest
                        set destWritable to false
                        try
                                do shell script "test -d " & quoted form of chosenDest & " && test -w " & quoted form of chosenDest
                                set destWritable to true
                        end try
                        if not destWritable then
                                my addFinding("Chosen destination", "BLOCKER", chosenDest & " is not writable")
                                my writeReceipt(0, "-", "-", "NO-GO", "Not started", "Not captured")
                                try
                                        do shell script "open " & quoted form of htmlPath
                                end try
                                display dialog "⚠️  The destination you chose is not writable:" & return & return & chosenDest & return & return & "Pick a location you have write access to, then run again." buttons {"OK"} default button "OK" with title (appTitle & " — Destination Not Writable") with icon stop
                                return
                        end if
                        set destDir to chosenDest
                        set spaceRoot to chosenDest
                        set destLabel to chosenDest
                        my logLine("Chosen destination: " & chosenDest)
                        my addFinding("Chosen destination", "OK", chosenDest)
                end if
        end if

        set totalBytes to 0
        set totalFiles to 0
        repeat with p in sourceFolders
                set pp to (p as text)
                set b to 0
                set c to 0
                try
                        set b to ((do shell script "du -sk " & quoted form of pp & " 2>/dev/null | awk '{print $1}'") as integer) * 1024
                end try
                try
                        set c to (do shell script "find " & quoted form of pp & " -type f 2>/dev/null | wc -l | tr -d ' '") as integer
                end try
                set totalBytes to totalBytes + b
                set totalFiles to totalFiles + c
                my logLine("Selected: " & pp & "  (" & c & " files, " & my humanSize(b) & ")")
                my scanFolder(pp)
        end repeat

        set backupFolderName to "Backup_" & ts
        set finalBackupPath to destDir & "/" & backupFolderName
        set destOK to true
        try
                do shell script "mkdir -p " & quoted form of finalBackupPath & " && test -w " & quoted form of finalBackupPath
        on error
                set destOK to false
        end try
        if destOK then
                my addFinding("Destination writable", "OK", finalBackupPath)
        else
                my addFinding("Destination writable", "BLOCKER", "Cannot write to " & finalBackupPath)
        end if

        set freeBytes to 0
        try
                set freeBytes to ((do shell script "df -P -k " & quoted form of spaceRoot & " 2>/dev/null | awk 'NR==2{print $4}'") as integer) * 1024
        end try
        if freeBytes > (totalBytes * FREESPACE_HEADROOM) then
                my addFinding("Free disk space", "OK", my humanSize(freeBytes) & " free vs ~" & my humanSize(totalBytes))
        else
                my addFinding("Free disk space", "WARN", "Only " & my humanSize(freeBytes) & " free vs ~" & my humanSize(totalBytes) & " — may stall sync/copy")
        end if
        if isRaw then my addFinding("RAW mode", "WARN", "Uncompressed copy — larger footprint and slower sync than ZIP (by design)")
        if not fdaGranted then my addFinding("Browser bookmarks", "WARN", "Full Disk Access not granted for this app — bookmarks will be skipped")

        set blockers to my countSeverity("BLOCKER")
        set warns to my countSeverity("WARN")
        set decision to "GO"
        if blockers > 0 then
                set decision to "NO-GO"
        else if warns > 0 then
                set decision to "REVIEW"
        end if
        my logLine("Scan complete. Blockers=" & blockers & " Warnings=" & warns & " Decision=" & decision)

        if decision is "NO-GO" then
                my writeReceipt(totalFiles, my humanSize(totalBytes), my humanSize(freeBytes), decision, "Not started", "Not captured")
                try
                        do shell script "open " & quoted form of htmlPath
                end try
                display dialog "🛑  Backup blocked by the pre-flight scan. See the report that just opened, resolve the issue(s), and run again." buttons {"OK"} default button "OK" with title (appTitle & " — Cannot Proceed") with icon stop
                return
        end if

        set modeWord to "ZIP (compressed)"
        if isRaw then set modeWord to "RAW (uncompressed — Box-first)"
        set warnLine to ""
        if warns > 0 then set warnLine to return & "⚠️  " & warns & " note(s)/warning(s) — see the report (includes auto-skipped folders)." & return
        set confMsg to "Mode: " & backupMode & "  [" & modeWord & "]" & return & return & (count of sourceFolders) & " folder(s) with real content → destination." & return & "   • Files: " & totalFiles & return & "   • Total size: " & my humanSize(totalBytes) & return & "   • Plus: Safari & Chrome bookmarks" & warnLine & return & "Destination:  " & destLabel & " ▸ " & backupFolderName & return & return & "Proceed?"
        try
                set r to display dialog confMsg buttons {"Cancel", "Yes"} default button "Yes" cancel button "Cancel" with title (appTitle & " — Confirm") with icon note
        on error number -128
                my bailOut("Backup cancelled by user.")
        end try

        set bmSummary to my captureBookmarks(finalBackupPath, isRaw)

        set okCount to 0
        set failCount to 0
        set totalFolders to count of sourceFolders
        set folderIndex to 0
        repeat with p in sourceFolders
                set folderIndex to folderIndex + 1
                set sourcePath to (p as text)
                set folderName to do shell script "basename " & quoted form of sourcePath
                try
                        display dialog "Backing up folder " & folderIndex & " of " & totalFolders & ":" & return & folderName buttons {"OK"} default button "OK" with title appTitle giving up after 1
                end try
                if isRaw then
                        set tgt to finalBackupPath & "/" & folderName
                        my logLine("RAW copy (" & folderIndex & "/" & totalFolders & "): " & sourcePath & " -> " & tgt)
                        set ok to my rawCopy(sourcePath, tgt)
                else
                        set zipPath to finalBackupPath & "/" & folderName & ".zip"
                        my logLine("ZIP (" & folderIndex & "/" & totalFolders & "): " & sourcePath & " -> " & zipPath)
                        set ok to my makeZip(sourcePath, zipPath)
                end if
                if ok is true then
                        set okCount to okCount + 1
                        do shell script "echo 'Backed up: " & sourcePath & "' >> " & quoted form of runLog
                else
                        set failCount to failCount + 1
                        my addFinding("Backup failed: " & folderName, "WARN", "See log for details")
                        do shell script "echo 'FAILED: " & sourcePath & "' >> " & quoted form of runLog
                end if
        end repeat

        set finalResult to (okCount as text) & " of " & totalFolders & " folder(s) backed up (" & modeWord & ")"
        if failCount > 0 then set finalResult to finalResult & " (" & failCount & " failed)"
        my writeReceipt(totalFiles, my humanSize(totalBytes), my humanSize(freeBytes), decision, finalResult, bmSummary)
        my logLine("=== Completed. Mode=" & backupMode & " | " & finalResult & " | Bookmarks: " & bmSummary & " ===")

        try
                do shell script "open " & quoted form of htmlPath
        end try
        try
                do shell script "open " & quoted form of finalBackupPath
        end try

        display dialog "✅ Backup complete!  (Mode: " & backupMode & ")" & return & return & "• Saved to:" & return & finalBackupPath & return & return & "• Bookmarks: " & bmSummary & return & return & "• Log & receipt:" & return & outDir buttons {"OK"} default button "OK" with title (appTitle & " — Complete") with icon note giving up after 120
end run

-- ============================ RESTORE (Bookmarks only) ======================
on runRestoreBookmarks()
        do shell script "mkdir -p " & quoted form of snapshotDir
        set recentBackupDir to destDir
        try
                do shell script "test -d " & quoted form of recentBackupDir
        on error
                my finishNoGo("No backups found — 'recentBackup' does not exist in your Box.")
                return
        end try
        set snapRaw to ""
        try
                set snapRaw to do shell script "ls -1t " & quoted form of recentBackupDir & " 2>/dev/null | grep '^Backup_' || true"
        end try
        if snapRaw is "" then
                my finishNoGo("No backup snapshots (Backup_*) found in your Box recentBackup folder.")
                return
        end if
        set snapList to paragraphs of snapRaw
        set snapChoice to (choose from list snapList with prompt "Select the snapshot to restore BOOKMARKS from (newest first):" default items {item 1 of snapList} with title (appTitle & " — Restore Bookmarks") without empty selection allowed)
        if snapChoice is false then my bailOut("Cancelled at snapshot selection.")
        set snapPath to recentBackupDir & "/" & (item 1 of snapChoice)
        my logLine("Restore-bookmarks snapshot: " & snapPath)

        if not fdaGranted then
                display dialog "🔒 Full Disk Access is required to WRITE bookmarks back into Safari/Chrome." & return & return & "Please enable Full Disk Access for THIS app, then quit and re-run." buttons {"OK"} default button "OK" with title appTitle with icon stop
                my addFinding("Restore bookmarks", "BLOCKER", "Full Disk Access not granted")
                my writeReceipt(0, "-", "-", "NO-GO", "Not started", "Skipped (needs FDA)")
                try
                        do shell script "open " & quoted form of htmlPath
                end try
                return
        end if

        set bmZip to snapPath & "/BrowserBookmarks.zip"
        set bmRawDir to snapPath & "/BrowserBookmarks"
        set stage to outDir & "/restored_bookmarks_" & ts
        do shell script "mkdir -p " & quoted form of stage
        set haveSource to false
        try
                do shell script "test -f " & quoted form of bmZip
                do shell script "/usr/bin/ditto -x -k " & quoted form of bmZip & " " & quoted form of stage
                set haveSource to true
                my logLine("Bookmarks source: ZIP")
        end try
        if not haveSource then
                try
                        do shell script "test -d " & quoted form of bmRawDir
                        do shell script "/usr/bin/ditto " & quoted form of bmRawDir & " " & quoted form of stage
                        set haveSource to true
                        my logLine("Bookmarks source: RAW folder")
                end try
        end if
        if not haveSource then
                my finishNoGo("That snapshot has no browser bookmarks (no BrowserBookmarks.zip or BrowserBookmarks/ folder).")
                return
        end if

        try
                display dialog "RESTORE PLAN — Bookmarks only" & return & return & "Snapshot: " & (item 1 of snapChoice) & return & return & "Safari and Google Chrome will be QUIT, your current bookmarks snapshotted, then replaced with the backed-up bookmarks." & return & return & "Proceed?" buttons {"Cancel", "Restore Now"} default button "Restore Now" cancel button "Cancel" with title (appTitle & " — Confirm Restore") with icon caution
        on error number -128
                my bailOut("Cancelled at restore confirmation.")
        end try

        set bmSummary to my applyBookmarks(stage)
        my writeReceipt(0, "-", "-", "GO", "Bookmarks restore", bmSummary)
        my logLine("=== Restore complete. Bookmarks: " & bmSummary & " ===")
        try
                do shell script "open " & quoted form of htmlPath
        end try
        display dialog "✅ Bookmark restore complete!" & return & return & "• " & bmSummary & return & return & "• Safety snapshot of previous bookmarks:" & return & snapshotDir & return & return & "Re-open Safari/Chrome to see them." buttons {"OK"} default button "OK" with title (appTitle & " — Complete") with icon note giving up after 120
end runRestoreBookmarks

on applyBookmarks(stage)
        set parts to {}
        set stagedSafari to stage & "/Safari_Bookmarks.plist"
        set hasSafari to false
        try
                do shell script "test -f " & quoted form of stagedSafari
                set hasSafari to true
        end try
        if hasSafari then
                my quitApp("Safari")
                set safariTarget to homeDir & "/Library/Safari/Bookmarks.plist"
                try
                        do shell script "test -f " & quoted form of safariTarget & " && /bin/cp " & quoted form of safariTarget & " " & quoted form of (snapshotDir & "/Safari_Bookmarks_BEFORE.plist") & " || true"
                end try
                try
                        do shell script "mkdir -p " & quoted form of (homeDir & "/Library/Safari")
                        do shell script "/bin/cp " & quoted form of stagedSafari & " " & quoted form of safariTarget
                        set end of parts to "Safari ✔"
                        my addFinding("Safari bookmarks", "OK", "Restored")
                on error errMsg
                        set end of parts to "Safari (write failed)"
                        my addFinding("Safari bookmarks", "FAIL", errMsg)
                end try
        end if
        set chromeBase to homeDir & "/Library/Application Support/Google/Chrome"
        set chromeFilesRaw to ""
        try
                set chromeFilesRaw to do shell script "ls -1 " & quoted form of stage & "/Chrome_*_Bookmarks.json 2>/dev/null || true"
        end try
        if chromeFilesRaw is not "" then
                my quitApp("Google Chrome")
                set chromeCount to 0
                repeat with cf in paragraphs of chromeFilesRaw
                        set cfp to (cf as text)
                        if cfp is not "" then
                                set base to do shell script "basename " & quoted form of cfp
                                set prof to do shell script "printf '%s' " & quoted form of base & " | sed -e 's/^Chrome_//' -e 's/_Bookmarks\\.json$//'"
                                set profDir to chromeBase & "/" & prof
                                try
                                        do shell script "test -d " & quoted form of profDir
                                        try
                                                do shell script "test -f " & quoted form of (profDir & "/Bookmarks") & " && /bin/cp " & quoted form of (profDir & "/Bookmarks") & " " & quoted form of (snapshotDir & "/Chrome_" & prof & "_Bookmarks_BEFORE.json") & " || true"
                                        end try
                                        do shell script "/bin/cp " & quoted form of cfp & " " & quoted form of (profDir & "/Bookmarks")
                                        try
                                                do shell script "/bin/rm -f " & quoted form of (profDir & "/Bookmarks.bak")
                                        end try
                                        set chromeCount to chromeCount + 1
                                end try
                        end if
                end repeat
                if chromeCount > 0 then
                        set end of parts to "Chrome ✔ (" & chromeCount & " profile" & my plural(chromeCount) & ")"
                        my addFinding("Chrome bookmarks", "OK", "Restored " & chromeCount & " profile(s); .bak cleared")
                else
                        set end of parts to "Chrome (no matching profiles)"
                        my addFinding("Chrome bookmarks", "WARN", "Backed-up profiles not found on this Mac")
                end if
        end if
        set summary to ""
        repeat with p in parts
                if summary is not "" then set summary to summary & "; "
                set summary to summary & (p as text)
        end repeat
        if summary is "" then set summary to "None restored"
        return summary
end applyBookmarks

-- ============================ HANDLERS ======================================

on hasFullDiskAccess()
        try
                do shell script "/bin/cat '/Library/Application Support/com.apple.TCC/TCC.db' > /dev/null 2>&1"
                return true
        on error
                return false
        end try
end hasFullDiskAccess

on effectiveFileCount(folderPath)
        set q to quoted form of folderPath
        set cmd to "F=" & q & "; BASE=$(find \"$F\" -type f ! -name '.localized' ! -name '.DS_Store' ! -name 'Icon*' 2>/dev/null | grep -v -F '.photoslibrary/' | grep -v -F '.musiclibrary/' | grep -v -F '.tvlibrary/' | grep -v -F '.theater/' | wc -l | tr -d ' '); PH=0; for lib in \"$F\"/*.photoslibrary; do [ -d \"$lib/originals\" ] && PH=$((PH+$(find \"$lib/originals\" -type f 2>/dev/null | wc -l | tr -d ' '))); done; echo $((BASE+PH))"
        set n to 0
        try
                set n to (do shell script cmd) as integer
        end try
        return n
end effectiveFileCount

on detectBoxRoot()
        set candidates to {homeDir & "/Library/CloudStorage/Box-Box", homeDir & "/Box", homeDir & "/Box Sync"}
        repeat with c in candidates
                set cp to (c as text)
                try
                        do shell script "test -d " & quoted form of cp
                        return cp
                end try
        end repeat
        try
                set found to do shell script "ls -d " & quoted form of (homeDir & "/Library/CloudStorage/") & "Box* 2>/dev/null | head -1"
                if found is not "" then return found
        end try
        return ""
end detectBoxRoot

on scanFolder(p)
        set leaf to do shell script "basename " & quoted form of p
        try
                set bigCount to do shell script "find " & quoted form of p & " -type f -size +" & LARGE_FILE_BYTES & "c 2>/dev/null | wc -l | tr -d ' '"
                if (bigCount as integer) > 0 then my addFinding("Large files in " & leaf, "WARN", bigCount & " file(s) over 2 GB")
        end try
        try
                set symCount to do shell script "find " & quoted form of p & " -type l 2>/dev/null | wc -l | tr -d ' '"
                if (symCount as integer) > 0 then my addFinding("Symlinks in " & leaf, "WARN", symCount & " symbolic link(s)")
        end try
        try
                set heavy to do shell script "find " & quoted form of p & " -type d \\( -name node_modules -o -name .git -o -name Caches \\) 2>/dev/null | head -3"
                if heavy is not "" then my addFinding("Cache/dev folders in " & leaf, "WARN", "node_modules/.git/Caches detected — consider excluding")
        end try
        try
                set longCount to do shell script "find " & quoted form of p & " 2>/dev/null | awk '{ if (length($0) > " & LONG_PATH_LIMIT & ") c++ } END { print c+0 }'"
                if (longCount as integer) > 0 then my addFinding("Long paths in " & leaf, "WARN", longCount & " very long path(s)")
        end try
        try
                set noRead to do shell script "find " & quoted form of p & " -type f ! -perm -u+r 2>/dev/null | wc -l | tr -d ' '"
                if (noRead as integer) > 0 then my addFinding("Unreadable files in " & leaf, "WARN", noRead & " file(s) may be skipped")
        end try
end scanFolder

on makeZip(srcPath, zipPath)
        try
                do shell script "/usr/bin/ditto -c -k --sequesterRsrc " & quoted form of srcPath & " " & quoted form of zipPath
        on error errMsg
                my logLine("ditto zip error " & srcPath & ": " & errMsg)
                return false
        end try
        try
                set sz to (do shell script "stat -f%z " & quoted form of zipPath) as integer
                if sz ≤ 0 then return false
                set entries to do shell script "/usr/bin/unzip -l " & quoted form of zipPath & " 2>/dev/null | tail -1 | awk '{print $2}'"
                my logLine("Verify ZIP OK: " & zipPath & " (" & my humanSize(sz) & ", " & entries & " entries)")
                return true
        on error
                return false
        end try
end makeZip

on rawCopy(srcPath, targetDir)
        try
                do shell script "mkdir -p " & quoted form of targetDir
                do shell script "/usr/bin/ditto " & quoted form of srcPath & " " & quoted form of targetDir
        on error errMsg
                my logLine("ditto raw copy error " & srcPath & ": " & errMsg)
                return false
        end try
        try
                set srcN to (do shell script "find " & quoted form of srcPath & " -type f 2>/dev/null | wc -l | tr -d ' '") as integer
                set dstN to (do shell script "find " & quoted form of targetDir & " -type f 2>/dev/null | wc -l | tr -d ' '") as integer
                if dstN ≥ srcN and dstN > 0 then
                        my logLine("Verify RAW OK: " & targetDir & " (" & dstN & " files)")
                        return true
                else if srcN is 0 then
                        my logLine("Verify RAW: source empty: " & srcPath)
                        return true
                else
                        my logLine("Verify RAW mismatch: src=" & srcN & " dst=" & dstN)
                        return false
                end if
        on error
                return false
        end try
end rawCopy

on captureBookmarks(finalBackupPath, isRaw)
        set stage to outDir & "/BrowserBookmarks_" & ts
        do shell script "mkdir -p " & quoted form of stage
        set statusParts to {}
        set capturedAny to false
        set safariBM to homeDir & "/Library/Safari/Bookmarks.plist"
        set safariExists to false
        try
                do shell script "test -e " & quoted form of safariBM
                set safariExists to true
        end try
        if safariExists then
                set safariOK to false
                try
                        do shell script "/bin/cp " & quoted form of safariBM & " " & quoted form of (stage & "/Safari_Bookmarks.plist")
                        try
                                do shell script "plutil -convert xml1 -o " & quoted form of (stage & "/Safari_Bookmarks.xml") & " " & quoted form of safariBM & " 2>/dev/null"
                        end try
                        set safariOK to true
                end try
                if safariOK then
                        set end of statusParts to "Safari ✔"
                        set capturedAny to true
                else
                        set end of statusParts to "Safari (needs Full Disk Access)"
                end if
        else
                if fdaGranted then
                        set end of statusParts to "Safari (none)"
                else
                        set end of statusParts to "Safari (needs Full Disk Access)"
                end if
        end if
        set chromeBase to homeDir & "/Library/Application Support/Google/Chrome"
        set chromeInstalled to false
        try
                do shell script "test -d " & quoted form of chromeBase
                set chromeInstalled to true
        end try
        if chromeInstalled then
                set chromeGot to 0
                set chromeBlocked to false
                set profLines to ""
                try
                        set profLines to do shell script "for d in " & quoted form of chromeBase & "/Default " & quoted form of chromeBase & "/Profile*; do [ -f \"$d/Bookmarks\" ] && echo \"$d\"; done 2>/dev/null || true"
                end try
                if profLines is "" then
                        if not fdaGranted then set chromeBlocked to true
                else
                        repeat with pr in paragraphs of profLines
                                set prp to (pr as text)
                                if prp is not "" then
                                        try
                                                set pname to do shell script "basename " & quoted form of prp
                                                do shell script "/bin/cp " & quoted form of (prp & "/Bookmarks") & " " & quoted form of (stage & "/Chrome_" & pname & "_Bookmarks.json")
                                                set chromeGot to chromeGot + 1
                                        on error
                                                set chromeBlocked to true
                                        end try
                                end if
                        end repeat
                end if
                if chromeGot > 0 then
                        set end of statusParts to "Chrome ✔ (" & chromeGot & " profile" & my plural(chromeGot) & ")"
                        set capturedAny to true
                else if chromeBlocked then
                        set end of statusParts to "Chrome (needs Full Disk Access)"
                else
                        set end of statusParts to "Chrome (no bookmarks)"
                end if
        else
                set end of statusParts to "Chrome (not installed)"
        end if
        if capturedAny then
                if isRaw then
                        do shell script "mkdir -p " & quoted form of (finalBackupPath & "/BrowserBookmarks")
                        do shell script "/usr/bin/ditto " & quoted form of stage & " " & quoted form of (finalBackupPath & "/BrowserBookmarks")
                        my logLine("Bookmarks stored RAW in BrowserBookmarks/")
                else
                        my makeZip(stage, finalBackupPath & "/BrowserBookmarks.zip")
                        my logLine("Bookmarks stored as BrowserBookmarks.zip")
                end if
        end if
        set summary to ""
        repeat with s in statusParts
                if summary is not "" then set summary to summary & "; "
                set summary to summary & (s as text)
        end repeat
        if summary is "" then set summary to "None found"
        return summary
end captureBookmarks

on quitApp(appName)
        try
                tell application "System Events"
                        set isRunning to (exists (processes whose name is appName))
                end tell
                if isRunning then
                        try
                                tell application appName to quit
                        end try
                        delay 2
                        try
                                do shell script "pkill -x " & quoted form of appName & " 2>/dev/null || true"
                        end try
                        my logLine("Quit app: " & appName)
                end if
        end try
end quitApp

on addFinding(nm, sev, det)
        set end of findName to nm
        set end of findSev to sev
        set end of findDetail to det
        my logLine("[" & sev & "] " & nm & " — " & det)
end addFinding

on countSeverity(sev)
        set n to 0
        repeat with s in findSev
                if (s as text) is sev then set n to n + 1
        end repeat
        return n
end countSeverity

on plural(n)
        if n is 1 then
                return ""
        else
                return "s"
        end if
end plural

on humanSize(bytes)
        try
                return do shell script "echo " & bytes & " | awk '{b=$1; s=\"B KB MB GB TB\"; split(s,u,\" \"); i=1; while (b>=1024 && i<5){b/=1024; i++} printf \"%.1f %s\", b, u[i]}'"
        on error
                return (bytes as text) & " B"
        end try
end humanSize

on logLine(msg)
        set stamp to do shell script "date '+%H:%M:%S'"
        try
                do shell script "printf '%s  %s\\n' " & quoted form of stamp & " " & quoted form of msg & " >> " & quoted form of logPath
        end try
end logLine

on bailOut(msg)
        my logLine("ABORT: " & msg)
        display dialog msg buttons {"OK"} default button "OK" with title appTitle with icon stop
        error number -128
end bailOut

on finishNoGo(msg)
        my logLine("NO-GO: " & msg)
        my addFinding("Restore", "BLOCKER", msg)
        my writeReceipt(0, "-", "-", "NO-GO", "Not started", "Not restored")
        try
                do shell script "open " & quoted form of htmlPath
        end try
        display dialog "🛑  " & msg buttons {"OK"} default button "OK" with title (appTitle & " — Cannot Proceed") with icon stop
end finishNoGo

on writeModeInfo()
        set infoPath to outDir & "/Backup_Modes_" & ts & ".html"
        set html to "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>Backup Modes — Choose</title><style>:root{--gold:#d4af37;}*{box-sizing:border-box;font-family:-apple-system,Segoe UI,Roboto,sans-serif;}body{margin:0;background:#0a0c12;color:#e7ebf3;}.bg{position:fixed;inset:0;background:radial-gradient(1200px 600px at 18% -10%,rgba(212,175,55,.12),transparent),radial-gradient(900px 500px at 110% 15%,rgba(80,140,255,.08),transparent);}.wrap{position:relative;max-width:1200px;margin:0 auto;padding:40px 24px 70px;}.badge{display:inline-block;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:var(--gold);border:1px solid rgba(212,175,55,.4);padding:6px 14px;border-radius:999px;background:rgba(212,175,55,.08);}.hero{margin-top:16px;font-size:34px;font-weight:900;}.hero .c{color:var(--gold);}.sub{margin-top:10px;color:#aab4c8;font-size:15px;max-width:820px;line-height:1.6;}.shimmer{height:4px;border-radius:4px;margin-top:22px;background:linear-gradient(90deg,transparent,var(--gold),#f0d774,var(--gold),transparent);background-size:200% 100%;animation:sh 3s linear infinite;}@keyframes sh{to{background-position:-200% 0;}}.cols{display:flex;gap:16px;flex-wrap:wrap;margin-top:26px;}.col{flex:1;min-width:220px;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.09);backdrop-filter:blur(16px);border-radius:18px;padding:20px;box-shadow:0 10px 34px rgba(0,0,0,.4);transition:.2s;}.col:hover{transform:translateY(-4px);box-shadow:0 0 30px rgba(212,175,55,.25);}.col h2{font-size:16px;margin-bottom:4px;}.tag{display:inline-block;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;padding:4px 9px;border-radius:999px;margin-bottom:10px;}.tag.z{background:rgba(57,217,138,.15);color:#39d98a;border:1px solid rgba(57,217,138,.4);}.tag.c{background:rgba(240,180,41,.15);color:#f0b429;border:1px solid rgba(240,180,41,.4);}.tag.r{background:rgba(80,140,255,.15);color:#6ea8ff;border:1px solid rgba(80,140,255,.4);}.tag.re{background:rgba(212,175,55,.15);color:var(--gold);border:1px solid rgba(212,175,55,.4);}.tag.d{background:rgba(180,120,255,.15);color:#c39bff;border:1px solid rgba(180,120,255,.4);}.col p{color:#c3cad8;font-size:13px;line-height:1.55;}.col ul{margin:10px 0 4px 16px;color:#c3cad8;font-size:12.5px;line-height:1.7;}.col li b{color:#fff;}.uc{margin-top:10px;padding:9px 11px;border-radius:10px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.08);font-size:11.5px;color:#c9d2e2;}.uc b{color:var(--gold);}.card{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:22px;margin-top:22px;}.card h3{color:var(--gold);margin-bottom:8px;}table{width:100%;border-collapse:collapse;font-size:14px;}th,td{text-align:left;padding:10px 12px;border-bottom:1px solid rgba(255,255,255,.07);}th{color:var(--gold);font-size:12px;text-transform:uppercase;letter-spacing:1px;}.pill{padding:3px 10px;border-radius:999px;font-size:12px;font-weight:700;}.pill.ok{background:rgba(57,217,138,.15);color:#39d98a;border:1px solid rgba(57,217,138,.4);}.pill.warn{background:rgba(240,180,41,.15);color:#f0b429;border:1px solid rgba(240,180,41,.4);}.foot{color:#6b7686;font-size:11px;margin-top:26px;text-align:center;}</style></head><body><div class='bg'></div><div class='wrap'><span class='badge'>🛡️ Executive Support · Backup to Box</span><div class='hero'>Choose Your <span class='c'>Mode</span></div><div class='sub'>Six options: compressed Legal-Hold, custom compressed, RAW Box-first migration, bookmark-only restore, custom + choose-destination, and standard set + choose-destination. Empty/Apple-default folders are auto-skipped; a full audit receipt is saved.</div><div class='shimmer'></div><div class='cols'><div class='col'><div class='tag z'>① ZIP → Box</div><h2>Standard Corporate</h2><p>Automatic, compressed. Apple-default-only roots auto-skipped.</p><ul><li>✅ <b>Desktop</b></li><li>✅ <b>Documents</b></li><li>✅ <b>Movies / Music / Pictures</b></li><li>✅ <b>Safari + Chrome</b> bookmarks</li></ul><div class='uc'><b>Use case:</b> Legal Hold — capture a departing / terminated employee's data before the machine is wiped and reissued.</div></div><div class='col'><div class='tag c'>② ZIP → Box</div><h2>Custom</h2><p>You pick the folders (⌘-click). Saves to Box.</p><ul><li>🎯 <b>Any folders</b> you choose</li><li>✅ <b>Bookmarks</b> included</li></ul><div class='uc'><b>Use case:</b> Targeted / ad-hoc backups to Box.</div></div><div class='col'><div class='tag r'>③ RAW → Box</div><h2>Standard — Uncompressed</h2><p><b>Box-first.</b> Same set as ①, copied RAW.</p><ul><li>✅ <b>Desktop + Documents</b></li><li>✅ <b>Movies / Music / Pictures</b></li><li>✅ <b>Bookmarks</b></li><li>⚠️ Larger &amp; slower sync</li></ul><div class='uc'><b>Use case:</b> System-update / migration moving users to Box as their default location.</div></div><div class='col'><div class='tag re'>④ RESTORE</div><h2>Bookmarks Only</h2><p>For a <b>new device</b>. Only bookmarks come back locally.</p><ul><li>✅ Restores <b>Safari + Chrome</b></li><li>🛟 Snapshots current first</li><li>🔒 Needs Full Disk Access</li></ul><div class='uc'><b>Use case:</b> Device refresh / onboarding after a Box-first migration.</div></div><div class='col'><div class='tag d'>⑤ ZIP → ANY</div><h2>Custom + Choose Destination</h2><p>You pick the folders <b>AND</b> where to save them.</p><ul><li>🎯 <b>Any folders</b> you choose</li><li>📍 <b>Any destination:</b> Box, Network share, OneDrive, external drive</li><li>✅ <b>Bookmarks</b> included</li></ul><div class='uc'><b>Use case:</b> When the backup must land somewhere other than the default Box personal folder.</div></div><div class='col'><div class='tag d'>⑥ ZIP → ANY</div><h2>Standard + Choose Destination</h2><p>Default folder set, but <b>you</b> pick where to save.</p><ul><li>✅ <b>Desktop + Documents</b></li><li>✅ <b>Movies / Music / Pictures</b></li><li>✅ <b>Bookmarks</b> included</li><li>📍 <b>Any destination:</b> Box, Network, OneDrive, external</li></ul><div class='uc'><b>Use case:</b> Standard-set backup that must land somewhere other than the default Box folder.</div></div></div><div class='card'><h3>All modes guarantee</h3><table><tr><th>Guarantee</th><th>Status</th></tr><tr><td>Source files are read-only (never moved or deleted)</td><td><span class='pill ok'>Always</span></td></tr><tr><td>Standard set = Desktop + Documents + Movies + Music + Pictures</td><td><span class='pill ok'>Modes ① ③ ⑥</span></td></tr><tr><td>Apple defaults (.localized / empty libraries) ignored; empty roots skipped</td><td><span class='pill ok'>Modes ① ③ ⑥</span></td></tr><tr><td>User chooses destination (Box / Network / OneDrive / external)</td><td><span class='pill ok'>Modes ⑤ ⑥</span></td></tr><tr><td>Destination verified writable before copying</td><td><span class='pill ok'>Always</span></td></tr><tr><td>Each archive/copy verified after write</td><td><span class='pill ok'>Always</span></td></tr><tr><td>Browser bookmarks require Full Disk Access (this app)</td><td><span class='pill warn'>If enabled</span></td></tr><tr><td>Logs + receipt saved under /Users/Shared/BACKUP-TO-BOX</td><td><span class='pill ok'>Always</span></td></tr></table></div><div class='card'><h3>Destinations</h3><p style='color:#c3cad8;font-size:14px;'>Box modes (① ② ③) land in <b>Box ▸ " & personalFolderName & " ▸ " & backupSubfolder & " ▸ Backup_" & ts & "</b>. Modes ⑤ ⑥ land in <b>&lt;your chosen folder&gt; ▸ Backup_" & ts & "</b>. Logs &amp; receipts are always saved under <b>/Users/Shared/BACKUP-TO-BOX/</b>.</p></div><div class='foot'>Intuitive confidential — For internal use only. " & appTitle & " v" & appVersion & " · Host " & hostName & " · " & nowH & "</div></div></body></html>"
        try
                set fh to open for access (POSIX file infoPath) with write permission
                set eof fh to 0
                write html to fh as «class utf8»
                close access fh
        on error
                try
                        close access (POSIX file infoPath)
                end try
        end try
end writeModeInfo

on writeReceipt(totalFiles, totalSizeH, freeH, decision, resultText, bmSummary)
        set decClass to "ok"
        if decision is "NO-GO" then set decClass to "bad"
        if decision is "REVIEW" then set decClass to "warn"
        set modeLabel to backupMode
        try
                if backupMode is missing value then set modeLabel to "n/a"
        end try
        set destShown to destLabel
        if destShown is "" then set destShown to "n/a"
        set rows to ""
        repeat with i from 1 to (count of findName)
                set nm to item i of findName
                set sv to item i of findSev
                set dt to item i of findDetail
                set cls to "ok"
                if sv is "WARN" then set cls to "warn"
                if sv is "BLOCKER" then set cls to "bad"
                set rows to rows & "<tr><td>" & nm & "</td><td><span class='pill " & cls & "'>" & sv & "</span></td><td class='mono'>" & dt & "</td></tr>"
        end repeat
        if rows is "" then set rows to "<tr><td colspan='3' class='mono'>No issues detected.</td></tr>"
        set fdaLabel to "Granted"
        if not fdaGranted then set fdaLabel to "NOT granted (bookmarks skipped)"

        set html to "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>Backup Receipt - " & serialNum & "</title><style>:root{--gold:#d4af37;}*{box-sizing:border-box;font-family:-apple-system,Segoe UI,Roboto,sans-serif;}body{margin:0;background:#0a0c12;color:#e7ebf3;}.bg{position:fixed;inset:0;background:radial-gradient(1200px 600px at 20% -10%,rgba(212,175,55,.10),transparent),radial-gradient(900px 500px at 110% 20%,rgba(80,140,255,.08),transparent);}.wrap{position:relative;max-width:1000px;margin:0 auto;padding:36px 24px;}.hero{font-size:26px;font-weight:800;}.hero .c{color:var(--gold);}.sub{color:#9aa4b8;margin-top:6px;font-size:13px;}.card{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);backdrop-filter:blur(14px);border-radius:16px;padding:22px;margin-top:22px;box-shadow:0 8px 30px rgba(0,0,0,.35);}.kpis{display:flex;gap:16px;flex-wrap:wrap;margin-top:20px;}.kpi{flex:1;min-width:150px;background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.08);border-radius:14px;padding:16px;transition:.2s;}.kpi:hover{transform:translateY(-3px);box-shadow:0 0 22px rgba(212,175,55,.25);}.kpi .l{font-size:12px;color:#9aa4b8;text-transform:uppercase;letter-spacing:1px;}.kpi .v{font-size:16px;font-weight:800;margin-top:6px;word-break:break-word;}.decision{font-size:30px;font-weight:900;letter-spacing:2px;}.decision.ok{color:#39d98a;}.decision.warn{color:#f0b429;}.decision.bad{color:#ff5c6c;}table{width:100%;border-collapse:collapse;margin-top:10px;font-size:14px;}th,td{text-align:left;padding:11px 12px;border-bottom:1px solid rgba(255,255,255,.07);vertical-align:top;}th{color:var(--gold);font-size:12px;text-transform:uppercase;letter-spacing:1px;}.mono{font-family:ui-monospace,Menlo,monospace;font-size:12px;color:#aab4c8;}.pill{padding:3px 10px;border-radius:999px;font-size:12px;font-weight:700;}.pill.ok{background:rgba(57,217,138,.15);color:#39d98a;border:1px solid rgba(57,217,138,.4);}.pill.warn{background:rgba(240,180,41,.15);color:#f0b429;border:1px solid rgba(240,180,41,.4);}.pill.bad{background:rgba(255,92,108,.15);color:#ff5c6c;border:1px solid rgba(255,92,108,.4);}.foot{color:#6b7686;font-size:11px;margin-top:24px;text-align:center;}</style></head><body><div class='bg'></div><div class='wrap'><div class='hero'>BACKUP-TO-<span class='c'>BOX</span> — Receipt</div><div class='sub'>Mode: " & modeLabel & " &bull; User " & consoleUser & " &bull; Host " & hostName & " &bull; Serial " & serialNum & " &bull; macOS " & osVer & " (" & osBuild & ") &bull; " & nowH & "</div><div class='kpis'><div class='kpi'><div class='l'>Mode</div><div class='v'>" & modeLabel & "</div></div><div class='kpi'><div class='l'>Destination</div><div class='v'>" & destShown & "</div></div><div class='kpi'><div class='l'>Files</div><div class='v'>" & totalFiles & "</div></div><div class='kpi'><div class='l'>Total Size</div><div class='v'>" & totalSizeH & "</div></div><div class='kpi'><div class='l'>Free Space</div><div class='v'>" & freeH & "</div></div><div class='kpi'><div class='l'>Full Disk Access</div><div class='v'>" & fdaLabel & "</div></div><div class='kpi'><div class='l'>Bookmarks</div><div class='v'>" & bmSummary & "</div></div><div class='kpi'><div class='l'>Result</div><div class='v'>" & resultText & "</div></div></div><div class='card'><div class='l' style='color:#9aa4b8;font-size:12px;letter-spacing:1px;'>DECISION</div><div class='decision " & decClass & "'>" & decision & "</div></div><div class='card'><h3 style='margin:0 0 6px;color:var(--gold);'>Findings / Results</h3><table><tr><th>Item</th><th>Status</th><th>Detail</th></tr>" & rows & "</table></div><div class='card'><h3 style='margin:0 0 6px;color:var(--gold);'>Notes &amp; Guarantees</h3><p style='color:#c3cad8;font-size:14px;'>Standard set (modes ① ③ ⑥) = Desktop + Documents + Movies + Music + Pictures + bookmarks. Apple default items (.localized, .DS_Store, Icon, empty libraries) are ignored; real imported Photos (originals) ARE included. Modes ⑤ ⑥ let the user choose any writable destination (Box / Network / OneDrive / external) and verify it before copying. Logs &amp; receipts saved under <b>/Users/Shared/BACKUP-TO-BOX/</b>. Sources are read-only (ditto). ZIP verifies size + entry count; RAW verifies file-count parity. Restore quits browsers and snapshots current bookmarks first. Browser bookmarks need <b>Full Disk Access for THIS app</b>. Full detail in <b>backup.log</b>.</p></div><div class='foot'>Intuitive confidential — For internal use only. " & appTitle & " v" & appVersion & " &bull; Log: backup.log</div></div></body></html>"
        try
                set fh to open for access (POSIX file htmlPath) with write permission
                set eof fh to 0
                write html to fh as «class utf8»
                close access fh
        on error
                try
                        close access (POSIX file htmlPath)
                end try
        end try
end writeReceipt