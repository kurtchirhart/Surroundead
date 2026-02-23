#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; --- Configuration ---
TargetWindow := "ahk_exe Surroundead-Win64-Shipping.exe"
Menu, Tray, Icon, shell32.dll, 42 

; --- Menu Setup ---
Menu, FileMenu, Add, &Reload Script, ReloadRoutine
Gui, Main: Menu, FileMenu

; --- GUI Setup ---
Gui, Main: +AlwaysOnTop
Gui, Main: Font, s10, Segoe UI
Gui, Main: Add, Text,, Reel Delay (ms):
Gui, Main: Add, Edit, vReelDelay, 1000
Gui, Main: Add, Text,, Detector X Offset:
Gui, Main: Add, Edit, vPosX, 1800
Gui, Main: Add, Text,, Detector Y Offset:
Gui, Main: Add, Edit, vPosY, 500
Gui, Main: Add, Text, vStatusText w200 cRed, Status: Stopped
Gui, Main: Add, Text, vSubStatus w200 cGray, [Idle]

Gui, Main: Add, Button, gStart Default w80, Start (F1)
Gui, Main: Add, Button, gStop x+10 w80, Stop (F2)
Gui, Main: Show,, Surroundead Fisher

; --- Tracker Box Setup ---
Gui, Tracker: +AlwaysOnTop -Caption +ToolWindow +E0x20 
Gui, Tracker: Color, Red
return

; --- Menu Routine ---
ReloadRoutine:
Reload
return

; --- Controls ---

F1::
Start:
Gui, Main: Submit, NoHide
Running := true
GuiControl, Main:, StatusText, Status: FISHING...
GuiControl, Main: +cGreen, StatusText
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
GuiControl, Main:, StatusText, Status: Stopped
GuiControl, Main: +cRed, StatusText
GuiControl, Main:, SubStatus, [Idle]
Gui, Tracker: Hide
return

MainGuiClose:
ExitApp

; --- Mouse Button Remaps ---
XButton1::f  ; Browser Back -> f
XButton2::e  ; Browser Forward -> e

