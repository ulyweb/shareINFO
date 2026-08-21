-- ============================================================================
--  BACKUP-TO-BOX  v2.3.11   "Mac Backup & Recovery Toolkit"
--  IT Support — MAC-MAINT / MAC-HANDOFF family
--
--  v2.3.11 CHANGE:
--    • Fixed a permissions-dialog syntax error (stray double-ampersand from blank-line joins).
--    • Added a branded gold-shield icon to the info dialogs (embedded PNG → icns at runtime).
--    • Output folder renamed to /Users/Shared/mac-backup-recovery-toolkit/ (was BACKUP-TO-BOX).
--
--  v2.3.10 CHANGE:
--    • Renamed to “Mac Backup & Recovery Toolkit” (destination-neutral; backup + restore).
--    • Native mode-picker labels shortened for readability (full folder detail lives on the
--      info page + receipt); permissions dialog wording tidied.
--
--  v2.3.9 CHANGE:
--    • Standard set now also includes the Downloads folder (modes ① ③ ⑥):
--      Desktop + Documents + Downloads + Movies + Music + Pictures + Bookmarks.
--    • Backup receipt page rebuilt with the Liquid Glass UI (telemetry topbar, glass
--      KPI tiles + decision banner, adjustable Blur / Fill / Depth controls).
--
--  v2.3.8 CHANGE:
--    • CHOOSE-YOUR-MODE info page rebuilt with the Liquid Glass dashboard UI:
--      welcome splash, telemetry topbar, cards that open a slide-in detail drawer,
--      and an adjustable-glass control panel (Blur / Fill / Depth).
--    • Wording generalized for portable IT Support use (no company-specific labels).
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
--    ① STANDARD CORPORATE BACKUP (ZIP) → Box — Desktop + Documents + Downloads + Movies +
--       Music + Pictures + Safari/Chrome bookmarks. USE CASE: Legal Hold.
--    ② CUSTOM BACKUP (ZIP) → Box — user multi-selects folders (+ bookmarks).
--    ③ STANDARD CORPORATE — RAW (UNCOMPRESSED) → Box. USE CASE: Box-first migration.
--    ④ RESTORE — BOOKMARKS ONLY — restores Safari/Chrome bookmarks for new device.
--    ⑤ CUSTOM BACKUP + CHOOSE DESTINATION (ZIP) — user picks folders AND the
--    ⑥ CUSTOM BACKUP + DEFAULT FOLDERS (ZIP) — standard set (Desktop + Documents + Downloads +
--       Movies + Music + Pictures + Bookmarks) → user picks destination (Box / Network / OneDrive / external).
--       destination (Box / network / OneDrive / external / any writable path).
--
--  Build:  Script Editor > paste > Export > Application > Sign to Run Locally.
-- ============================================================================

property appTitle : "Mac Backup & Recovery Toolkit"
property appVersion : "2.3.11"
property personalFolderName : "01. My Personal Folder"
property backupSubfolder : "recentBackup"
property LARGE_FILE_BYTES : 2.147483648E+9
property LONG_PATH_LIMIT : 240
property FREESPACE_HEADROOM : 1.1
property brandIconB64 : "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"

