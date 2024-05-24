// @Maintainer jwrl
// @Released 2024-05-24
// @Author msi
// @OriginalAuthor "Wojciech Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)"
// @Created 2011-05-27

/**
 Vintage look simulates what happens when the dye layers of old colour film stock start
 to fade.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VintageLook.fx
//
// 2011 msi, licensed Creative Commons [BY-NC-SA] - Uses Vintage Look routine by
// Wojciech Toman (http://wtomandev.blogspot.com/2011/04/vintage-look.html)
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Vintage look", "Colour", "Film Effects", "Simulates what happens when the dye layers of old colour film stock start to fade.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (Yellow, "Yellow", "Balance", kNoFlags, 0.9843, 0.9490, 0.6392, 1.0);
DeclareColourParam (Magenta, "Magenta", "Balance", kNoFlags, 0.9098, 0.3960, 0.7019, 1.0);
DeclareColourParam (Cyan, "Cyan", "Balance", kNoFlags, 0.0352, 0.2862, 0.9137, 1.0);

DeclareFloatParam (YellowLevel, "Yellow", "Overlay", kNoFlags, 0.59, 0.0, 1.0);
DeclareFloatParam (MagentaLevel, "Magenta", "Overlay", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (CyanLevel, "Cyan", "Overlay", kNoFlags, 0.17, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (VintageLook)
{
   float4 source = ReadPixel (Input, uv1);

   // BEGIN Vintage Look routine by Wojciech Toman
   // (http://wtomandev.blogspot.com/2011/04/vintage-look.html)

   float4 corrected = lerp (source, source * Yellow, YellowLevel);

   corrected = lerp (corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Magenta))),  MagentaLevel);
   corrected = lerp (corrected, (1.0.xxxx - ((1.0.xxxx - corrected) * (1.0.xxxx - Cyan))), CyanLevel);

   // END Vintage Look routine by Wojciech Toman

   corrected = lerp (_TransparentBlack, corrected, source.a);	

   return lerp (source, corrected, tex2D (Mask, uv1).x);	
}
