// @Maintainer jwrl
// @Released 2025-05-19
// @Author jwrl
// @Created 2025-05-10

/**
 This effect is similar to "Extrusion blend" but creates a series of flat colour
 offsets for a foreground title.  It can also be used with an externally created
 graphic.  For the best results the text effect should not have borders or drop
 shadow enabled.

 To apply it to a text or image key effect, make sure that both border and drop
 shadow are disabled.  Then apply this effect and open the routing display.
 Disconnect the background video from the title or image key input and connect
 it to the Bg input of this effect.  If you are using a graphic clip this effect
 will take care of the routing for you.

 The settings are shown below.
   [*] Opacity:  Allows fading in or out of the title effect.
   [*] Size:  Allows the size of the title to be adjusted.
   [*] Position X:  Sets the horizontal position of the title.
   [*] Position Y:  Sets the vertical position of the title.
   [*] Border
     [*] Thickness:  Self explanatory.
     [*] Colour:  Self explanatory.
   [*] Offsets
     [*] Quantity:  Sets the number of offsets generated from none to five.
     [*] Displacement X:  Sets the additive horizontal displacement for each offset.
     [*] Displacement Y:  Sets the additive vertical displacement for each offset.
     [*] Offset 1 colour:  Sets the text colour of the first offset.
     [*] Offset 2 colour:  Self explanatory.  As above but for offset 2.
     [*] Offset 3 colour:  Self explanatory.
     [*] Offset 4 colour:  Self explanatory.
     [*] Offset 5 colour:  Self explanatory.
     [*] Borders:  Chooses offsets bordered or unbordered.

 If borders are disabled the offsets can include or exclude the area that would be
 otherwise occupied by the border.  In this mode and with the number of offsets set
 to 1 the result is a bordered foreground with a hard edged coloured drop shadow.

 The default values of the effect set the number of offsets to 3 with all layers
 showing a thin black border.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeOffset.fx
//
// Version history:
//
// Modified 2025-05-19 by jwrl.
// Added border mode switching.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Edge offset", "Text", "Text Effects", "Offsets a text effect to give a 3d bordered edge appearance", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity,   "Opacity",  kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Scale,     "Size",     kNoGroup, "DisplayAsPercentage", 1.0, 0.2, 5.0);
DeclareFloatParam (PositionX, "Position", kNoGroup, "SpecifiesPointX", 0.0, -1.0, 1.0);
DeclareFloatParam (PositionY, "Position", kNoGroup, "SpecifiesPointY", 0.0, -1.0, 1.0);

DeclareFloatParam (Thickness, "Thickness", "Border", kNoFlags, 0.333333, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", "Border", kNoFlags, 0.05, 0.05, 0.05, 1.0));

DeclareIntParam (Quantity, "Quantity", "Offsets", 3, "None|One|Two|Three|Four|Five");

DeclareFloatParam (OffsetX, "Displacement", "Offsets", "SpecifiesPointX",  0.32, -1.0, 1.0);
DeclareFloatParam (OffsetY, "Displacement", "Offsets", "SpecifiesPointY", -0.32, -1.0, 1.0);

DeclareColourParam (Colour_1, "Offset 1 colour", "Offsets", kNoFlags, 0.85, 0.25, 0.10, 1.0));
DeclareColourParam (Colour_2, "Offset 2 colour", "Offsets", kNoFlags, 0.85, 0.85, 0.01, 1.0));
DeclareColourParam (Colour_3, "Offset 3 colour", "Offsets", kNoFlags, 0.25, 0.85, 0.10, 1.0));
DeclareColourParam (Colour_4, "Offset 4 colour", "Offsets", kNoFlags, 0.01, 0.85, 0.85, 1.0));
DeclareColourParam (Colour_5, "Offset 5 colour", "Offsets", kNoFlags, 0.10, 0.25, 0.85, 1.0));

DeclareIntParam (Borders, "Borders", "Offsets", 0, "Same as foreground|Unbordered, includes border area|Unbordered");

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define B_SCALE    10
#define OFFS_SCALE 0.025

float _sin_0 [] = { 0.0, 0.2225, 0.4339, 0.6235, 0.7818, 0.9010, 0.9749 };
float _cos_0 [] = { 0.9749, 0.9010, 0.7818, 0.6235, 0.4339, 0.2225, 0.0 };

float _sin_1 [] = { 0.1305, 0.3827, 0.6088, 0.7934, 0.9239, 0.9914 };
float _cos_1 [] = { 0.9914, 0.9239, 0.7934, 0.6088, 0.3827, 0.1305 };

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float2 xy = ((uv1 - float2 (PositionX + 0.5, 0.5 - PositionY)) / Scale) + 0.5.xx;

   return ReadPixel (Fg, xy);
}

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (RawBorder)
{
   float edgeX = pow (Thickness, 2.0) * B_SCALE / _OutputWidth;
   float edgeY = edgeX * _OutputAspectRatio;

   float2 offset, xy = uv3;

   float4 retval = ReadPixel (Fgd, xy);

   for (int i = 0; i < 7; i++) {
      offset.x = edgeX * _sin_0 [i];
      offset.y = edgeY * _cos_0 [i];

      retval += tex2D (Fgd, xy + offset);
      retval += tex2D (Fgd, xy - offset);

      offset.y = -offset.y;

      retval += tex2D (Fgd, xy + offset);
      retval += tex2D (Fgd, xy - offset);
   }

   return saturate (retval);
}

DeclarePass (Border)
{
   float edgeX = Thickness * B_SCALE / _OutputWidth;
   float edgeY = edgeX * _OutputAspectRatio;

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

   // The order in which the paramaters are returned is X is the border value
   // or zero if no borders are selected.  Y is the foreground alpha when 
   // Borders is set to 0 or 2, Z is the Fg alpha, and W is the clean border.

   retval.z = tex2D (Fgd, uv3).a;
   retval.w = saturate (max (retval.w, retval.z));
   retval.x = Borders == 0 ? retval.w : 0.0;
   retval.y = Borders == 1 ? retval.w : retval.z;

   return retval;
}

DeclareEntryPoint (EdgeOffset)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 edges, retval;

   float2 xy1 = float2 (-OffsetX, OffsetY * _OutputAspectRatio) * OFFS_SCALE;

   if (Quantity > 4) {
      edges = tex2D (Border, uv3 + (xy1 * 5.0));
      retval = lerp (lerp (Bgnd, Colour, edges.x), Colour_5, edges.y);
      }
   else retval = Bgnd;

   if (Quantity > 3) {
      edges = tex2D (Border, uv3 + (xy1 * 4.0));
      retval = lerp (lerp (retval, Colour, edges.x), Colour_4, edges.y);
      }

   if (Quantity > 2) {
      edges = tex2D (Border, uv3 + (xy1 * 3.0));
      retval = lerp (lerp (retval, Colour, edges.x), Colour_3, edges.y);
      }

   if (Quantity > 1) {
      edges = tex2D (Border, uv3 + (xy1 * 2.0));
      retval = lerp (lerp (retval, Colour, edges.x), Colour_2, edges.y);
      }

   if (Quantity > 0) {
      edges = tex2D (Border, uv3 + xy1);
      retval = lerp (lerp (retval, Colour, edges.x), Colour_1, edges.y);
      }

   retval = lerp (lerp (retval, Colour, tex2D (Border, uv3).a), Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, ReadPixel (Mask, uv1).x * Opacity);
}
