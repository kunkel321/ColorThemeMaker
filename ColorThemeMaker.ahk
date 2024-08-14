#SingleInstance
#Requires AutoHotkey v2+

/*
Color Theme Maker
Kunkel321: 8-14-2024
https://github.com/kunkel321/ColorThemeMaker
https://www.autohotkey.com/boards/viewtopic.php?f=83&t=132310

WhiteColorBlackGradient function is based on ColorGradient() by Lateralus138 and Teadrinker.  
I Used Claude.ai for debugging several parts and doing the "split complemplementary" math. 
Some aspects are also from https://colordesigner.io/color-wheel

The colorArray has 120 elements, equidistantly circling the color wheel.  I've attempted to create two color wheel options:
* RGB uses "additive/light-based" color gradients.
* CYM is uses "subtractive/pigment-based" color gradients.
Both arrays start at red, then loop around, back to red.

Using terminology from the above colordesigner site...

Given a reference color, its "Complementary" color will be directly across from it, on the opposite side of the color wheel.  If, instead of choosing the Complementary color, you choose the two colors that are on equal-and-opposite sides of the Complementary color, then the three points will comprise a "Split Complementary" color set.  The below tool uses the color selected in the combobox as the reference color and determines which color in the colorArray is its Complementary color.  The first up/down box in the gui (“Split Size”) defines the number of steps from the Complementary position, that the other two colors should be.  

The three color variables are used:
* "formColor" is the GUI background color.  I.e. myGui.BackColor := formColor
* "listColor" is the background color of the listView, and other applicable controls.  I.e. "BackgroundColor" as appears in the gui control options. 
* "fontColor" is the color of the text on the gui and in applicable controls.  I.e myGui.SetFont("c" fontColor)

The colors are assigned by default as:  
* fontColor = The reference color that appears in the comboBox.
* formColor = The color that appears in the posing Counter-Clockwise from the Complementary position. 
* listColor = The color that appears in the posing Clockwise from the Complementary position. 
This means that the color which is chosen in the top comboBox corresponds to the font color of the form.  The gui element (font/list/form) which is used for the reference color (and which corresponds to the top comboBox) can be changed with the second comboBox "... Is Reference."   

So… If the Split Size is 10 or 15 or so, then the pattern will be “Split Complementary.”  If the Split Size is set to 0, then the listColor and the fontColor will be at the same position and will be "Complementary" to the formColor.   If the Split Size is the max of 60, then all three colors will be at the same location and the theme will be "Monochromatic."  If the Split Size value is around 45 to 50, then the pattern will be “Analogous” (again, see colordesigner site).  And if the Split Size is 20, then the pattern will be a “Triad.”   As indicated above, the primary color is set in the top comboBox, and the other two are the split colors.  The split colors can swapped by setting a negative number as the Split Size.

With a gui, the font needs to “stand out” from the background color of the gui and the controls, so the  colors chosen will often need to be adjusted in terms of lightness/darkness.  Typically the font will be on one end of the light/dark continuum, and the background colors will be at the other end.  The Light/Dark radios swap this.  The bottom three up/down boxes are for fine-tuning the light/darkness. 

Similar to changing the shading, users may wish to "tone-down" one or more of the colors by reducing the saturation.  This is simulated by fading the color to gray.  The saturation up/down controls are next to the shading ones. Double-clicking the "Saturation" text label will reset the saturation levels to max. 

Note also:  The 'Export Sample File' button will make a sample gui in an ahk file and attempt to run it.  Depending on your setup, it might open for editing, or might not open at all.  It will get saved in the same folder as this file. 
*/

myHotKey := "!+g"  ; Alt+Shift+G shows/hides tool.
^Esc::ExitApp ; Ctrl+Esc Terminates entire script.
guiTitle := "Color Theme Maker" ; OK to change title (here only).

