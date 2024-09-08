// @Maintainer jwrl
// @Released 2024-09-08
// @Author jwrl
// @Created 2024-09-08

/**
 Show alpha is a utility designed to show the presence of the alpha channel in a graphic
 or animated sequence.  The modes and what they do are:

   • Normal blend:  Identical to the Lightworks blend effect.
   • Foreground only:  Shows the foreground, but with black wherever there is transparency.
   • Show alpha as checkerboard:  Shows the foreground over a checkerboard pattern.
   • Show alpha:  The alpha (transparency) channel is shown as white over black.

 The amount control in normal blend mode works as the opacity does in the blend effect.
 In the next two display modes it fades between foreground over background at 0% to the
 selected mode at 100%.  Show alpha just fades the alpha display in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ShowAlpha.fx
//
// Version history:
//
// Built 2024-09-08 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Show alpha", "Mix", "Blend Effects", "Performa a simple blend or just shows the alpha channel", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam   (SetTechnique, "Display", kNoGroup, 0, "Normal blend|Foreground only|Show alpha as checkerboard|Show alpha");

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 checkerboard (float2 uv)
{
   float x = round (frac (uv.x * _OutputWidth  / 64.0));
   float y = round (frac (uv.y * _OutputHeight / 64.0));

   return float4 ((0.45 - clamp (abs (x - y), 0.2, 0.25)).xxx, 0.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg0)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg0)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ShowAlpha_0)
{
   float4 Fgnd = tex2D (Fg0, uv3);
   float4 Bgnd = tex2D (Bg0, uv3);

   float mask = tex2D (Mask, uv3).x;

   return lerp (Bgnd, Fgnd, Fgnd.a * mask * Amount);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Fg1)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg1)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ShowAlpha_1)
{
   float4 Fgnd = tex2D (Fg1, uv3);
   float4 Bgnd = lerp (tex2D (Bg1, uv3), Fgnd, Fgnd.a);

   Fgnd.rgb *= Fgnd.a;

   float mask = tex2D (Mask, uv3).x;

   return lerp (Bgnd, Fgnd, mask * Amount);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Fg2)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bg2)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ShowAlpha_2)
{
   float4 Fgnd = tex2D (Fg2, uv3);
   float4 Bgnd = lerp (tex2D (Bg2, uv3), Fgnd, Fgnd.a);

   float mask = tex2D (Mask, uv3).x;

   Fgnd = lerp (checkerboard (uv3), Fgnd, Fgnd.a);

   return lerp (Bgnd, Fgnd, mask * Amount);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Fg3)
{ return ReadPixel (Fg, uv1); }

DeclareEntryPoint (ShowAlpha_3)
{
   float4 Fgnd = float4 (tex2D (Fg3, uv3).aaa, 1.0);

   float mask = tex2D (Mask, uv3).x;

   return lerp (float4 (0.0.xxx, 1.0), Fgnd, mask * Amount);
}

