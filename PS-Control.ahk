#SingleInstance force
SetBatchLines, -1
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
	
	static __ := [] ; proxy object
	static void := PS.__MAIN__()

	__MAIN__() {
		static init , _ := ObjRemove(PS, "void")

		Menu, Tray, Icon, powershell.exe, 1
		
		if !init
			this.base := PS.__BASE__ , init := true

		if !this.__hwnd {
			Run, % this.shortcut,,, PID
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

	__move__(p*) {
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		WinMove, % "ahk_id " this.__hwnd,, % p.1, % p.2, % p.3, % p.4
		DetectHiddenWindows, % dhw
	}

	__move(p*) {
		flags := 0x0010|0x0004 ; SWP_NOACTIVATE|SWP_NOZORDER
		if (p.1 = "") && (p.2 = "") {
			p.1 := 0 , p.2 := 0
			flags |= 0x0002 ; SWP_NOMOVE
		} else if (p.3 = "") && (p.4 = "") {
			p.3 := 0 , p.4 := 0
			flags |= 0x0001 ; SWP_NOSIZE
		}

		for k, v in ["x","y","w","h"]
			%v% := p[k]<>"" ? p[k] : (this.pos)[v]

		DllCall("SetWindowPos"
		      , "Ptr", this.__hwnd
		      , "Ptr", 0
		      , "UInt", x ; x
		      , "UInt", y ; y
		      , "UInt", w ; w
		      , "UInt", h ; h
		      , "UInt", flags)
		
		
		DllCall("QueryPerformanceCounter", "Int64*", i) , j := i
		while (j < i+2500)
			DllCall("QueryPerformanceCounter", "Int64*", j)
		
		;Sleep, % A_WinDelay
	}

	__quake() {
		static d := 16 , u := 8
		
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
			while ((y:=this.pos.Y) > s) {
				this.__move("", (z:=y-u)<s ? s : z)
			}
			
			WinHide, % "ahk_id " this.__hwnd
			WinActivate, % "ahk_id " a
		
		} else while ((y:=this.pos.Y) < 0) {
			this.__move("", (z:=y+d)>0 ? 0 : z)
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

			else if (k = "trans")
				WinSet, Transparent, % PS.trans+v, % "ahk_id " this.__hwnd

			else if (k = "alwaysontop")
				WinSet, AlwaysOnTop
				      , % {0:"Off", 1:"On", 2:"Toggle"}[v]
				      , % "ahk_id " this.__hwnd

			else if (k = "toolwindow")
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
				val := this.__.HasKey("__hwnd")
				    ? this.__.__hwnd
				    : (this.__hwnd:=WinExist("ahk_exe powershell.exe"))
				/*
				if !WinExist("ahk_id " val) ;!DllCall("IsWindow", "Ptr", val)
					throw Exception("ERROR: PowerShell handle does not exist", -1)
				*/
			} else if (key = "pos") {
				WinGetPos, x, y, w, h, % "ahk_id " this.__hwnd		
				val := {X:x, Y:y, W:w, H:h}
			
			} else if (key = "trans") {
				WinGet, val, Transparent, % "ahk_id " this.__hwnd
				if (val = "")
					val := 255
			
			} else if (key = "isVisible") {
				val := (this.pos.Y >= 0)
			
			} else if (key = "isHidden") {
				val := !DllCall("IsWindowVisible", "Ptr", this.__hwnd)
			
			} else if (key = "__pid") {
				WinGet, val, PID, % "ahk_id " this.__hwnd

			} else if (key = "shortcut") {
				val := A_ProgramsCommon . "\
				(LTrim Join\
				Accessories
				Windows PowerShell
				Windows PowerShell.lnk
				)"
			
			} else if (key = "wClass") {
				val := "ConsoleWindowClass"
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
		else if (A_ThisHotkey = PS.__Hotkeys.caption)
			PS.caption := 2
		else if (A_ThisHotkey = PS.__Hotkeys.trans_min)
			PS.trans := -10
		else if (A_ThisHotkey = PS.__Hotkeys.trans_add)
			PS.trans := 10
		else if (A_ThisHotkey = PS.__Hotkeys.exit)
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