global consoleUser, homeDir, serialNum, hostName, osVer, osBuild
global boxRoot, destDir, spaceRoot, destLabel, backupFolderName, outDir, logPath, htmlPath, runLog, ts, nowH
global findName, findSev, findDetail
global fdaGranted, backupMode, snapshotDir
global brandIcon

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

        set outDir to "/Users/Shared/mac-backup-recovery-toolkit/" & ts & "_" & serialNum
        try
                do shell script "mkdir -p " & quoted form of outDir
        end try
        try
                do shell script "test -w " & quoted form of outDir
        on error
                set outDir to homeDir & "/mac-backup-recovery-toolkit/" & ts & "_" & serialNum
                do shell script "mkdir -p " & quoted form of outDir
        end try
        try
                do shell script "test -w " & quoted form of outDir
        on error
                set outDir to (do shell script "mktemp -d /tmp/mac-backup-recovery-toolkit.XXXXXX")
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

        set brandIcon to my prepBrandIcon()
        display dialog "🔐  PERMISSIONS CHECK" & return & return & "Grant these under  System Settings ▸ Privacy & Security:" & return & return & "•  Full Disk Access   —   REQUIRED (folders + Safari/Chrome bookmarks)" & return & "•  Files & Folders" & return & "•  Accessibility" & return & return & "⚠️  Add THIS app — “" & appTitle & "” — to Full Disk Access. Access you granted to Script Editor does NOT carry over to the exported app." & return & return & "Click OK when you're ready to continue." buttons {"OK"} default button "OK" with title appTitle with icon brandIcon

        set fdaGranted to my hasFullDiskAccess()
        my logLine("Full Disk Access granted: " & fdaGranted)
        if not fdaGranted then
                try
                        set r to display dialog "🔒  Full Disk Access is not enabled for THIS app." & return & return & "Browser bookmarks (backup AND restore) require Full Disk Access for the app you are running (" & appTitle & "), not just Script Editor." & return & return & "Click 'Open Settings', add + enable this app, then QUIT and RE-RUN. You may continue now (folders still work; bookmarks skipped)." buttons {"Open Settings", "Continue Anyway"} default button "Open Settings" with title (appTitle & " — Full Disk Access") with icon caution
                        if button returned of r is "Open Settings" then
                                try
                                        do shell script "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles'"
                                end try
                                display dialog "After enabling Full Disk Access for THIS app, QUIT and RE-RUN it so the change takes effect." buttons {"Quit", "Continue Anyway"} default button "Quit" with title appTitle with icon brandIcon
                                if button returned of result is "Quit" then return
                        end if
                on error number -128
                end try
        end if

        my writeModeInfo()
        try
                do shell script "open " & quoted form of (outDir & "/Backup_Modes_" & ts & ".html")
        end try

        set mode1 to "①  Standard Corporate — ZIP → Box   ·   Legal Hold (standard set + bookmarks)"
        set mode2 to "②  Custom — ZIP → Box   ·   you choose the folders"
        set mode3 to "③  Standard Corporate — RAW → Box   ·   system update / migration"
        set mode4 to "④  Restore — Bookmarks Only   ·   Safari & Chrome"
        set mode5 to "⑤  Custom + Choose Destination — ZIP   ·   Box / Network / OneDrive / external"
        set mode6 to "⑥  Standard Folders + Choose Destination — ZIP   ·   you pick where to save"
        set modeChoice to (choose from list {mode1, mode2, mode3, mode4, mode5, mode6} with prompt "Select a backup mode below." & return & "Full details for each mode are on the info page that just opened." default items {mode1} with title (appTitle & " — Choose Mode") without empty selection allowed)
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
                display dialog "Tip: hold ⌘ (Command) to select multiple folders." buttons {"OK"} default button "OK" with title appTitle with icon brandIcon
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
                        display dialog "Now choose the DESTINATION where the backup will be saved." & return & return & "This can be your Box folder, a mounted NETWORK share, OneDrive, an external drive, or any writable folder." buttons {"Choose Destination"} default button "Choose Destination" with title appTitle with icon brandIcon
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
                set stdCandidates to {homeDir & "/Desktop", homeDir & "/Documents", homeDir & "/Downloads", homeDir & "/Movies", homeDir & "/Music", homeDir & "/Pictures"}
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
                if (count of sourceFolders) is 0 then my bailOut("None of the standard folders (Desktop/Documents/Downloads/Movies/Music/Pictures) contained any meaningful user files to back up.")
                if backupMode is "Standard-Dest" then
                        display dialog "Now choose the DESTINATION where the backup will be saved." & return & return & "This can be your Box folder, a mounted NETWORK share, OneDrive, an external drive, or any writable folder." buttons {"Choose Destination"} default button "Choose Destination" with title appTitle with icon brandIcon
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
                set r to display dialog confMsg buttons {"Cancel", "Yes"} default button "Yes" cancel button "Cancel" with title (appTitle & " — Confirm") with icon brandIcon
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

        display dialog "✅ Backup complete!  (Mode: " & backupMode & ")" & return & return & "• Saved to:" & return & finalBackupPath & return & return & "• Bookmarks: " & bmSummary & return & return & "• Log & receipt:" & return & outDir buttons {"OK"} default button "OK" with title (appTitle & " — Complete") with icon brandIcon giving up after 120
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
        display dialog "✅ Bookmark restore complete!" & return & return & "• " & bmSummary & return & return & "• Safety snapshot of previous bookmarks:" & return & snapshotDir & return & return & "Re-open Safari/Chrome to see them." buttons {"OK"} default button "OK" with title (appTitle & " — Complete") with icon brandIcon giving up after 120
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

on prepBrandIcon()
        set pngPath to outDir & "/.brand_icon.png"
        set icnsPath to outDir & "/.brand_icon.icns"
        try
                do shell script "printf %s " & quoted form of brandIconB64 & " | /usr/bin/base64 -D > " & quoted form of pngPath
        on error
                return note
        end try
        try
                do shell script "/usr/bin/sips -s format icns " & quoted form of pngPath & " --out " & quoted form of icnsPath
                return (POSIX file icnsPath)
        end try
        return note
