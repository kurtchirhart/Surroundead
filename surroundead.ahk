#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

; --- Configuration ---
IniFile := A_ScriptDir . "\surroundead.ini"
ReelDelay := IniRead(IniFile, "Settings", "ReelDelay", 1000)
PosX := IniRead(IniFile, "Settings", "PosX", 1800)
PosY := IniRead(IniFile, "Settings", "PosY", 500)

TargetWindow := "ahk_exe Surroundead-Win64-Shipping.exe"
try TraySetIcon "shell32.dll", 42

; --- Global State ---
Running := false

; --- Menu Setup ---
FileMenu := MenuBar()
FileMenu.Add("&Reload Script", (*) => Reload())

; --- GUI Setup (Settings Window) ---
MainGui := Gui("+AlwaysOnTop", "Settings")
MainGui.MenuBar := FileMenu
MainGui.SetFont("s10", "Segoe UI")
MainGui.Add("Text",, "Reel Delay (ms):")
MainGui.Add("Edit", "vReelDelay", ReelDelay).OnEvent("Change", SaveSettings)
MainGui.Add("Text",, "Detector X Offset:")
MainGui.Add("Edit", "vPosX", PosX).OnEvent("Change", SaveSettings)
MainGui.Add("Text",, "Detector Y Offset:")
MainGui.Add("Edit", "vPosY", PosY).OnEvent("Change", SaveSettings)
MainGui.Add("Text",, "Status:")
SubStatusText := MainGui.Add("Text", "w200 cGray", "[Idle]")

MainGui.Add("Button", "w80 Default", "Start (F1)").OnEvent("Click", (*) => StartFishing())
MainGui.Add("Button", "x+10 w80", "Stop (F2)").OnEvent("Click", (*) => StopFishing())

MainGui.OnEvent("Close", (*) => MainGui.Hide())
MainGui.OnEvent("Escape", (*) => MainGui.Hide())

; --- Tracker Box Setup ---
TrackerGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
TrackerGui.BackColor := "Red"

; --- OSD Setup ---
OSDGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "StatusOSD")
OSDGui.BackColor := "000000"
OSDGui.SetFont("s10 cFFFFFF", "Segoe UI")
OSDStatusText := OSDGui.Add("Text", "w200 cRed", "Status: Stopped")
OSDGui.SetFont("s8 cAAAAAA")
OSDGui.Add("Text", "y+5 w200", "[Settings]").OnEvent("Click", (*) => MainGui.Show())

OSD_Width := 220
OSD_X := A_ScreenWidth - OSD_Width
OSDGui.Show("x" OSD_X " y0 w" OSD_Width " NoActivate")
WinSetTransparent(150, OSDGui.Hwnd)

; --- Debug OSD Setup ---
DebugGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "DebugOSD")
DebugGui.BackColor := "000000"
DebugGui.SetFont("s8 cGray", "Segoe UI")
DebugText := DebugGui.Add("Text", "w200 h300", "")
DebugGui.Show("x" OSD_X " y60 w" OSD_Width " NoActivate")
WinSetTransparent(150, DebugGui.Hwnd)

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

LogDebug(Msg) {
    try DebugText.Value := Msg . "`n" . DebugText.Value
}

StartFishing() {
    global Running
    if Running
        return
    
    Running := true
    OSDStatusText.Value := "Status: FISHING..."
    OSDStatusText.Opt("+cGreen")
    
    Loop {
        if !Running
            break
            
        if WinActive(TargetWindow) {
            LogDebug("Casting line...")
            ControlClick(, TargetWindow,,,, "R D")
            Sleep(100)
            ControlClick(, TargetWindow,,,, "R U")
            Sleep(2000)
            
            LogDebug("Scanning for bite...")
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
            ControlClick(, TargetWindow,,,, "R D")
            Sleep(100)
            ControlClick(, TargetWindow,,,, "R U")
            
            Sleep(800)
            TrackerGui.Hide()
            Sleep(ReelDelay)
        } else {
            LogDebug("Paused (Focus Game)")
            TrackerGui.Hide()
            Sleep(1000)
        }
    }
}

StopFishing() {
    global Running
    Running := false
    OSDStatusText.Value := "Status: Stopped"
    OSDStatusText.Opt("+cRed")
    LogDebug("[Idle]")
    TrackerGui.Hide()
}

; --- Hotkeys ---

^!s::MainGui.Show()

^!r::Reload

F1::StartFishing()

F2::StopFishing()

XButton1::f
XButton2::e
