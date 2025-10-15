// @Maintainer jwrl
// @Released 2025-10-15
// @Author schrauber
// @Created 2025-10-15

/**
 This effect provides a means of preserving pixels when scaling low resolution media.
 When using multiple effects, it's important to position this effect as close to the
 beginning of the routing as possible.  While many effects, such as the Color Correction
 effect, aren't a problem because they retain the original format information, many
 other effects, such as the Image Effect, or any effects with two inputs, scaling
 effects, etc., will interpolate the pixels as they are scaled.

 If the foreground contains transparency, whatever is connected to the background input
 will be visible if it's opaque.  When tested with backgrounds that had transparent areas
 it was found that areas could remain transparent at the effect output because the effect
 blends the alpha (transparency) values of both inputs.  In cases like that you can
 preserve foreground transparency by disconnecting the Bg input. 
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Pixel.fx
//
// Created 2025-10-15 by schrauber.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Pixel", "User", "Technical", "Without pixel interpolation, the resolution is scaled to the sequence resolution.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Point);
DeclareInput (Bg, Point);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Pixel)
{
   float4 fg = ReadPixel (Fg, uv1);
   float4 bg = ReadPixel (Bg, uv2);

   return lerp (bg, fg, fg.a);
}