TraySetIcon("shell32.dll",131) 
formColor := "Default"
listColor := "Default"
fontColor := "Default"
reference := ""
CounterClock := ""
ClockWise := ""
shadingSteps := 30
saturationSteps := 30
splitSteps := 10  
setColorArrays() ; The arrays are large, so I put them at the bottom.  
colorArray := additiveRGB

; --- Build gui ---
global myGui := Gui(, guiTitle)
myGui.SetFont("s12 c" fontColor)
myGui.BackColor := formColor
pattern := myGui.Add("Text", "x14 W215 Center","Split Complementary`n" guiTitle)
pattern.SetFont("bold")

myRadRGB := myGui.Add("Radio", "x50  Checked1", "RGB")
myRadRGB.OnEvent("Click", colorChanged)
myRadCYM := myGui.Add("Radio", "x+30", "CYM")
myRadCYM.OnEvent("Click", colorChanged)

myGui.Add("Text","x14 ","Reference:")
global color1 := myGui.Add("ComboBox", "x+5 w110 Background" listColor, colorArray) 
color1.OnEvent("Change", colorChanged)

global myReference := myGui.Add("ComboBox", "x14 w90 choose1 Background" listColor, ['fontColor','listColor','formColor'])
myReference.OnEvent("Change", colorChanged)
myGui.Add("Text","x+5 ","uses reference")


myGui.Add("Text", "x14", "Split steps for other 2: ")
sEdit := myGui.Add("Edit", "w50 x+5")
sSteps := myGui.Add("UpDown", " Range-60-60", splitSteps) 
sSteps.OnEvent("change", colorChanged)
sSteps.Enabled := False
sEdit.Enabled := False
myListArr := ["fontColor:`t" fontColor, "listColor:`t" listColor, "formColor:`t" formColor,]
myList := myGui.Add("ListBox", "x14 w215 r3 Background" listColor, myListArr)

myRadLight := myGui.Add("Radio", "x50 Checked1", "Light")
myRadLight.OnEvent("Click", shadeChanged)
myRadDark := myGui.Add("Radio", "x+30", "Dark")
myRadDark.OnEvent("Click", shadeChanged)
myRadLight.Enabled := False
myRadDark.Enabled := False

myGui.SetFont("s10")
myGui.Add("Text","x14","Shading ")
myGui.Add("Text","x+4","Saturation").OnEvent("DoubleClick", resaturate)
myGui.SetFont("s12")

FontShadeEdit := myGui.Add("Edit", "y+5 w50 x14") ; FontColor Shading.
FontShadeSteps := myGui.Add("UpDown", "Range1-" shadingSteps, "24") ; last parameter is the default setting. Change as desired.
FontShadeSteps.OnEvent("change", colorChanged)
FontShadeSteps.Enabled := False
FontShadeEdit.Enabled := False

FontSaturationEdit := myGui.Add("Edit", "w50 x+5") ; FontColor Saturation.
FontSaturationSteps := myGui.Add("UpDown", "Range1-" saturationSteps, saturationSteps) ; last parameter is the default setting. Change as desired.
myGui.Add("Text", "x+5", "Font")
FontSaturationSteps.OnEvent("change", colorChanged)
FontSaturationSteps.Enabled := False
FontSaturationEdit.Enabled := False
;-----------------------

ListShadeEdit := myGui.Add("Edit", "w50 x14") ; ListColor (Ctrl Background) Shading.
ListShadeSteps := myGui.Add("UpDown", "Range1-" shadingSteps, "4") 
ListShadeSteps.OnEvent("change", colorChanged)
ListShadeSteps.Enabled := False
ListShadeEdit.Enabled := False

ListSaturationEdit := myGui.Add("Edit", "w50 x+5") ; ListColor (Ctrl Background) Saturation.
ListSaturationSteps := myGui.Add("UpDown", "Range1-" saturationSteps, saturationSteps) 
myGui.Add("Text", "x+5", "List (Ctrl Bkg)")
ListSaturationSteps.OnEvent("change", colorChanged)
ListSaturationSteps.Enabled := False
ListSaturationEdit.Enabled := False
;-----------------------

