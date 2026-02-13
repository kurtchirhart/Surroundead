#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; --- Configuration ---
; Updated based on your Window Spy screenshot
TargetWindow := "ahk_exe Surroundead-Win64-Shipping.exe"
Menu, Tray, Icon, shell32.dll, 42 

; --- GUI Setup ---
Gui, +AlwaysOnTop
Gui, Font, s10, Segoe UI
Gui, Add, Text,, Cast Wait (ms):
Gui, Add, Edit, vCastWait, 9000
Gui, Add, Text,, Reel Delay (ms):
Gui, Add, Edit, vReelDelay, 500
Gui, Add, Text, vStatusText w200 cRed, Status: Stopped
Gui, Add, Text, vSubStatus w200 cGray, [Idle]

Gui, Add, Button, gStart Default w80, Start (F1)
Gui, Add, Button, gStop x+10 w80, Stop (F2)

Gui, Show,, Surroundead Fisher
return

; --- Controls ---

F1::
Start:
Gui, Submit, NoHide
Running := true
GuiControl,, StatusText, Status: FISHING...
GuiControl, +cGreen, StatusText
Loop
{
    if !Running
        break
    
    if WinActive(TargetWindow)
    {
        ; CASTING
        GuiControl,, SubStatus, Casting line...
        ; Using 'Down' and 'Up' to ensure the game registers the input
        ControlClick,, %TargetWindow%,,,, R D
        Sleep, 100
        ControlClick,, %TargetWindow%,,,, R U
        
        Sleep, 1500 
        
        ; WAITING
        GuiControl,, SubStatus, Waiting %CastWait%ms for bite...
        Sleep, %CastWait%
        
        ; REELING
        GuiControl,, SubStatus, Reeling in...
        ControlClick,, %TargetWindow%,,,, R D
        Sleep, 100
        ControlClick,, %TargetWindow%,,,, R U
        
        Sleep, %ReelDelay%
    }
    else
    {
        GuiControl,, SubStatus, Paused (Game not focused)
        Sleep, 1000 
    }
}
return

F2::
Stop:
Running := false
GuiControl,, StatusText, Status: Stopped
GuiControl, +cRed, StatusText
GuiControl,, SubStatus, [Idle]
return

GuiClose:
ExitApp