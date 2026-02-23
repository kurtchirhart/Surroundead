#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; --- Configuration ---
IniFile := A_ScriptDir . "\surroundead.ini"
IniRead, ReelDelay, %IniFile%, Settings, ReelDelay, 1000
IniRead, PosX, %IniFile%, Settings, PosX, 1800
IniRead, PosY, %IniFile%, Settings, PosY, 500

TargetWindow := "ahk_exe Surroundead-Win64-Shipping.exe"
Menu, Tray, Icon, shell32.dll, 42 

; --- Menu Setup ---
Menu, FileMenu, Add, &Reload Script, ReloadRoutine
Gui, Main: Menu, FileMenu

; --- GUI Setup (Settings Window) ---
Gui, Main: +AlwaysOnTop
Gui, Main: Font, s10, Segoe UI
Gui, Main: Add, Text,, Reel Delay (ms):
Gui, Main: Add, Edit, vReelDelay gSaveSettings, %ReelDelay%
Gui, Main: Add, Text,, Detector X Offset:
Gui, Main: Add, Edit, vPosX gSaveSettings, %PosX%
Gui, Main: Add, Text,, Detector Y Offset:
Gui, Main: Add, Edit, vPosY gSaveSettings, %PosY%
; Gui, Main: Add, Text, vStatusText w200 cRed, Status: Stopped ; -- Replaced by OSD
Gui, Main: Add, Text, vSubStatus w200 cGray, [Idle]

Gui, Main: Add, Button, gStart Default w80, Start (F1)
Gui, Main: Add, Button, gStop x+10 w80, Stop (F2)
; The GUI is now created but not shown by default. Use Ctrl+Alt+S to show it.

; --- Tracker Box Setup ---
Gui, Tracker: +AlwaysOnTop -Caption +ToolWindow +E0x20 
Gui, Tracker: Color, Red

; --- OSD Setup ---
Gui, OSD:New, +AlwaysOnTop -Caption +ToolWindow, StatusOSD
Gui, OSD:Color, 000000
Gui, OSD:Font, s10 cFFFFFF, Segoe UI
Gui, OSD:Add, Text, vStatusOSDText w200 cRed, Status: Stopped
Gui, OSD:Font, s8 cAAAAAA
Gui, OSD:Add, Text, y+5 w200 gOpenSettings, [Settings]
SysGet, MonitorWidth, 76
OSD_Width := 220
OSD_X := MonitorWidth - OSD_Width
Gui, OSD:Show, x%OSD_X% y0 W%OSD_Width% NoActivate
WinSet, Transparent, 150, StatusOSD

return

; --- Hotkeys & Routines ---

^!s:: ; Ctrl+Alt+S to show Settings
OpenSettings:
    Gui, Main:Show
return

SaveSettings:
    Gui, Main:Submit, NoHide
    IniWrite, %ReelDelay%, %IniFile%, Settings, ReelDelay
    IniWrite, %PosX%, %IniFile%, Settings, PosX
    IniWrite, %PosY%, %IniFile%, Settings, PosY
return

^!r:: ; Ctrl+Alt+R to Reload
ReloadRoutine:
    ; OSD Stub: Call OSD function here in the future
    Reload
return

; --- Controls ---

F1::
Start:
; Settings are now saved automatically, no need to submit the GUI here.
Running := true
GuiControl, OSD:, StatusOSDText, Status: FISHING...
GuiControl, OSD:+cGreen, StatusOSDText
Loop
{
    if !Running
        break
    
    if WinActive(TargetWindow)
    {
        GuiControl, Main:, SubStatus, Casting line...
        ControlClick,, %TargetWindow%,,,, R D
        Sleep, 100
        ControlClick,, %TargetWindow%,,,, R U
        Sleep, 2000 
        
        GuiControl, Main:, SubStatus, Scanning for bite...
        Gui, Tracker: Color, Red
        ; Uses the X and Y values from your GUI
        Gui, Tracker: Show, x%PosX% y%PosY% w12 h12 NoActivate
        
        Loop 
        {
            if !Running
                break
            
            ; 1. Search for Dark/Black with 15 shades of variation
            PixelSearch, Px, Py, PosX-20, PosY-20, PosX+20, PosY+20, 0x050505, 15, Fast RGB
            DarkFound := !ErrorLevel
            
            ; 2. Search for White text (0xFFFFFF)
            PixelSearch, Px, Py, PosX-20, PosY-20, PosX+20, PosY+20, 0xFFFFFF, 10, Fast RGB
            WhiteFound := !ErrorLevel

            if (DarkFound or WhiteFound)
            {
                Gui, Tracker: Color, Green
                break
            }
            Sleep, 100 
        }
        
        GuiControl, Main:, SubStatus, BITE FOUND! Reeling...
        ControlClick,, %TargetWindow%,,,, R D
        Sleep, 100
        ControlClick,, %TargetWindow%,,,, R U
        
        Sleep, 800 
        Gui, Tracker: Hide
        Sleep, %ReelDelay%
    }
    else
    {
        GuiControl, Main:, SubStatus, Paused (Focus Game)
        Gui, Tracker: Hide
        Sleep, 1000 
    }
}
return

F2::
Stop:
Running := false
GuiControl, OSD:, StatusOSDText, Status: Stopped
GuiControl, OSD:+cRed, StatusOSDText
GuiControl, Main:, SubStatus, [Idle]
Gui, Tracker: Hide
return

MainGuiClose:
MainGuiEscape:
    Gui, Main:Hide
return

; --- Mouse Button Remaps ---
XButton1::f  ; Browser Back -> f
XButton2::e  ; Browser Forward -> e

