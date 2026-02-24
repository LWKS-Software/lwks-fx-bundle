// @Maintainer jwrl
// @Released 2026-02-24
// @Author jwrl
// @Created 2026-02-23

/**
 This takes an image key or text effect and uses the alpha channel to invert the
 background image.  Both the the inverted image and the foreground can each be
 separately mixed over the background layer, resulting in a potentially vast
 range of visual effects.

 To apply it to a text or image key effect, first make sure that any border and/or
 drop shadow has been disabled.  They can be replaced in this effect as needed.
 Then apply this effect and open the routing display.  Make sure that you disconnect
 the background video from the title or image key input if you have chosen to use
 "Extracted foreground" in "Source mode". In either source mode the background video
 should be connected to the Bg input.

 The settings are shown below.
   [*] Opacity:  Allows fading in or out of the foreground image.
   [*] Inversion:  Allows fading out of the inverted background as fill to the
       foreground image (0%) then to the background as fill (-100%).
   [*] Tint level:  Adjusts the amount of the tint to be mixed with the foreground.
   [*] Tint colour:  Self explanatory.
   [*] If not extracting disconnect title/image key input
     [*] Source mode: Selects between video/image key/title or an extracted foreground.
   [*] Border
     [*] Opacity:  Self explanatory.
     [*] Thickness:  Self explanatory.
     [*] Colour:  Self explanatory.
   [*] Drop shadow
     [*] Opacity:  Self explanatory.
     [*] Feather:  Feathers the drop shadow.
     [*] Offset X:  Sets the horizontal displacement for the shadow.
     [*] Offset Y:  Sets the vertical displacement for the shadow.
     [*] Tint colour:  Sets the tint colour of the shadow.

 The default values of the effect are set to show the inverted background with a
 black border and a faint drop shadow.  The best results are usually obtained if
 the foreground text has no border or drop shadow.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TextInversion.fx 
//
// Version history:
//
// Modified 2026-02-24 by jwrl.
// Clarified FG input disconnection message.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Text inversion", "Text", "Text Effects", "The text video is optionally replaced with negative background", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity,    "Opacity",     kNoGroup, kNoFlags, 1.0,  0.0, 1.0);
DeclareFloatParam (Inversion,  "Inversion",   kNoGroup, kNoFlags, 1.0, -1.0, 1.0);
DeclareFloatParam (TintLevel,  "Tint level",  kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareColourParam (FgdTint,   "Tint colour", kNoGroup, kNoFlags, 0.2,  0.8, 1.0, 1.0);

DeclareIntParam   (Source,     "Source mode", "If not extracting disconnect title/image key input", 0, "Video, image key or title|Extracted foreground");

DeclareFloatParam (BdrOpacity, "Opacity",     "Border", kNoFlags, 1.00, 0.0, 1.0);
DeclareFloatParam (Thickness,  "Thickness",   "Border", kNoFlags, 0.25, 0.0, 1.0);
DeclareColourParam (Colour,    "Colour",      "Border", kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (ShdOpacity, "Opacity",     "Drop shadow", kNoFlags,           0.50,   0.0, 1.0));
DeclareFloatParam (ShdFeather, "Feather",     "Drop shadow", kNoFlags,           0.3333, 0.0, 1.0);
DeclareFloatParam (OffsetX,    "Offset",      "Drop shadow", "SpecifiesPointX",  0.20,  -1.0, 1.0);
DeclareFloatParam (OffsetY,    "Offset",      "Drop shadow", "SpecifiesPointY", -0.20,  -1.0, 1.0);
DeclareColourParam (ShdTint,   "Tint colour", "Drop shadow", kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define FOREGROUND 2
#define BORDER     10
#define SHADOW     0.04

#define _TransparentBlack 0.0.xxxx

float _sin_0 []  = { 0.0, 0.2225, 0.4339, 0.6235, 0.7818, 0.9010, 0.9749 };
float _cos_0 []  = { 0.9749, 0.9010, 0.7818, 0.6235, 0.4339, 0.2225, 0.0 };

float _sin_1 []  = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
float _cos_1 []  = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

float _pascal [] = { 0.00000006, 0.00000143, 0.00001645, 0.00012064, 0.00063336,
                     0.00253344, 0.00802255, 0.02062941, 0.04383749, 0.07793331,
                     0.11689997, 0.14878178, 0.16118026 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (KeyFg)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);

   // If we need to extract the alpha value, do it next.

   if (Source == 1) {
      float kDiff = distance (Fgnd.g, Bgnd.g);

      // The step above and the two below return zero if we have a colour match.
      // This can only occur if the foreground and background are the same.

      kDiff = max (kDiff, distance (Fgnd.r, Bgnd.r));
      kDiff = max (kDiff, distance (Fgnd.b, Bgnd.b));

      // If the difference value exceeds 0.25 alpha is 1.0.

      Fgnd.a    = smoothstep (0.0, 0.25, kDiff);
      Fgnd.rgb *= Fgnd.a;
   }

   // Set up the tint and background values to mix with Fg.

   float4 retval = float4 ((Bgnd.rgb * Bgnd.a), Fgnd.a);
   float4 tint   = FgdTint * (Bgnd.r + Bgnd.g + Bgnd.b) / 3.0;

   // Invert retval if the Inversion parameter is positive.

   if (Inversion > 0.0) retval.rgb = 1.0.xxx - retval.rgb;

   retval.rgb = lerp (retval.rgb, tint.rgb, TintLevel);     // Mix the foreground tint into retval.

   return lerp (Fgnd, retval, abs (Inversion));             // Return the modified Bg as the Fg (KeyFg).
}

DeclarePass (RawBorder)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;       // If we exceed frame size return transparent black.

   if (BdrOpacity == 0.0) return ReadPixel (KeyFg, uv3);    // If the border opacity is zero we do nothing.

   // Set the border size, adjusted for horizontal and vertical scale.

   float edgeX = Thickness * BORDER / _OutputWidth;
   float edgeY = edgeX * _OutputAspectRatio;

   float2 offset, xy = uv3;

   float4 retval = ReadPixel (KeyFg, xy);                   // Put the Fg with alpha in retval.

   // This loop expands the Fg with alpha.

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * _sin_0 [i];
      offset.y = edgeY * _cos_0 [i];

      retval += tex2D (KeyFg, xy + offset);
      retval += tex2D (KeyFg, xy - offset);

      offset.y = -offset.y;

      retval += tex2D (KeyFg, xy + offset);
      retval += tex2D (KeyFg, xy - offset);
   }

   // As the first step of border creation we return the expanded Fg aith processed alpha.

   return saturate (retval);
}

DeclarePass (Alias)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;       // If we exceed frame size return transparent black.

   if (BdrOpacity == 0.0) return ReadPixel (KeyFg, uv3);    // If the border opacity is zero we do nothing.

   // Set the border size, adjusted for horizontal and vertical scale.

   float edgeX = Thickness * BORDER / _OutputWidth;
   float edgeY = edgeX * _OutputAspectRatio;

   // Repeat the raw border generation, with the offset modified to fill in the edges and reduce aliassing.

   float2 offset, xy = uv3;

   float4 retval = tex2D (RawBorder, xy);

   for (int i = 0; i < 6; i++) {
      offset.x = edgeX * _sin_1 [i];
      offset.y = edgeY * _cos_1 [i];

      retval += tex2D (RawBorder, xy + offset);
      retval += tex2D (RawBorder, xy - offset);

      offset.y = -offset.y;

      retval += tex2D (RawBorder, xy + offset);
      retval += tex2D (RawBorder, xy - offset);
   }

   return saturate (retval);
}

DeclarePass (Border)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;       // If we exceed frame size return transparent black.

   float4 retval = tex2D (Alias, uv3);
   float4 Fgnd   = tex2D (KeyFg, uv3);

   float PixelWidth  = 1.0 / _OutputWidth;
   float PixelHeight = 1.0 / _OutputHeight;

   // Generate the border colour with the antialiassed border size

   if (BdrOpacity > 0.0) {
      float2 offset = max (PixelHeight * _OutputAspectRatio, PixelWidth).xx / (_OutputWidth * 2.0);

      retval += tex2D (Alias, uv3 + offset);
      retval += tex2D (Alias, uv3 - offset);

      offset.x = -offset.x;

      retval += tex2D (Alias, uv3 + offset);
      retval += tex2D (Alias, uv3 - offset);
      retval /= 5.0;

      float alpha = max (Fgnd.a, retval.a * BdrOpacity);

      retval = lerp (Colour, Fgnd, Fgnd.a);
      retval.a = alpha;
   }

   // Adjust the border opacity with the Fg opacity and range limit it to between 0 and 1.

   retval.a = saturate (retval.a - (Fgnd.a * (1.0 - Opacity)));

   return retval;
}

DeclarePass (Shadow)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;       // If we exceed frame size return transparent black.

   // Generate the drop shadow by recovering and displacing the border.  We will only be using the alpha, but we
   // need the combined border and Fg opacity that the border alpha contains.

   float2 xy = uv3 - float2 (OffsetX / _OutputAspectRatio, -OffsetY) * SHADOW;

   float4 retval = tex2D (Border, xy);

   // If we have drop shadow and it should be blurred, apply horizontal blur to the alpha using pascal's formula.

   if ((ShdOpacity != 0.0) && (ShdFeather != 0.0)) {
      float2 offset = float2 (ShdFeather * FOREGROUND / _OutputWidth, 0.0);
      float2 xy1 = xy + offset;

      retval *= _pascal [12];
      retval += tex2D (Border, xy1) * _pascal [11]; xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [10]; xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [9];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [8];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [7];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [6];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [5];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [4];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [3];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [2];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [1];  xy1 += offset;
      retval += tex2D (Border, xy1) * _pascal [0];
      xy1 = xy - offset;
      retval += tex2D (Border, xy1) * _pascal [11]; xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [10]; xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [9];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [8];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [7];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [6];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [5];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [4];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [3];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [2];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [1];  xy1 -= offset;
      retval += tex2D (Border, xy1) * _pascal [0];
   }

   return retval;
}

DeclareEntryPoint (TextInversion)
{
   float4 retval = tex2D (Shadow, uv3);                     // Recover the horizontally blurred drop shadow.
   float4 Bgnd = ReadPixel (Bgd, uv3);

   if (IsOutOfBounds (uv1)) return Bgnd;                    // If the foreground is out of range just show Bg.

   // If we have drop shadow and it should be blurred, apply the vertical blur using pascal's formula.

   if ((ShdOpacity != 0.0) && (ShdFeather != 0.0)) {
      float2 offset = float2 (0.0, ShdFeather * FOREGROUND * _OutputAspectRatio / _OutputWidth);
      float2 xy1 = uv3 + offset;

      retval *= _pascal [12];
      retval += tex2D (Shadow, xy1) * _pascal [11]; xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [10]; xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [9];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [8];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [7];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [6];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [5];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [4];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [3];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [2];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [1];  xy1 += offset;
      retval += tex2D (Shadow, xy1) * _pascal [0];
      xy1 = uv3 - offset;
      retval += tex2D (Shadow, xy1) * _pascal [11]; xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [10]; xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [9];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [8];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [7];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [6];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [5];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [4];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [3];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [2];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [1];  xy1 -= offset;
      retval += tex2D (Shadow, xy1) * _pascal [0];
   }

   float alpha = retval.a * ShdOpacity;

   retval   = tex2D (Border, uv3);
   alpha    = max (alpha, retval.a);
   retval   = lerp (ShdTint, retval, retval.a);
   retval.a = alpha * Opacity;

   float4 comp = float4 (lerp (Bgnd, retval, retval.a).rgb, max (Bgnd.a, retval.a));

   return lerp (Bgnd, comp, tex2D (Mask, uv3).x);
}


