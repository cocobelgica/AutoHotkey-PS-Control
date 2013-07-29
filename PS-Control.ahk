#SingleInstance force
SetBatchLines, -1
SetWinDelay, -1
return

class PS
{

	static __ := [] ; proxy object
	static void := PS.__MAIN__()

	__MAIN__() {
		static init , _ := ObjRemove(PS, "void")
		;Load configuration [UI Style, Hotkeys, Menus]
		this.__config := this.__LOADCONFIG__()
		
		if !init
			this.base := PS.__BASE__ , init := true

		if !this.__hwnd {
			Run, % this.shortcut,,, PID
			WinWait, % "ahk_pid " PID
		}
		; Attach script to PowerShell console
		DllCall("AttachConsole", "Int", this.__pid)

		for a, b in this.__config.UI
			this[a] := b

		for k, v in this.__config.HOTKEYS {
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
		swpFlags := 0x0010|0x0004 ; SWP_NOACTIVATE|SWP_NOZORDER
		if (p.1 = "") && (p.2 = "") {
			p.1 := 0 , p.2 := 0
			swpFlags |= 0x0002 ; SWP_NOMOVE
		} else if (p.3 = "") && (p.4 = "") {
			p.3 := 0 , p.4 := 0
			swpFlags |= 0x0001 ; SWP_NOSIZE
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
		      , "UInt", swpFlags)
		
		
		DllCall("QueryPerformanceCounter", "Int64*", i) , j := i
		while (j < i+3000)
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
				WinSet, Transparent, % v, % "ahk_id " this.__hwnd

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
				    : (this.__hwnd:=WinExist("ahk_class ConsoleWindowClass"))
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

			} else if (key = "alwaysontop") {
				WinGet, ExStyle, ExStyle, % "ahk_id " this.__hwnd
				val := (ExStyle & 0x8) ? true : false ; WS_EX_TOPMOST:=0x8

			} else if (key = "shortcut") {
				; Fix this part
				val := A_ProgramsCommon . "\
				(LTrim Join\
				Accessories
				Windows PowerShell
				Windows PowerShell.lnk
				)"
				. "`n" A_ProgramsCommon . "\
				(LTrim Join\
				Accessories
				Command Prompt.lnk
				)"
				. "`n" A_Programs . "\
				(LTrim Join\
				Accessories
				Command Prompt.lnk
				)"
				os := {7:1, 8:1, VISTA:2, XP:3}[SubStr(A_OSVersion, 5)]
				if !RegExMatch(val, "(?:(?:\R|)\K[^\r\n]+){" os "}", val)
					val := "cmd.exe"
			
			} else if (key = "wClass") {
				val := "ConsoleWindowClass"
			}

			DetectHiddenWindows, % dhw
			return val
		}
	}

	__LOADCONFIG__() {
		x := ComObjCreate("MSXML2.DOMDocument" . (A_OSVersion~="(VISTA|7|8)" ? ".6.0" : ""))
		x.setProperty("SelectionLanguage", "XPath") , x.async := false
		_ := {UI:[], HOTKEYS:[]}
		
		cfg := "
		(LTrim Join
		<PS>
		<UI>
		<caption>0</caption>
		<trans>235</trans>
		<alwaysontop>0</alwaysontop>
		</UI>
		<HOTKEYS>
		<quake>#``</quake>
		<exit>Esc</exit>
		</HOTKEYS>
		<MENUS>
		<Menu name=""Tray"" icon=""powershell.exe,1,1"" default=""Exit PS-Control"" standard=""0"">
		<Item name=""Show Titlebar"" action=""PS_MenuLabel""/>
		<Item name=""Transparency"" action="":Trans""/>
		<Item name=""Always On Top"" action=""PS_MenuLabel""/>
		<Item/>
		<Item name=""Exit PS-Control"" action=""PS_MenuLabel""/>
		</Menu>
		<Menu name=""Trans"">
		<Item name=""Default"" action=""PS_MenuLabel"" check=""1""/>
		<Item/>
		<Item name=""None"" action=""PS_MenuLabel""/>
		<Item name=""90"" action=""PS_MenuLabel""/>
		<Item name=""80"" action=""PS_MenuLabel""/>
		<Item name=""70"" action=""PS_MenuLabel""/>
		<Item name=""60"" action=""PS_MenuLabel""/>
		<Item name=""50"" action=""PS_MenuLabel""/>
		</Menu>
		</MENUS>
		</PS>
		)"
		x.loadXML(cfg)
		
		for k, v in _
			Loop, % (_cfg_:=x.selectNodes("//" k "/*")).length
				c := _cfg_.item(A_Index-1)
				, v[c.nodeName] := c.text
		
		MENU_load(x.selectSingleNode("//MENUS").xml)
		
		return _
	}

	__EVENTHANDLER__() {
		return

		PS_Hotkey:
		if (A_ThisHotkey = PS.__config.HOTKEYS.quake)
			PS.__quake()
		else if (A_ThisHotkey = PS.__config.HOTKEYS.exit)
			PS.__EXIT__()
		return

		PS_MenuLabel:
		if (A_ThisMenu = "Tray") {
			if (A_ThisMenuItem = "Exit PS-Control")
				PS.__EXIT__()
			
			else if (A_ThisMenuItem ~= "^(Show|Hide) Titlebar$") {
				PS.caption := {show:1, hide:0}[cmd:=SubStr(A_ThisMenuItem, 1, 4)]
				Menu, % A_ThisMenu
				    , Rename
				    , % A_ThisMenuItem
				    , % {show:"Hide Titlebar", hide:"Show Titlebar"}[cmd]
			
			} else if (A_ThisMenuItem = "Always On Top") {
				PS.alwaysontop := PS.alwaysontop ? 0 : 1
				Menu, % A_ThisMenu
				    , % {0:"Uncheck", 1:"Check"}[PS.alwaysontop]
				    , % A_ThisMenuItem
			
			} 
		
		} else if (A_ThisMenu = "Trans") {
			val := (A_ThisMenuItem ~= "^\d+$"
			    ? 255*(A_ThisMenuItem/100)
			    : {None:255, Default:235}[A_ThisMenuItem])

			PS.trans := val
			
			prev := Round((PS.trans/255)*100) , def := Round((235/255)*100)
			if (prev~="^(100|" def ")$")
				prev := {100:"None", (def):"Default"}[prev]
			
			Menu, % A_ThisMenu, Uncheck, % prev
			Menu, % A_ThisMenu, Check, % A_ThisMenuItem
			 
		}
		return
	}

	__EXIT__(p*) {
		; Show if hidden
		if (this.isHidden || !this.isVisible)
			this.__quake()
		
		; Reset to normal
		for k, v in {caption:1, trans:255, alwaysontop:0}
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

MENU_load(src) {
	/*
	Do not initialize 'xpr' as class static initializer(s) will not be
	able to access the variable's content when calling this function.
	*/
	static xpr
	
	;XPath[1.0] expression(s) that allow case-insensitive node selection
	if !xpr
		xpr := ["*[translate(name(), 'MENU', 'menu')='menu']"
		    ,   "*[translate(name(), 'ITEM', 'item')='item' or "
		    .   "translate(name(), 'STANDARD', 'standard')='standard']"
		    ,   "@*[translate(name(), 'NAME', 'name')='name']"
		    ,   "@*[translate(name(), 'ACTION', 'action')='action']"
		    ,   "@*[translate(name(), 'RELOAD', 'reload')='reload']"]
	
	x := ComObjCreate("MSXML2.DOMDocument" . (A_OSVersion~="(VISTA|7|8)" ? ".6.0" : ""))
	x.setProperty("SelectionLanguage", "XPath") ;for OS'es below Win_7
	x.async := false

	;Load XML source
	if (src ~= "s)^<.*>$")
		x.loadXML(src)
	else if ((f:=FileExist(src)) && !(f ~= "D"))
		x.load(src)
	else throw Exception("Invalid XML source.", -1)

	m := [] , mn := []
	_m_ := x.selectNodes("//" xpr.1 "[" xpr.3 "]")
	
	Loop, % _m_.length {
		mn := {node: _m_.item(A_Index-1)}
		Loop, % (_mp_:=mn.node.attributes).length
			mp := _mp_.item(A_Index-1)
			, mn[mp.name] := mp.value
		m[A_Index] := mn

		/*
		Reload: Specify a 'reload' attribute for the menu element node and
		set its value to '1'. Function assumes that the menu exists - deletes
		all menu items and recreates the menu based on new xml description.
		*/
		if mn.node.selectSingleNode(xpr.5).nodeValue
			try Menu, % mn.name, DeleteAll

		if (mn.name = "Tray") {
			if (mn.node.selectSingleNode(std:=RegExReplace(xpr.2, "^.*or\s", "*["))
			|| mn.node.selectSingleNode("@" . std))
				Menu, Tray, NoStandard
			continue
		}
		/*
		Initialize empty menu or if menu is being reloaded remove
		all the standard AHK menu items(if any).
		*/
		else Loop, 2
			Menu, % mn.name, % ["Standard", "NoStandard"][A_Index]
	}

	for k, v in m {

		;Set menu properties
		for a, b in v {
			if (a ~= "i)^(n(ame|ode)|reload)$")
				continue

			if (a = "default") {
				if (def:=v.node.selectSingleNode("*[" xpr.3 "='" b "']"))
					def.setAttribute("default", 1)
			
			} else if (a = "color") {
				RegExMatch(b, "iO)^([^,\s]+)(?:[,\s]+(single|)|$)$", c)
				Menu, % v.name, Color, % c.1, % c.2
			
			} else if (a = "standard") {
				if !b
					continue
				e := x.createElement("Standard")
				, m := (b>0 ? "insertBefore" : "appendChild")
				, p := (b>0 ? [e, v.node.selectSingleNode("*[" b "]")] : [e])
				, (v.node)[m](p*)

			} else if (a ~= "i)^(icon|tip|click|mainwindow)$") {
				if (v.name <> "Tray")
					continue

				if (a = "icon") {
					RegExMatch(b, "iO)^([^,]+|)(?:,(\d+|)(?:,(0|1|)|$)|$)$", icon)
					if (icon.1 ~= "^(0|1|)$")
						Menu, Tray, % icon.1 ? "Icon" : "NoIcon"
					else Menu, Tray, Icon, % icon.1, % icon.2, % icon.3
				
				} else if (a = "mainwindow") {
					if !A_IsCompiled
						continue
					Menu, Tray, % b ? "MainWindow" : "NoMainWindow"
				
				} else Menu, Tray, % a, % b
			}
		}

		_mi_ := v.node.selectNodes(xpr.2)

		;Add menu item(s)
		Loop, % _mi_.length {
			mi := _mi_.item(A_Index-1)
			
			;If element node name is 'Standard', add standard AHK menu items
			if (mi.nodeName = "standard") {
				Menu, % v.name, Standard
				continue
			}

			_p_ := mi.attributes , len := _p_.length
			
			item := {name:(len ? mi.selectSingleNode(xpr.3).nodeValue : "")
			     , action:(len ? mi.selectSingleNode(xpr.4).nodeValue : "")}
			Menu, % v.name, Add, % item.name, % item.action
			
			;Set menu item properties
			Loop, % len {
				p := _p_.item(A_Index-1)

				if !(p.name ~= "i)^(icon|check|enable|default)$")
					continue
				
				if (p.name = "icon") {
					RegExMatch(p.value, "iO)^([^,]+)(?:,(\d+|)(?:,(\d+|)|$)|$)$", icon)
					Menu, % v.name, Icon, % item.name, % icon.1, % icon.2, % icon.3
				
				} else if (p.name ~= "i)^(check|enable)$") {
					cmd := {check:{1:"Check", 0:"Uncheck", 2:"ToggleCheck"}
				         , enable:{1:"Enable", 0:"Disable", 2:"ToggleEnable"}}[p.name, p.value]
			        Menu, % v.name, % cmd, % item.name

				} else if (p.name = "default")
					Menu, % v.name, Default, % (p.value ? item.name : "")
			}
		}
		
	}
}