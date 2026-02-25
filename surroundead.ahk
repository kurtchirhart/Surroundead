#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; --- Configuration ---
IniFile := A_ScriptDir . "\surroundead.ini"
ReelDelay := IniRead(IniFile, "Settings", "ReelDelay", 1000)
PosX := IniRead(IniFile, "Settings", "PosX", 1800)
PosY := IniRead(IniFile, "Settings", "PosY", 500)
DebugMode := IniRead(IniFile, "Settings", "DebugMode", 0)
Alpha := IniRead(IniFile, "Settings", "Alpha", 150)

TargetWindow := "ahk_exe Surroundead-Win64-Shipping.exe"
try TraySetIcon "shell32.dll", 42

; --- Global State ---
Running := false
SettingsOpen := false

; --- GUI Setup (Settings Window) ---
; --- Menu Setup ---
FileMenu := MenuBar()
FileMenu.Add("&Reload Script", (*) => Reload())
MainGui := Gui("+AlwaysOnTop", "Settings")
MainGui.MenuBar := FileMenu
MainGui.SetFont("s10", "Segoe UI")
MainGui.Add("Text", "w150", "Reel Delay (ms):")
MainGui.Add("Edit", "x+5 yp w100 vReelDelay", ReelDelay).OnEvent("Change", SaveSettings)
MainGui.Add("Text", "xm w150", "Detector X Offset:")
MainGui.Add("Edit", "x+5 yp w100 vPosX", PosX).OnEvent("Change", SaveSettings)
MainGui.Add("Text", "xm w150", "Detector Y Offset:")
MainGui.Add("Edit", "x+5 yp w100 vPosY", PosY).OnEvent("Change", SaveSettings)
MainGui.Add("Checkbox", "xm vDebugMode", "Show Debug Log").OnEvent("Click", ToggleDebugFromSettings)
MainGui["DebugMode"].Value := DebugMode
MainGui.Add("Text", "xm w150", "OSD Transparency:")
MainGui.Add("Slider", "x+5 yp w100 vAlpha Range0-255 ToolTip", Alpha).OnEvent("Change", UpdateAlpha)
MainGui.Add("Button", "xm w125", "Reload Script").OnEvent("Click", (*) => Reload())
MainGui.Add("Button", "x+10 yp w125", "Close Script").OnEvent("Click", (*) => ExitApp())


MainGui.OnEvent("Close", (*) => (SettingsOpen := false, MainGui.Hide()))
MainGui.OnEvent("Escape", (*) => (SettingsOpen := false, MainGui.Hide()))

; --- Tracker Box Setup ---
TrackerGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
TrackerGui.BackColor := "Red"

; --- OSD Setup ---
; We are using a left and a right GUI to fake a two colum table with
; left hand buttons and right side status lines
L_Width := 40
R_Width := 200
Padding := 100

; Calculate X to anchor to the top right
L_X := A_ScreenWidth - L_Width - R_Width - Padding
R_X := L_X + L_Width

; Setup
L_Gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x02000000")
R_Gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x02000000")
L_Gui.BackColor := R_Gui.BackColor := "1A1A1A"
L_Gui.SetFont("s12 cWhite")
R_Gui.SetFont("s12 cWhite")

L_Gui.Add("Text",, "❌").OnEvent("Click", (*) => ExitApp())
R_Gui.Add("Text",, "Close Script")

L_Gui.Add("Text",, "⚙️").OnEvent("Click", (*) => ToggleSettings())
R_Gui.Add("Text",, "Settings (ctrl-alt-s)")

; L_Gui.Add("Text",, "🐛").OnEvent("Click", (*) => ToggleDebug())
; R_Gui.Add("Text",, "Toggle Debug")

L_Gui.Add("Text",, "🔄").OnEvent("Click", (*) => Reload())
R_Gui.Add("Text",, "Reload (ctrl-alt-r)")

L_Gui.Add("Text",, "🎣").OnEvent("Click", (*) => ToggleFishing())
line1 := R_Gui.Add("Text", "-Wrap", "Start Fishing(F1)")

L_Gui.Add("Text",, "")
line2 := R_Gui.Add("Text",, "                                  ")

L_Gui.Show("x" L_X " y" Padding " w" L_Width " NoActivate")
R_Gui.Show("x" R_X + 10 " y" Padding " w" R_Width " NoActivate")

WinSetTransparent(Alpha, L_Gui.Hwnd)
WinSetTransparent(Alpha, R_Gui.Hwnd)

; Collect some info for our debug window
L_Gui.GetPos(,,,&OSD_H)
Width := L_Width + R_Width


; --- Debug OSD Setup ---
DebugColor := "240000"
DebugGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "DebugOSD")
DebugGui.BackColor := DebugColor

; Use a monospaced font for logs so they align nicely
DebugGui.SetFont("s9 cffffff", "Consolas") 

; -E0x200 removes the 3D border, BackColor sets the internal box color
DebugText := DebugGui.Add("Edit", "w" Width " h300 +ReadOnly +Wrap -E0x200 cffffff")
DebugText.Opt("Background" . DebugColor) ; This is the correct v2 syntax

LogToGui(NewText) {
    global DebugText
    DebugText.Value .= NewText . "`n"
    SendMessage(0x0115, 7, 0, DebugText.Hwnd, "A") ; WM_VSCROLL to bottom
}