FormShadeEdit := myGui.Add("Edit", " w50 x14") ; Form (Gui BackColor) Shading. 
FormShadeSteps := myGui.Add("UpDown", "Range1-" shadingSteps, "9")
FormShadeSteps.OnEvent("change", colorChanged)
FormShadeSteps.Enabled := False
FormShadeEdit.Enabled := False

FormSaturationEdit := myGui.Add("Edit", " w50 x+5") ; Form (Gui BackColor) Saturation. 
FormSaturationSteps := myGui.Add("UpDown", "Range1-" saturationSteps, saturationSteps)
myGui.Add("Text", "x+5", "Form (Gui Bck)")
FormSaturationSteps.OnEvent("change", colorChanged)
FormSaturationSteps.Enabled := False
FormSaturationEdit.Enabled := False
;-----------------------

; the buttons
myGui.SetFont("s11")
expButton := myGui.Add("Button" , "w100 x14", "Export Vars`nto ClipBoard")
expButton.OnEvent("Click", exportClip)
expButton.Enabled := False
samButton := myGui.Add("Button" , "w100 x+5", "Export`nSample File")
samButton.OnEvent("Click", exportFile)
samButton.Enabled := False

relButton := myGui.Add("Button" , "w100 x14", "Reload Script")
relButton.OnEvent("Click", buttRestart)
relButton.Enabled := False
canButton := myGui.Add("Button" , "w100 x+5", "Cancel")
canButton.OnEvent("Click", buttCancel)
canButton.Enabled := False

; Main hotkey shows/hides gui.
Hotkey(myHotKey, showHideTool) 
showHideTool(*) { 
    If WinActive(guiTitle)
        myGui.Hide()
    Else 
        myGui.Show("x" A_ScreenWidth /5*3) 
}

; 'Reload Script button pressed'
buttRestart(*) {
    Result := MsgBox("Current colors will be lost if you restart.",, "icon! okCancel")
    If Result = "OK"
        Reload()
    Else If Result = "Cancel"
        Return
}

; 'Cancel' button pressed.
buttCancel(*) {
    myGui.Hide()
}


; If user changes light/dark radio, set 3 shade spinners.
shadeChanged(*) { 
    If (myRadLight.Value = 1) {
        FormShadeSteps.Value := 6
        ListShadeSteps.Value := 8
        FontShadeSteps.Value := 24
        colorChanged()
    }
    Else {
        FormShadeSteps.Value := 25
        ListShadeSteps.Value := 23
        FontShadeSteps.Value := 7
        colorChanged()
    }
}

; Sets the three saturation spin boxes to max. 
resaturate(*) {
    FormSaturationSteps.Value := saturationSteps
    ListSaturationSteps.Value := saturationSteps
    FontSaturationSteps.Value := saturationSteps
    colorChanged()
}

