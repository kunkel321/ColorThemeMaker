# Color Theme Maker

Kunkel321: (version date in code)

https://github.com/kunkel321/ColorThemeMaker

https://www.autohotkey.com/boards/viewtopic.php?f=83&t=132310

![Screenshot of main window](https://i.imgur.com/BJaONaj.png))


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