DebugGui.Show("x" L_X " y" (OSD_H + Padding + 50) " NoActivate")
if !DebugMode
    DebugGui.Hide()

SetTimer CheckWindowFocus, 100

; Loop 91 {
;     LogToGui("Test line " . A_Index)
; }
; --- Functions ---

SaveSettings(*) {
    global ReelDelay, PosX, PosY
    Saved := MainGui.Submit(false)
    ReelDelay := Saved.ReelDelay
    PosX := Saved.PosX
    PosY := Saved.PosY
    IniWrite(ReelDelay, IniFile, "Settings", "ReelDelay")
    IniWrite(PosX, IniFile, "Settings", "PosX")
    IniWrite(PosY, IniFile, "Settings", "PosY")
}

UpdateAlpha(*) {
    global Alpha
    Alpha := MainGui["Alpha"].Value
    WinSetTransparent(Alpha, L_Gui.Hwnd)
    WinSetTransparent(Alpha, R_Gui.Hwnd)
    IniWrite(Alpha, IniFile, "Settings", "Alpha")
}

LogDebug(Msg) {
    try DebugText.Value := Msg . "`n" . DebugText.Value
}

F1::ToggleFishing()

ToggleFishing() {
    global Running
    if (Running) {
        StopFishing()
    } else {
        ; StartFishing is a loop, so we run it in a new thread 
        ; to keep the GUI responsive
        SetTimer(StartFishing, -1) 
    }
}

StopFishing() {
    global Running
    Running := false
    LogDebug("[Idle]")
    line1.Value := "Start fishing(F1)"
    line1.Opt("+" . "cffffff")
    line2.Value:=""
    TrackerGui.Hide()
}

StartFishing() {
    global Running
    if Running
        return
    
    Running := true
    ; line1.Opt("-Wrap")
    line1.Value := "Stop Fishing(F1)"
    line1.Opt("+" . "caaffaa")
    
    Loop {
        if !Running
            break
            
        if WinActive(TargetWindow) {
            LogDebug("Casting line...")
            line2.Value := "Casting"
            line2.Opt("+" . "caaffaa")
            ControlClick(, TargetWindow,,,, "R D")
            Sleep(100)
            ControlClick(, TargetWindow,,,, "R U")
            Sleep(2000)
            
            LogDebug("Scanning for bite...")
            line2.Value := "Scanning"
            TrackerGui.BackColor := "Red"
            TrackerGui.Show("x" PosX " y" PosY " w12 h12 NoActivate")
            
            Loop {
                if !Running
                    break
                
                ; Search for Dark/Black (Variation 15)
                if PixelSearch(&Px, &Py, PosX-20, PosY-20, PosX+20, PosY+20, 0x050505, 15) {
                        TrackerGui.BackColor := "Green"
                        break
                }
                
                ; Search for White text (Variation 10)
                if PixelSearch(&Px, &Py, PosX-20, PosY-20, PosX+20, PosY+20, 0xFFFFFF, 10) {
                        TrackerGui.BackColor := "Green"
                        break
                }
                
                Sleep(100)
            }
            
            if !Running
                break

            LogDebug("BITE FOUND! Reeling...")
            line2.Value := "Bite! Reeling in!"
            ControlClick(, TargetWindow,,,, "R D")
            Sleep(100)
            ControlClick(, TargetWindow,,,, "R U")
            
            Sleep(800)
            TrackerGui.Hide()
            Sleep(ReelDelay)
        } else {
            LogDebug("Paused (Focus Game)")
            line2.Value := "Focus Game"
            line2.Opt("+" . "cffaaaa")
            Sleep(1000)
            TrackerGui.Hide()
            Sleep(1000)
        }
    }
}

ToggleSettings() {
    global SettingsOpen
    SettingsOpen := !SettingsOpen
    if SettingsOpen
        MainGui.Show("x50 y50")
    else
        MainGui.Hide()
}

ToggleDebug(*) {
    global DebugMode
    DebugMode := !DebugMode
    MainGui["DebugMode"].Value := DebugMode
    ToggleDebugFromSettings()
}

ToggleDebugFromSettings(*) {
    global DebugMode
    DebugMode := MainGui["DebugMode"].Value
    IniWrite(DebugMode, IniFile, "Settings", "DebugMode")
    if !DebugMode
        DebugGui.Hide()
    else
        DebugGui.Show("NoActivate")
}

CheckWindowFocus() {
    ; Check if Game or Settings is active
    IsGameActive := WinActive(TargetWindow)
    IsSettingsActive := WinActive("ahk_id " MainGui.Hwnd)
    
    ShouldBeVisible := IsGameActive || IsSettingsActive
    
    if ShouldBeVisible {
        if !WinExist("ahk_id " L_Gui.Hwnd) {
             L_Gui.Show("NoActivate")
             R_Gui.Show("NoActivate")
             if DebugMode
                DebugGui.Show("NoActivate")
        }
        if SettingsOpen && !WinExist("ahk_id " MainGui.Hwnd)
            MainGui.Show("NoActivate")
    } else {
        L_Gui.Hide()
        R_Gui.Hide()
        DebugGui.Hide()
        if WinExist("ahk_id " MainGui.Hwnd)
            MainGui.Hide()
    }
}

; --- Hotkeys ---

^!s::ToggleSettings()

^!r::Reload

XButton1::f
XButton2::e