; This is the main function that updates the colors in the gui and does several calculations. 
colorChanged(*) {    
    splitSteps := sSteps.Value

    If myRadRGB.Value = 1 {
        colorArray := subtractiveCMY
        refIndex := color1.Value
        color1.Delete() ; Clear all existing items
        color1.Add(colorArray) ; Add new items
        color1.Value := refIndex
    }
    else {
        colorArray := additiveRGB   
        refIndex := color1.Value
        color1.Delete() ; Clear all existing items
        color1.Add(colorArray) ; Add new items
        color1.Value := refIndex
    }

    refIndex := color1.Value
    reference := color1.Text

    ; Add error handling for empty combobox
    if (reference = "") {
        return  ; Exit the function early if the combobox is empty
    }
    Else {
        for ctrl in myGui
            ctrl.Enabled := True
    }

    complementaryIndex := Mod(refIndex + 59, 120) + 1 ; These three lines written by Claude.ai.
    splitCompCounterClockwiseIdx := Mod(complementaryIndex + 120 - splitSteps - 1, 120) + 1
    splitCompClockwiseIdx := Mod(complementaryIndex + splitSteps - 1, 120) + 1
    
    CounterClock := colorArray[splitCompCounterClockwiseIdx]
    ClockWise := colorArray[splitCompClockwiseIdx]

    Switch splitSteps { ; Update Title.
        Case 0:pattern.text := "Complementary`n" guiTitle
        Case 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
            pattern.text := "Split Complementary`n" guiTitle
        Case -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15:
            pattern.text := "Split Complementary`n" guiTitle
        Case 20, -20: pattern.text := "Triad`n" guiTitle
        Case 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59: 
            pattern.text := "Analogous`n" guiTitle
        Case -45, -46, -47, -48, -49, -50, -51, -52, -53, -54, -55, -56, -57, -58, -59: 
            pattern.text := "Analogous`n" guiTitle
        Case 60, -60: pattern.text := "Monochromatic`n" guiTitle
        Default: pattern.text := guiTitle
    }
    
    ; This part is for the "font/from/list Is Reference" color part.
    global fontColor, listColor, formColor
    If (myReference.text = "fontColor") {
        fontColor := reference
        listColor := CounterClock
        formColor := ClockWise
    }
    Else if  (myReference.text = "formColor") {
        formColor := reference
        fontColor := CounterClock
        listColor := ClockWise
    }
    Else { ; myRef is listColor
        listColor := reference
        formColor := CounterClock
        fontColor := ClockWise
    }

    ; Apply shading, then saturation to formColor as needed. 
    formArr := WhiteColorBlackGradient(formColor, shadingSteps)
    formColor := formArr[FormShadeSteps.Value]
    formArr := ColorToGrayGradient(formColor, saturationSteps)
    formColor := formArr[-FormSaturationSteps.Value]
    myGui.BackColor := formColor

    ; Apply shading, saturation to listColor and fontColor, as needed.
    listArr := WhiteColorBlackGradient(listColor, shadingSteps)
    listColor := listArr[ListShadeSteps.Value]
    listArr := ColorToGrayGradient(listColor, saturationSteps)
    listColor := listArr[-ListSaturationSteps.Value]
    
    fontArr := WhiteColorBlackGradient(fontColor, shadingSteps)
    fontColor := fontArr[FontShadeSteps.Value]
    fontArr := ColorToGrayGradient(fontColor, saturationSteps)
    fontColor := fontArr[-FontSaturationSteps.Value]

    For Ctrl in myGui {
        If (Ctrl.Type = "Edit") or (Ctrl.Type = "ListBox") or (Ctrl.Type = "ComboBox")
            Ctrl.Opt("Background" listColor)
        If (Ctrl.Type = "Text") or (Ctrl.Type = "Edit") or (Ctrl.Type = "ListBox") or (Ctrl.Type = "ComboBox")
            Ctrl.Opt("c" fontColor) ; doesn't work for radios :- (
    }

    ; Update color values displayed in ListBox. 
    myListArr := ["fontColor:`t" fontColor, "listColor:`t" listColor, "formColor:`t" formColor,]
    myList.Delete() ; Clear all existing items
    myList.Add(myListArr) ; Add new items
}

; This is the function that is based closely on ColorGradient() by Lateralus138 and Teadrinker.
WhiteColorBlackGradient(color, steps) {
    static red   := color => color >> 16
         , green := color => (color >> 8) & 0xFF
         , blue  := color => color & 0xFF
         , fmt := Format.Bind('0x{:06X}')

    colorArr := []
    redArr := [], greenArr := [], blueArr := []

    ; Calculate steps for white to color and color to black
    stepsToColor := Floor((steps - 1) / 2)
    stepsToBlack := steps - stepsToColor - 1

    ; White to color
    for item in ['red', 'green', 'blue'] {
        step := (255 - %item%(color)) / stepsToColor
        value := 255
        Loop stepsToColor {
            %item%Arr.Push(Round(value))
            value -= step
        }
    }

    ; Add the specified color
    redArr.Push(red(color))
    greenArr.Push(green(color))
    blueArr.Push(blue(color))

    ; Color to black
    for item in ['red', 'green', 'blue'] {
        step := %item%(color) / stepsToBlack
        value := %item%(color)
        Loop stepsToBlack {
            value -= step
            %item%Arr.Push(Round(value))
        }
    }

    ; Construct the color array
    Loop steps {
        colorArr.Push(fmt(redArr[A_Index] << 16 | greenArr[A_Index] << 8 | blueArr[A_Index]))
    }

    return colorArr
}

