// @Maintainer jwrl
// @Released 2026-07-03
// @Author jwrl
// @Created 2016-04-22

/**
 This effect is designed to modulate the input with a texture from an external piece of
 art.  The texture may be coloured but only the luminance value will be used.  New in
 this version is a means of adjusting the texture levels and inverting them, and a way
 to deal with the edges of frame of both video and texture has also been added.

   [*]Overlay:  Adjusts the amount of texture pattern that will be mixed into the video.
   [*]Size:  Scales the texture, not the video.
   [*]Depth:  Controls the displacement caused by the texture, giving the illusion of
      3D depth.
   [*]Offset
      [*]X:  Displaces the effect of the texture pattern's highlights horizontally to
         enhance the 3D effect.
      [*]Y:  Similar to the above, but displaces the texture vertically.
   [*]Video mode:  Chooses what happens if the video size is less than the sequence
      size.  The overflow can be blanked, or the video can be tiled or mirrored.
   [*]Art setup
      [*]Texture mode:  This is the same as video mode, but is applied to the texture.
      [*]Invert texture:  The texture colours will be inverted, making them negative.
      [*]Gamma:  The standard colourgrade function, applied to the texture pattern.
      [*]Contrast:  The standard video function applied to the texture.
      [*]Gain:  As above.
      [*]Brightness:  As above.
      [*]Show texture:  Allows the texture pattern to be shown to assist in setup.

 It is advisable to initially enable Show texture, and using Lightwork's video tools,
 adjust the texture levels for best dark - light separation.  Once you've done that,
 turn show texture off.  Adjust the overlay until you're comfortable with it then the
 depth and offsets.  If necessary set the video and texture modes and the texture size.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Texturiser.fx
//
// Version history:
//
// Updated 2026-07-03 jwrl.
// Restructured header text, includes settings.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Texturiser", "Stylize", "Textures", "Generates bump mapped textures on an image using external texture artwork", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Art, Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount,       "Overlay",        kNoGroup,    kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Size,         "Size",           kNoGroup,    kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Depth,        "Depth",          kNoGroup,    kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (OffsetX,      "X",              "Offset",    kNoFlags, 0.5, -1.0, 2.0);
DeclareFloatParam (OffsetY,      "Y",              "Offset",    kNoFlags, 0.5, -1.0, 2.0);

DeclareIntParam (VideoMode,      "Video mode",     kNoGroup,    0, "Single|Tiled|Mirrored");

DeclareIntParam (TextureMode,    "Texture mode",   "Art setup", 1, "Single|Tiled|Mirrored");
DeclareBoolParam (InvertTexture, "Invert texture", "Art setup", false);
DeclareFloatParam (Gamma,        "Gamma",          "Art setup", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (Contrast,     "Contrast",       "Art setup", "DisplayAsPercentage", 1.0, 0.0, 2.0);
DeclareFloatParam (Gain,         "Gain",           "Art setup", "DisplayAsPercentage", 1.0, 0.0, 2.0);
DeclareFloatParam (Brightness,   "Brightness",     "Art setup", "DisplayAsPercentage", 0.0, -1.0, 1.0);
DeclareBoolParam (ShowTexture,   "Show texture",   "Art setup", false);

DeclareIntParam (_InpOrientation);

DeclareFloat4Param (_InpExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define AMT       0.2   // Amount scale factor
#define DPTH      1.5   // Depth scale factor
#define SIZE      0.75  // Size scale factor
#define REDUCTION 0.9   // Foreground reduction for texture add

#define BLACK float4(0.0.xxx, 1.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 Mirrored (float2 uv)
{ return 1.0.xx - (abs (frac (abs (uv) / 2.0) - 0.5.xx) * 2.0); }

float2 Tiled (float2 uv)
{ return frac (1.0.xx + frac (uv)); }

float2 fixOffset (float displace)
{
   float2 offset = _InpOrientation == 90  ? 0.5.xx - float2 (OffsetY, OffsetX)
                 : _InpOrientation == 180 ? float2 (OffsetX - 0.5, 0.5 - OffsetY)
                 : _InpOrientation == 270 ? float2 (OffsetY, OffsetX) - 0.5.xx
                                          : float2 (0.5 - OffsetX, OffsetY - 0.5);

   return offset * abs (_InpExtents.xy - _InpExtents.zw) * displace / 100.0;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Artwork)
{
   float2 xy = ((uv1 - 0.5.xx) * (1.0 - (Size * SIZE))) + 0.5.xx;

   float4 retval = TextureMode == 1 ? tex2D (Art, Tiled (xy))
                 : TextureMode == 2 ? tex2D (Art, Mirrored (xy))
                 : IsOutOfBounds (xy) ? BLACK : tex2D (Art, xy);

   float luma = (retval.r + retval.g + retval.b) / 3.0;

   if (InvertTexture) luma = 1.0 - luma;

   luma = ((((pow (luma, 1.0 / Gamma) * Gain) + Brightness) - 0.5) * Contrast) + 0.5;

   return float4 (luma.xxx, retval.a);
}

DeclareEntryPoint (Texturiser)
{
   float amt = Amount * AMT;

   float4 Tex = tex2D (Artwork, uv3);

   if (ShowTexture) return Tex;

   Tex.rgb *= Depth * DPTH;

   float2 xy = uv2 + fixOffset (Tex.g);

   float4 Fgd = VideoMode == 1 ? tex2D (Inp, Tiled (xy))
              : VideoMode == 2 ? tex2D (Inp, Mirrored (xy)) : tex2D (Inp, xy);

   float alpha = Fgd.a;

   Fgd = saturate (Fgd + (Tex * amt));
   Fgd = lerp (Fgd, Tex, amt);

   if ((VideoMode == 0) && IsOutOfBounds (xy)) Fgd = BLACK;

   return IsOutOfBounds (uv2) ? kTransparentBlack : float4 (Fgd.rgb, alpha);
}
