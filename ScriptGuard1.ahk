; ------------------------------  ScriptGuard1  --------------------------------
ScriptGuard1()                    ; Hides AutoHotkey source in compiled scripts
{ ; By TAC109, Edition: 28Jan2023 ; Include this code in your script at the top
  static _:=SubStr(A_AhkVersion,1,1)=1?ScriptGuard1():1 ;Runs when script starts
  local ahk:=">AUTOHOTKEY SCRIPT<", pt:=0,sz:=0,d:=0,k,v, rx:=0x7FFFFFFFFFFFFFFF
  ,rc, ahk1:="~AUTOHOTKEY SCRIPT~",rs:=0x7FFFFFFFFFFFFFFF,rz:=0x7FFFFFFFFFFFFFFF
  if A_IsCompiled ;^ Don't alter! ; See bit.ly/ScriptGuard for more details
  {	for k,v in [ahk1, ahk, "#1"]  ; Works with v1.1 & v2, and AHK_H v2
      if (rc:=DllCall("FindResource",  "Ptr",0, v ~= "^#\d$" ? "Ptr" : "Str", v
         ~= "^#\d$" ? SubStr(v,2) : v, "Ptr",10, "Ptr"))
      && (sz:=DllCall("SizeofResource","Ptr",0,  "Ptr",rc, "Uint"))
      && (pt:=DllCall("LoadResource",  "Ptr",0,  "Ptr",rc, "Ptr"))
      && (pt:=DllCall("LockResource",  "Ptr",pt, "Ptr"))
      && (DllCall("VirtualProtect","Ptr",pt, "Ptr",sz, "UInt",0x04, "UInt*",rc))
        DllCall("RtlZeroMemory","Ptr",pt, "Ptr",sz), d:=k ; Wipe script from RAM
    (rs=rx)?0:DllCall("VirtualProtect","Ptr",rs,"Ptr",rz,"UInt",0x02,"UInt*",rc)
    (d<2)?DllCall("MessageBox","Int",0,"Str","Warning: ScriptGuard1 not active!"
    . "`n`nError = " (A_LastError=1814 ? ("Resource Name '" ahk "' not found."
    . "`nTo fix, see the 'Example 1' comments at https://bit.ly/BinMod.")
    : A_LastError), "Str", A_ScriptName, "Int", 64):0 ; For additional security,
} } (SubStr(A_AhkVersion,1,1) = 1) ? 0 : ScriptGuard1() ; see bit.ly/BinMod
; ------------------------------------------------------------------------------