ColorToGrayGradient(color, steps) {
    static red   := color => color >> 16
         , green := color => (color >> 8) & 0xFF
         , blue  := color => color & 0xFF
         , fmt := Format.Bind('0x{:06X}')

    colorArr := []
    redArr := [], greenArr := [], blueArr := []

    ; Calculate the gray value (average of R, G, B)
    grayValue := (red(color) + green(color) + blue(color)) / 3

    ; Calculate steps from color to gray
    for item in ['red', 'green', 'blue'] {
        startValue := %item%(color)
        step := (startValue - grayValue) / (steps - 1)
        value := startValue
        Loop steps {
            %item%Arr.Push(Round(value))
            value -= step
        }
    }

    ; Construct the color array
    Loop steps {
        colorArr.Push(fmt(redArr[A_Index] << 16 | greenArr[A_Index] << 8 | blueArr[A_Index]))
    }

    return colorArr
}

; Send simple list of vars to Windows Clipboard. 
exportClip(*)
{   Global fontColor, listColor, formColor
    myExp := 
    (
    "fontColor := `"" fontColor "`""
    "`nlistColor := `"" listColor "`""
    "`nformColor := `"" formColor "`""
    )
    A_Clipboard := myExp
    SoundBeep
}

; Create a sample gui script file, then attempt to run it. 
exportFile(*)
{   Global fontColor, listColor, formColor
    myExp := "
    (
#SingleInstance
#Requires AutoHotkey v2+
    )"
    myExp .= 
    (
"`n`nfontColor := `"" fontColor "`""
"`nlistColor := `"" listColor "`""
"`nformColor := `"" formColor "`"`n`n"
    )
    myExp .= "
    (
myGui := Gui()
myGui.SetFont("s12 c" fontColor)
myGui.BackColor := formColor
myGui.Add("Text","w350 center","Sample GUI To Demonstrate Colors")
myGui.Add("Edit", "w350 Background" listColor, "Sample")
myGui.Add("Button" , "w350", "Exit").onEvent("Click", (*)=>ExitApp())
myGui.Show()       
    )"
    FileName := "colorThemeSample-" A_Now ".ahk"
    FileAppend(myExp, FileName)
    While Not FileExist {
        FileName
        Sleep 100
    }
    Run FileName
}