end prepBrandIcon

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
        set html to "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>Backup Modes — Choose</title><style>*{box-sizing:border-box}:root{--gold:#e8b54b;--cyan:#00e5ff;--green:#00e08a;--bg:#05080d;--txt:#d7e6f2;--dim:#9fb4c6;--mute:#6b7686;--g-blur:26px;--g-fill-a:.55;--g-shadow-a:.8;--glass-hi:rgba(255,255,255,.14);--glass-edge:rgba(255,255,255,.2)}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:var(--txt);background-image:linear-gradient(rgba(0,229,255,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(0,229,255,.04) 1px,transparent 1px);background-size:44px 44px}body:before{content:'';position:fixed;inset:0;z-index:0;pointer-events:none;background:radial-gradient(1100px 600px at 12% -8%,rgba(0,229,255,.10),transparent 62%),radial-gradient(900px 520px at 92% 4%,rgba(232,181,75,.10),transparent 60%)}.glass{background:linear-gradient(180deg,var(--glass-hi),rgba(255,255,255,0) 46%),rgba(14,21,33,var(--g-fill-a));-webkit-backdrop-filter:blur(var(--g-blur)) saturate(180%);backdrop-filter:blur(var(--g-blur)) saturate(180%);border:1px solid var(--glass-edge);box-shadow:0 1px 0 rgba(255,255,255,.22) inset,0 -14px 30px -26px rgba(0,0,0,var(--g-shadow-a)) inset,0 28px 60px -22px rgba(0,0,0,var(--g-shadow-a))}.welcome{position:fixed;inset:0;z-index:400;display:flex;align-items:center;justify-content:center;text-align:center;background:radial-gradient(1200px 700px at 50% 8%,rgba(232,181,75,.08),transparent 60%),linear-gradient(160deg,#04060a,#070c14 45%,#0a1424);transition:opacity .5s}.welcome.hide{opacity:0;pointer-events:none}.wtitle{font-family:Georgia,Times New Roman,serif;font-size:clamp(30px,5vw,56px);margin:8px 0 0;line-height:1.05}.wt2{color:var(--gold);font-style:italic}.weyebrow{font-family:ui-monospace,Menlo,monospace;font-size:11px;letter-spacing:4px;color:var(--gold);text-transform:uppercase;margin-top:12px}.wtag{color:var(--dim);max-width:640px;margin:16px auto 0;line-height:1.6;font-size:14px}.wcta{margin-top:24px;font-weight:800;font-size:15px;color:#20160a;background:linear-gradient(180deg,#f0c869,#d9a838);border:none;border-radius:12px;padding:13px 30px;cursor:pointer;box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 10px 30px rgba(232,181,75,.4)}.topbar{position:sticky;top:0;z-index:60;display:flex;align-items:center;gap:10px;padding:9px 16px;border-bottom:1px solid var(--glass-edge);-webkit-backdrop-filter:blur(24px) saturate(180%);backdrop-filter:blur(24px) saturate(180%);background:linear-gradient(180deg,rgba(5,8,13,.9),rgba(5,8,13,.7))}.brand{font-family:ui-monospace,Menlo,monospace;font-weight:800;letter-spacing:.12em;font-size:13px;display:flex;gap:8px;align-items:center}.brand b{color:var(--gold)}.live{display:inline-flex;align-items:center;gap:6px;font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.16em;color:var(--green);border:1px solid rgba(0,224,138,.8);background:rgba(0,224,138,.2);padding:3px 9px;border-radius:20px;box-shadow:0 0 16px -2px rgba(0,224,138,.6)}.live i{width:8px;height:8px;border-radius:50%;background:#2effb0;box-shadow:0 0 12px 2px rgba(0,224,138,.9);animation:pulse 1.5s infinite}@keyframes pulse{0%,100%{transform:scale(1);opacity:1}50%{transform:scale(1.4);opacity:.5}}.chip{font-family:ui-monospace,monospace;font-size:10px;color:var(--gold);border:1px solid rgba(232,181,75,.4);background:rgba(232,181,75,.1);padding:3px 9px;border-radius:20px}.sp{flex:1}.gear{font-family:ui-monospace,monospace;font-size:12px;color:var(--dim);background:rgba(255,255,255,.05);border:1px solid var(--glass-edge);border-radius:9px;padding:6px 11px;cursor:pointer}.gear:hover{color:var(--cyan);border-color:var(--cyan)}.wrap{position:relative;z-index:1;max-width:1200px;margin:0 auto;padding:26px 20px 70px}.eyebrow{font-family:ui-monospace,monospace;font-size:11px;letter-spacing:3px;color:var(--gold);text-transform:uppercase}.hero{font-size:32px;font-weight:900;margin-top:8px}.hero span{color:var(--gold)}.sub{margin-top:8px;color:var(--dim);max-width:820px;line-height:1.6;font-size:14px}.shimmer{height:3px;border-radius:4px;margin-top:18px;background:linear-gradient(90deg,transparent,var(--gold),var(--cyan),transparent);background-size:200% 100%;animation:sh 4s linear infinite}@keyframes sh{to{background-position:-200% 0}}.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:14px;margin-top:24px}.card{border-radius:16px;padding:18px;cursor:pointer;transition:transform .22s cubic-bezier(.2,.7,.2,1),box-shadow .22s,border-color .22s}.card:hover{transform:translateY(-5px) scale(1.01);border-color:rgba(0,229,255,.5)}.tag{display:inline-block;font-family:ui-monospace,monospace;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;padding:4px 9px;border-radius:999px;margin-bottom:10px}.tag.z{background:rgba(0,224,138,.15);color:var(--green);border:1px solid rgba(0,224,138,.4)}.tag.c{background:rgba(240,180,41,.15);color:#f0b429;border:1px solid rgba(240,180,41,.4)}.tag.r{background:rgba(80,140,255,.15);color:#6ea8ff;border:1px solid rgba(80,140,255,.4)}.tag.re{background:rgba(232,181,75,.15);color:var(--gold);border:1px solid rgba(232,181,75,.4)}.tag.d{background:rgba(180,120,255,.15);color:#c39bff;border:1px solid rgba(180,120,255,.4)}.card h2{font-size:16px;margin:2px 0 4px}.card p{color:var(--dim);font-size:12.5px;line-height:1.5;margin:0}.card .more{display:block;margin-top:10px;font-family:ui-monospace,monospace;font-size:9px;letter-spacing:.1em;color:var(--gold)}.drawer{position:fixed;top:0;right:0;height:100vh;width:min(560px,calc(100vw - 20px));z-index:260;transform:translateX(106%);transition:.32s;display:flex;flex-direction:column;border-top-left-radius:22px;border-bottom-left-radius:22px}.drawer.open{transform:translateX(0)}.dhead{display:flex;align-items:center;gap:10px;padding:16px 18px;border-bottom:1px solid var(--glass-edge)}.dhead h2{font-family:ui-monospace,monospace;font-size:14px;letter-spacing:.06em;margin:0;flex:1;color:var(--gold)}.x{background:none;border:1px solid var(--glass-edge);border-radius:8px;color:var(--dim);padding:5px 10px;cursor:pointer}.dbody{padding:16px 18px;overflow:auto}.sec{border:1px solid var(--glass-edge);border-radius:12px;padding:12px;margin-bottom:10px;background:rgba(255,255,255,.03)}.sec .k{font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.14em;color:var(--gold);text-transform:uppercase;margin-bottom:6px}.sec p,.sec li{color:var(--dim);font-size:13px;line-height:1.55;margin:4px 0}.overlay{position:fixed;inset:0;z-index:300;background:rgba(2,5,10,.5);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);display:none;align-items:flex-start;justify-content:center;padding:9vh 16px}.overlay.show{display:flex}.modal{width:100%;max-width:520px;border-radius:20px;padding:20px}.modal h2{font-family:ui-monospace,monospace;font-size:13px;letter-spacing:.1em;margin:0 0 12px;color:var(--gold)}.rngrow{display:flex;justify-content:space-between;font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.06em;color:var(--dim)}.rng{width:100%;accent-color:var(--gold);margin:3px 0 12px}.btn{font-family:ui-monospace,monospace;font-size:11px;border:1px solid var(--glass-edge);background:rgba(255,255,255,.05);color:var(--dim);border-radius:9px;padding:7px 12px;cursor:pointer}.foot{color:var(--mute);font-family:ui-monospace,monospace;font-size:11px;margin-top:28px;text-align:center}</style></head><body><div class='welcome' id='welcome'><div><div style='font-size:52px'>🛡️</div><h1 class='wtitle'>Mac Backup &amp; Recovery Toolkit<br><span class='wt2'>Choose Your Mode</span></h1><div class='weyebrow'>IT Support · Self-Hosted · Offline</div><p class='wtag'>Six backup modes, each with a full audit receipt. Empty and Apple-default folders are auto-skipped. Click any card to see exactly what it does.</p><button class='wcta' onclick='dismissWelcome()'>I’m Ready →</button></div></div><div class='topbar'><div class='brand'>🛡️ <b>MAC</b> BACKUP &amp; RECOVERY</div><span class='live'><i></i>LIVE</span><span class='chip'>IT SUPPORT</span><div class='sp'></div><button class='gear' onclick='openSettings()'>⚙ CONTROLS</button></div><div class='wrap'><div class='eyebrow'>Mac Backup &amp; Recovery · v" & appVersion & "</div><div class='hero'>Choose Your <span>Mode</span></div><div class='sub'>Six options — click any card for full details in the side panel. A detailed audit receipt is saved for every run.</div><div class='shimmer'></div><div class='cards'><div class='card glass' onclick='openMode(1)'><div class='tag z'>① ZIP → Box</div><h2>Standard Corporate</h2><p>Automatic, compressed. Standard folder set. Legal Hold.</p><span class='more'>CLICK FOR DETAILS →</span></div><div class='card glass' onclick='openMode(2)'><div class='tag c'>② ZIP → Box</div><h2>Custom</h2><p>You pick the folders. Saves to Box.</p><span class='more'>CLICK FOR DETAILS →</span></div><div class='card glass' onclick='openMode(3)'><div class='tag r'>③ RAW → Box</div><h2>Standard — Uncompressed</h2><p>Same set as ①, copied raw. Box-first migration.</p><span class='more'>CLICK FOR DETAILS →</span></div><div class='card glass' onclick='openMode(4)'><div class='tag re'>④ RESTORE</div><h2>Bookmarks Only</h2><p>Restore Safari + Chrome for a new device.</p><span class='more'>CLICK FOR DETAILS →</span></div><div class='card glass' onclick='openMode(5)'><div class='tag d'>⑤ ZIP → ANY</div><h2>Custom + Choose Destination</h2><p>You pick the folders AND where to save.</p><span class='more'>CLICK FOR DETAILS →</span></div><div class='card glass' onclick='openMode(6)'><div class='tag d'>⑥ ZIP → ANY</div><h2>Standard + Choose Destination</h2><p>Default folder set, but you choose the destination.</p><span class='more'>CLICK FOR DETAILS →</span></div></div><div class='foot'>IT Support — For internal use only. " & appTitle & " v" & appVersion & " · Host " & hostName & " · " & nowH & "</div></div><div class='drawer glass' id='drawer'><div class='dhead'><h2 id='dTitle'>Mode</h2><button class='x' onclick='closeDrawer()'>✕ Close</button></div><div class='dbody' id='dBody'></div></div><div id='dets' style='display:none'><div id='det1' data-title='① Standard Corporate — ZIP → Box'><div class='sec'><div class='k'>Objective</div><p>Preserve data from a departing or terminated employee before the machine is wiped and reissued.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>✅ Desktop, Documents, Downloads</li><li>✅ Movies, Music, Pictures</li><li>✅ Safari + Chrome bookmarks</li></ul></div><div class='sec'><div class='k'>Destination</div><p>Box ▸ " & personalFolderName & " ▸ " & backupSubfolder & " ▸ Backup_" & ts & " (compressed ZIP). Verified writable before copying.</p></div><div class='sec'><div class='k'>Use case</div><p>Legal Hold.</p></div></div><div id='det2' data-title='② Custom — ZIP → Box'><div class='sec'><div class='k'>Objective</div><p>Back up a specific set of folders that you choose.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>🎯 Any folders you select (hold ⌘ for multiple)</li><li>✅ Safari + Chrome bookmarks</li></ul></div><div class='sec'><div class='k'>Destination</div><p>Box ▸ " & personalFolderName & " ▸ " & backupSubfolder & " ▸ Backup_" & ts & " (ZIP).</p></div><div class='sec'><div class='k'>Use case</div><p>Targeted or ad-hoc backups to Box.</p></div></div><div id='det3' data-title='③ Standard — RAW → Box'><div class='sec'><div class='k'>Objective</div><p>The same standard set as ①, copied uncompressed (raw) for a Box-first migration.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>✅ Desktop, Documents, Downloads, Movies, Music, Pictures</li><li>✅ Bookmarks</li><li>⚠️ Larger footprint and slower sync than ZIP (by design)</li></ul></div><div class='sec'><div class='k'>Destination</div><p>Box ▸ " & personalFolderName & " ▸ " & backupSubfolder & " ▸ Backup_" & ts & " (raw copy).</p></div><div class='sec'><div class='k'>Use case</div><p>System-update or migration moving users to Box as their default location.</p></div></div><div id='det4' data-title='④ Restore — Bookmarks Only'><div class='sec'><div class='k'>Objective</div><p>Restore browser bookmarks onto a new device.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>✅ Safari + Chrome bookmarks</li><li>🛟 Your current bookmarks are snapshotted first</li><li>🔒 Browsers are quit before writing</li></ul></div><div class='sec'><div class='k'>Requires</div><p>🔒 Full Disk Access for this app.</p></div><div class='sec'><div class='k'>Use case</div><p>Device refresh or onboarding after a Box-first migration.</p></div></div><div id='det5' data-title='⑤ Custom + Choose Destination — ZIP'><div class='sec'><div class='k'>Objective</div><p>Back up the folders you choose to a destination you choose.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>🎯 Any folders you select</li><li>✅ Bookmarks</li></ul></div><div class='sec'><div class='k'>Destination</div><p>📍 Any writable location — Box, Network share, OneDrive, external drive — inside Backup_" & ts & ". Verified writable before copying.</p></div><div class='sec'><div class='k'>Use case</div><p>When the backup must land somewhere other than the default Box personal folder.</p></div></div><div id='det6' data-title='⑥ Custom + Default Folders — ZIP'><div class='sec'><div class='k'>Objective</div><p>The standard folder set (like ①), but you choose the destination. No Legal Hold labelling.</p></div><div class='sec'><div class='k'>Includes</div><ul><li>✅ Desktop, Documents, Downloads, Movies, Music, Pictures</li><li>✅ Bookmarks</li></ul></div><div class='sec'><div class='k'>Destination</div><p>📍 Any writable location — Box, Network, OneDrive, external — inside Backup_" & ts & ". Verified writable before copying.</p></div><div class='sec'><div class='k'>Use case</div><p>A standard-set backup that must land somewhere other than the default Box folder.</p></div></div></div><div class='overlay' id='settings'><div class='modal glass'><h2>⚙ Appearance — Liquid Glass</h2><div class='rngrow'><span>BLUR</span><span id='vBlur'></span></div><input class='rng' id='sBlur' type='range' min='8' max='48' oninput='setBlur(this.value)'><div class='rngrow'><span>PANEL FILL · lower = more see-through</span><span id='vFill'></span></div><input class='rng' id='sFill' type='range' min='25' max='90' oninput='setFill(this.value)'><div class='rngrow'><span>DEPTH / SHADOW</span><span id='vDepth'></span></div><input class='rng' id='sDepth' type='range' min='40' max='100' oninput='setDepth(this.value)'><div style='display:flex;gap:8px;margin-top:10px'><button class='btn' onclick='Glass.reset()'>↺ Reset Glass</button><button class='btn' onclick='closeSettings()'>Done</button></div></div></div><script>var LSK='bydtb.';function lget(k,d){try{var v=localStorage.getItem(LSK+k);return v===null?d:JSON.parse(v)}catch(e){return d}}function lset(k,v){try{localStorage.setItem(LSK+k,JSON.stringify(v))}catch(e){}}var Glass={def:{blur:26,fill:55,depth:80},get:function(){var g=lget('glass',{});return {blur:g.blur||this.def.blur,fill:g.fill||this.def.fill,depth:g.depth||this.def.depth}},apply:function(){var g=this.get(),r=document.documentElement.style;r.setProperty('--g-blur',g.blur+'px');r.setProperty('--g-fill-a',(g.fill/100).toFixed(2));r.setProperty('--g-shadow-a',(g.depth/100).toFixed(2))},set:function(k,v){var g=this.get();g[k]=+v;lset('glass',g);this.apply()},reset:function(){lset('glass',{});this.apply();syncSliders()}};function setBlur(v){Glass.set('blur',v);document.getElementById('vBlur').textContent=v+'px'}function setFill(v){Glass.set('fill',v);document.getElementById('vFill').textContent=v+'%'}function setDepth(v){Glass.set('depth',v);document.getElementById('vDepth').textContent=v+'%'}function syncSliders(){var g=Glass.get();document.getElementById('sBlur').value=g.blur;document.getElementById('vBlur').textContent=g.blur+'px';document.getElementById('sFill').value=g.fill;document.getElementById('vFill').textContent=g.fill+'%';document.getElementById('sDepth').value=g.depth;document.getElementById('vDepth').textContent=g.depth+'%'}function openMode(n){var s=document.getElementById('det'+n);document.getElementById('dTitle').textContent=s.getAttribute('data-title');document.getElementById('dBody').innerHTML=s.innerHTML;document.getElementById('drawer').classList.add('open')}function closeDrawer(){document.getElementById('drawer').classList.remove('open')}function openSettings(){document.getElementById('settings').classList.add('show')}function closeSettings(){document.getElementById('settings').classList.remove('show')}function dismissWelcome(){document.getElementById('welcome').classList.add('hide');lset('welcomeSeen',true)}document.addEventListener('keydown',function(e){if(e.key==='Escape'){closeDrawer();closeSettings()}});Glass.apply();syncSliders();if(lget('welcomeSeen',false)===true){document.getElementById('welcome').classList.add('hide')}</script></body></html>"
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

        set html to "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1'><title>Backup Receipt - " & serialNum & "</title><style>*{box-sizing:border-box}:root{--gold:#e8b54b;--cyan:#00e5ff;--green:#00e08a;--bg:#05080d;--txt:#d7e6f2;--dim:#9fb4c6;--mute:#6b7686;--g-blur:26px;--g-fill-a:.55;--g-shadow-a:.8;--glass-hi:rgba(255,255,255,.14);--glass-edge:rgba(255,255,255,.2)}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial,sans-serif;background:var(--bg);color:var(--txt);background-image:linear-gradient(rgba(0,229,255,.04) 1px,transparent 1px),linear-gradient(90deg,rgba(0,229,255,.04) 1px,transparent 1px);background-size:44px 44px}body:before{content:'';position:fixed;inset:0;z-index:0;pointer-events:none;background:radial-gradient(1100px 600px at 12% -8%,rgba(0,229,255,.10),transparent 62%),radial-gradient(900px 520px at 92% 4%,rgba(232,181,75,.10),transparent 60%)}.glass{background:linear-gradient(180deg,var(--glass-hi),rgba(255,255,255,0) 46%),rgba(14,21,33,var(--g-fill-a));-webkit-backdrop-filter:blur(var(--g-blur)) saturate(180%);backdrop-filter:blur(var(--g-blur)) saturate(180%);border:1px solid var(--glass-edge);box-shadow:0 1px 0 rgba(255,255,255,.22) inset,0 -14px 30px -26px rgba(0,0,0,var(--g-shadow-a)) inset,0 28px 60px -22px rgba(0,0,0,var(--g-shadow-a))}.topbar{position:sticky;top:0;z-index:60;display:flex;align-items:center;gap:10px;padding:9px 16px;border-bottom:1px solid var(--glass-edge);-webkit-backdrop-filter:blur(24px) saturate(180%);backdrop-filter:blur(24px) saturate(180%);background:linear-gradient(180deg,rgba(5,8,13,.9),rgba(5,8,13,.7))}.brand{font-family:ui-monospace,Menlo,monospace;font-weight:800;letter-spacing:.12em;font-size:13px;display:flex;gap:8px;align-items:center}.brand b{color:var(--gold)}.chip{font-family:ui-monospace,monospace;font-size:10px;color:var(--gold);border:1px solid rgba(232,181,75,.4);background:rgba(232,181,75,.1);padding:3px 9px;border-radius:20px}.sp{flex:1}.gear{font-family:ui-monospace,monospace;font-size:12px;color:var(--dim);background:rgba(255,255,255,.05);border:1px solid var(--glass-edge);border-radius:9px;padding:6px 11px;cursor:pointer}.gear:hover{color:var(--cyan);border-color:var(--cyan)}.wrap{position:relative;z-index:1;max-width:1050px;margin:0 auto;padding:26px 20px 70px}.eyebrow{font-family:ui-monospace,monospace;font-size:11px;letter-spacing:3px;color:var(--gold);text-transform:uppercase}.shimmer{height:3px;border-radius:4px;margin-top:16px;background:linear-gradient(90deg,transparent,var(--gold),var(--cyan),transparent);background-size:200% 100%;animation:sh 4s linear infinite}@keyframes sh{to{background-position:-200% 0}}.foot{color:var(--mute);font-family:ui-monospace,monospace;font-size:11px;margin-top:28px;text-align:center}.overlay{position:fixed;inset:0;z-index:300;background:rgba(2,5,10,.5);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);display:none;align-items:flex-start;justify-content:center;padding:9vh 16px}.overlay.show{display:flex}.modal{width:100%;max-width:520px;border-radius:20px;padding:20px}.modal h2{font-family:ui-monospace,monospace;font-size:13px;letter-spacing:.1em;margin:0 0 12px;color:var(--gold)}.rngrow{display:flex;justify-content:space-between;font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.06em;color:var(--dim)}.rng{width:100%;accent-color:var(--gold);margin:3px 0 12px}.btn{font-family:ui-monospace,monospace;font-size:11px;border:1px solid var(--glass-edge);background:rgba(255,255,255,.05);color:var(--dim);border-radius:9px;padding:7px 12px;cursor:pointer}.live{display:inline-flex;align-items:center;gap:6px;font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.16em}.rhead{font-size:26px;font-weight:900;margin-top:8px}.rhead span{color:var(--gold)}.rsub{color:var(--dim);font-size:12px;margin-top:6px;font-family:ui-monospace,monospace;line-height:1.5}.kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-top:20px}.kpi{border-radius:14px;padding:14px 16px}.kpi .l{font-family:ui-monospace,monospace;font-size:10px;letter-spacing:.12em;color:var(--mute);text-transform:uppercase}.kpi .v{font-size:16px;font-weight:800;margin-top:6px;word-break:break-word}.rcard{border-radius:16px;padding:20px;margin-top:16px}.rcard h3{margin:0 0 6px;color:var(--gold);font-family:ui-monospace,monospace;font-size:12px;letter-spacing:.1em}.decision{font-size:30px;font-weight:900;letter-spacing:2px}.decision.ok{color:var(--green)}.decision.warn{color:#f0b429}.decision.bad{color:#ff5c6c}table{width:100%;border-collapse:collapse;margin-top:8px;font-size:13px}th,td{text-align:left;padding:10px 12px;border-bottom:1px solid var(--glass-edge);vertical-align:top}th{color:var(--gold);font-size:11px;text-transform:uppercase;letter-spacing:.1em}.mono{font-family:ui-monospace,Menlo,monospace;font-size:12px;color:var(--dim)}.pill{padding:3px 10px;border-radius:999px;font-size:11px;font-weight:700}.pill.ok{background:rgba(0,224,138,.18);color:var(--green);border:1px solid rgba(0,224,138,.5)}.pill.warn{background:rgba(240,180,41,.18);color:#f0b429;border:1px solid rgba(240,180,41,.5)}.pill.bad{background:rgba(255,92,108,.18);color:#ff5c6c;border:1px solid rgba(255,92,108,.5)}</style></head><body><div class='topbar'><div class='brand'>🛡️ <b>MAC</b> BACKUP &amp; RECOVERY</div><span class='pill " & decClass & "'>" & decision & "</span><span class='chip'>IT SUPPORT</span><div class='sp'></div><button class='gear' onclick='openSettings()'>⚙ CONTROLS</button></div><div class='wrap'><div class='eyebrow'>Mac Backup &amp; Recovery · v" & appVersion & " · Receipt</div><div class='rhead'>MAC BACKUP &amp; <span>RECOVERY</span> — Receipt</div><div class='rsub'>Mode " & modeLabel & " · User " & consoleUser & " · Host " & hostName & " · Serial " & serialNum & " · macOS " & osVer & " (" & osBuild & ") · " & nowH & "</div><div class='shimmer'></div><div class='kpis'><div class='kpi glass'><div class='l'>Mode</div><div class='v'>" & modeLabel & "</div></div><div class='kpi glass'><div class='l'>Destination</div><div class='v'>" & destShown & "</div></div><div class='kpi glass'><div class='l'>Files</div><div class='v'>" & totalFiles & "</div></div><div class='kpi glass'><div class='l'>Total Size</div><div class='v'>" & totalSizeH & "</div></div><div class='kpi glass'><div class='l'>Free Space</div><div class='v'>" & freeH & "</div></div><div class='kpi glass'><div class='l'>Full Disk Access</div><div class='v'>" & fdaLabel & "</div></div><div class='kpi glass'><div class='l'>Bookmarks</div><div class='v'>" & bmSummary & "</div></div><div class='kpi glass'><div class='l'>Result</div><div class='v'>" & resultText & "</div></div></div><div class='rcard glass'><div style='font-family:ui-monospace,monospace;font-size:11px;letter-spacing:.12em;color:var(--mute)'>DECISION</div><div class='decision " & decClass & "'>" & decision & "</div></div><div class='rcard glass'><h3>FINDINGS / RESULTS</h3><table><tr><th>Item</th><th>Status</th><th>Detail</th></tr>" & rows & "</table></div><div class='rcard glass'><h3>NOTES &amp; GUARANTEES</h3><p style='color:var(--dim);font-size:13px;line-height:1.6'>Standard set (modes ① ③ ⑥) = Desktop + Documents + Downloads + Movies + Music + Pictures + bookmarks. Apple default items (.localized, .DS_Store, Icon, empty libraries) are ignored; real imported Photos (originals) ARE included. Modes ⑤ ⑥ let the user choose any writable destination (Box / Network / OneDrive / external) and verify it before copying. Logs &amp; receipts saved under /Users/Shared/mac-backup-recovery-toolkit/. Sources are read-only (ditto). ZIP verifies size + entry count; RAW verifies file-count parity. Restore quits browsers and snapshots current bookmarks first. Browser bookmarks need Full Disk Access for THIS app. Full detail in backup.log.</p></div><div class='foot'>IT Support — For internal use only. " & appTitle & " v" & appVersion & " · Log: backup.log</div></div><div class='overlay' id='settings'><div class='modal glass'><h2>⚙ Appearance — Liquid Glass</h2><div class='rngrow'><span>BLUR</span><span id='vBlur'></span></div><input class='rng' id='sBlur' type='range' min='8' max='48' oninput='setBlur(this.value)'><div class='rngrow'><span>PANEL FILL · lower = more see-through</span><span id='vFill'></span></div><input class='rng' id='sFill' type='range' min='25' max='90' oninput='setFill(this.value)'><div class='rngrow'><span>DEPTH / SHADOW</span><span id='vDepth'></span></div><input class='rng' id='sDepth' type='range' min='40' max='100' oninput='setDepth(this.value)'><div style='display:flex;gap:8px;margin-top:10px'><button class='btn' onclick='Glass.reset()'>↺ Reset Glass</button><button class='btn' onclick='closeSettings()'>Done</button></div></div></div><script>var LSK='bydtb.';function lget(k,d){try{var v=localStorage.getItem(LSK+k);return v===null?d:JSON.parse(v)}catch(e){return d}}function lset(k,v){try{localStorage.setItem(LSK+k,JSON.stringify(v))}catch(e){}}var Glass={def:{blur:26,fill:55,depth:80},get:function(){var g=lget('glass',{});return {blur:g.blur||this.def.blur,fill:g.fill||this.def.fill,depth:g.depth||this.def.depth}},apply:function(){var g=this.get(),r=document.documentElement.style;r.setProperty('--g-blur',g.blur+'px');r.setProperty('--g-fill-a',(g.fill/100).toFixed(2));r.setProperty('--g-shadow-a',(g.depth/100).toFixed(2))},set:function(k,v){var g=this.get();g[k]=+v;lset('glass',g);this.apply()},reset:function(){lset('glass',{});this.apply();syncSliders()}};function setBlur(v){Glass.set('blur',v);document.getElementById('vBlur').textContent=v+'px'}function setFill(v){Glass.set('fill',v);document.getElementById('vFill').textContent=v+'%'}function setDepth(v){Glass.set('depth',v);document.getElementById('vDepth').textContent=v+'%'}function syncSliders(){var g=Glass.get();document.getElementById('sBlur').value=g.blur;document.getElementById('vBlur').textContent=g.blur+'px';document.getElementById('sFill').value=g.fill;document.getElementById('vFill').textContent=g.fill+'%';document.getElementById('sDepth').value=g.depth;document.getElementById('vDepth').textContent=g.depth+'%'}function openSettings(){document.getElementById('settings').classList.add('show')}function closeSettings(){document.getElementById('settings').classList.remove('show')}document.addEventListener('keydown',function(e){if(e.key==='Escape'){closeSettings()}});Glass.apply();syncSliders();</script></body></html>"
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