#SingleInstance, force
SetWinDelay, -1
return

class PS
{

	; Set settings here
	static __settings := {caption:false
	                    , trans:-20
	                    , alwaysontop:false}
	
	; Set Hotkeys here
	static __Hotkeys := {quake:"#``"
	                   , caption:""
	                   , trans_min:""
	                   , trans_add:""
	                   , exit:"Esc"}
	
	static _ := PS.__INIT__()

	__INIT__() {
		static init , _ := ObjRemove(PS, "_")

		ObjInsert(this, "__", [])
		Menu, Tray, Icon, powershell.exe, 1
		
		if !init
			this.base := PS.__BASE__ , init := true

		if !this.__hwnd {
			Run, % A_ProgramsCommon "\Accessories\Windows PowerShell\Windows PowerShell.lnk",,, PID
			WinWait, % "ahk_pid " PID
		}
		; Attach script to PowerShell console
		DllCall("AttachConsole", "Int", this.__pid)

		for a, b in this.__settings
			this[a] := b

		for k, v in this.__Hotkeys {
			if (v == "")
				continue
			if (k <> "quake")
				HotKey, IfWinActive, % "ahk_id " this.__hwnd
			Hotkey, % v, PS_Hotkey
			Hotkey, IfWinActive
		}

	}

	__showASync(nCmdShow:=5) { ; SW_SHOW:=5 , SW_HIDE:=0
		DllCall("ShowWindowAsync", "Ptr", PS.__hwnd, "Int", nCmdShow)
	}

	__activate() {
		WinActivate, % "ahk_id " this.__hwnd
	}

	__min() {
		WinMinimize, % "ahk_id " this.__hwnd
	}

	__move(p*) {
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinMove, % "ahk_id " this.__hwnd,, % p.1, % p.2, % p.3, % p.4
		DetectHiddenWindows, % dhw
	}

	__quake() {
		static d := 64
		
		if (WinExist("A") == this.__hwnd) {
			WinGet, list, List,,, Program Manager
			Loop, % list
				n := (list%A_Index% = this.__hwnd ? A_Index+1 : false)
			until n
			a := list%n%
		} else {
			if this.isHidden
				WinShow, % "ahk_id " this.__hwnd
			this.__activate() , na := true
		}

		if this.isVisible {
			if na
				return
			s := (0-this.pos.H)
			while ((y:=this.pos.Y) > s)
				this.__move("", y-d)
			
			WinHide, % "ahk_id " this.__hwnd
			WinActivate, % "ahk_id " a
		
		} else while ((y:=this.pos.Y) < 0) {
			this.__move("", y+d)
		}
		
		return

		PS_WaitNotActive:
		WinWaitNotActive, % "ahk_id " PS.__hwnd
		if !PS.isVisible
			PS.__quake()
		return

	}

	__write(text) {
		FileAppend, % text, CONOUT$
		ControlSend,, {Enter}, % "ahk_id " this.__hwnd
	}

	class __BASE__
	{

		__Set(k, v, p*) {
			dhw := A_DetectHiddenWindows
			DetectHiddenWindows, On

			if (k = "caption")
				WinSet, Style
				      , % {0:"-", 1:"+", 2:"^"}[v] . 0xC00000
				      , % "ahk_id " this.__hwnd

			if (k = "trans")
				WinSet, Transparent, % PS.trans+v, % "ahk_id " this.__hwnd

			if (k = "alwaysontop")
				WinSet, AlwaysOnTop
				      , % {0:"Off", 1:"On", 2:"Toggle"}[v]
				      , % "ahk_id " this.__hwnd

			if (k = "toolwindow")
				WinSet, ExStyle
				      , % {0:"-", 1:"+", 2:"^"}[v] . 0x80
				      , % "ahk_id " this.__hwnd

			DetectHiddenWindows, % dhw
			return this.__[k] := v
		}

		__Get(key, p*) {
			dhw := A_DetectHiddenWindows
			DetectHiddenWindows, On

			if (key = "__hwnd") {
				;val := WinExist("ahk_class ConsoleWindowClass")
				val := WinExist("ahk_exe powershell.exe")
			}

			if (key = "wClass") {
				val := "ConsoleWindowClass"
			}

			if (key = "__pid") {
				WinGet, val, PID, % "ahk_id " this.__hwnd
			}
			
			if (key = "pos") {
				WinGetPos, x, y, w, h, % "ahk_id " this.__hwnd		
				val := {X:x, Y:y, W:w, H:h}
			}

			if (key = "trans") {
				WinGet, val, Transparent, % "ahk_id " this.__hwnd
				if (val = "")
					val := 255
			}

			if (key = "isVisible") {
				;val := (this.pos.Y < 0)
				val := (this.pos.Y >= 0)
			}

			if (key = "isHidden") {
				DetectHiddenWindows, Off
				val := !WinExist("ahk_id " this.__hwnd)
			}

			DetectHiddenWindows, % dhw
			return val
		}
	}

	__HOTKEYS__() {
		return

		PS_Hotkey:
		if (A_ThisHotkey = PS.__Hotkeys.quake)
			PS.__quake()
		if (A_ThisHotkey = PS.__Hotkeys.caption)
			PS.caption := 2
		if (A_ThisHotkey = PS.__Hotkeys.trans_min)
			PS.trans := -10
		if (A_ThisHotkey = PS.__Hotkeys.trans_add)
			PS.trans := 10
		if (A_ThisHotkey = PS.__Hotkeys.exit)
			PS.__EXIT__()
		return
	}

	__EXIT__(p*) {
		; reset to normal
		for k, v in {caption:1, trans:Abs(PS.__settings.trans), alwaysontop:0}
			this[k] := v
		
		this.__write("PS-Control terminated.")
		; Detach PowerShell console.
		DllCall("FreeConsole")
		SetTimer, PS_Exit, -1
		return
		
		PS_Exit:
		ExitApp
	}
}