; The color arrays for the main reference color. 
setColorArrays() {
    global additiveRGB := [ ; 120 elements, going around the colorwheel. 
        '0xff4538', '0xff4f38', '0xff5938', '0xff6338', '0xff6d38', '0xff7738', '0xff8138', '0xff8b38', '0xff9538', '0xff9f38',
        '0xffa938', '0xffb338', '0xffbc38', '0xffc638', '0xffd038', '0xffda38', '0xffe438', '0xffee38', '0xfff838', '0xfbff38',
        '0xf1ff38', '0xe7ff38', '0xeaff38', '0xe0ff38', '0xd6ff38', '0xccff38', '0xc2ff38', '0xb8ff38', '0xadff38', '0xa3ff38',
        '0x99ff38', '0x8fff38', '0x85ff38', '0x7bff38', '0x71ff38', '0x67ff38', '0x5dff38', '0x53ff38', '0x49ff38', '0x3eff38',
        '0x38ff3b', '0x38ff45', '0x38ff4f', '0x38ff59', '0x38ff63', '0x38ff6d', '0x38ff77', '0x38ff81', '0x38ff8b', '0x38ff95',
        '0x38ff9f', '0x38ffa9', '0x38ffb2', '0x38ffbc', '0x38ffc6', '0x38ffd0', '0x38ffda', '0x38ffe3', '0x38ffec', '0x38f2ff',
        '0x38e8ff', '0x38deff', '0x38d2ff', '0x38c8ff', '0x38beff', '0x38b4ff', '0x38aaff', '0x38a0ff', '0x3896ff', '0x388cff',
        '0x3882ff', '0x3878ff', '0x386eff', '0x3864ff', '0x385bff', '0x3851ff', '0x3847ff', '0x383dff', '0x3e38ff', '0x4838ff',
        '0x4d38ff', '0x5738ff', '0x6238ff', '0x6c38ff', '0x7638ff', '0x8038ff', '0x8a38ff', '0x9438ff', '0x9e38ff', '0xa838ff',
        '0xb238ff', '0xbc38ff', '0xc638ff', '0xd038ff', '0xda38ff', '0xe438ff', '0xee38ff', '0xf838ff', '0xff38f7', '0xff38ed',
        '0xff38e3', '0xff38d9', '0xff38cf', '0xff38c5', '0xff38bb', '0xff38b1', '0xff38a7', '0xff389d', '0xff3893', '0xff3889',
        '0xff387f', '0xff3875', '0xff386b', '0xff3861', '0xff3857', '0xff384d', '0xff3843', '0xff3839', '0xff3c39', '0xff4139',
    ]
    global subtractiveCMY := [
        "0xFF0000", "0xFF0700", "0xFF0D00", "0xFF1400", "0xFF1A00", "0xFF2100", "0xFF2700", "0xFF2E00", "0xFF3400", "0xFF3B00", 
        "0xFF4100", "0xFF4800", "0xFF4E00", "0xFF5500", "0xFF5C00", "0xFF6200", "0xFF6900", "0xFF6F00", "0xFF7600", "0xFF7C00", 
        "0xFF8300", "0xFF8900", "0xFF9000", "0xFF9600", "0xFF9D00", "0xFFA300", "0xFFAA00", "0xFFB100", "0xFFB700", "0xFFBE00", 
        "0xFFC400", "0xFFCB00", "0xFFD100", "0xFFD800", "0xFFDE00", "0xFFE500", "0xFFEB00", "0xFFF200", "0xFFF800", "0xFFFF00", 
        "0xF2F900", "0xE6F200", "0xD9EC00", "0xCCE600", "0xBFDF00", "0xB3D900", "0xA6D300", "0x99CC00", "0x8CC600", "0x80C000", 
        "0x73B900", "0x66B300", "0x59AC00", "0x4DA600", "0x40A000", "0x339900", "0x269300", "0x1A8D00", "0x0D8600", "0x008000", 
        "0x007A0D", "0x00731A", "0x006D26", "0x006633", "0x006040", "0x005A4D", "0x005359", "0x004D66", "0x004673", "0x004080", 
        "0x003A8C", "0x003399", "0x002DA6", "0x0026B3", "0x0020BF", "0x001ACC", "0x0013D9", "0x000DE6", "0x0006F2", "0x0000FF", 
        "0x0600F9", "0x0D00F2", "0x1300EC", "0x1A00E6", "0x2000DF", "0x2600D9", "0x2D00D2", "0x3300CC", "0x3900C6", "0x4000BF", 
        "0x4600B9", "0x4D00B3", "0x5300AC", "0x5900A6", "0x60009F", "0x660099", "0x6C0093", "0x73008C", "0x790086", "0x800080", 
        "0x860079", "0x8C0073", "0x93006C", "0x990066", "0x9F0060", "0xA60059", "0xAC0053", "0xB3004D", "0xB90046", "0xBF0040", 
        "0xC60039", "0xCC0033", "0xD2002D", "0xD90026", "0xDF0020", "0xE6001A", "0xEC0013", "0xF2000D", "0xF90006", "0xFF0000"
    ]
}