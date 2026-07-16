// @Maintainer jwrl
// @Released 2026-07-16
// @Author jwrl
// @Created 2023-03-04

/**
 This transition splits the outgoing image into strips which then move off either
 horizontally or vertically to reveal the incoming image.  This updated version adds
 the ability to choose whether to wipe the outgoing image out or the incoming image in.

   [*]Amount:  The normal keyframed transition progress.
   [*]Strip direction:  Sets the direction of movement of the slices.
   [*]Strip type:  Sets the section of the strips which moves first.
   [*]Strip number:  Sets the number of strips that will occupy the full screen.
   [*]Slice incoming video:  Switches whether incoming or outgoing video is sliced.
      Overridden by blend mode.
   [*]Enable blend transitions:   Changes the mode from opaque video to transparent
      video such as titles and the like.
   [*]Blend settings
      [*]Source:  Selects between an extracted video source and transparent video.
      [*]Transition into blend:  Selects between transitioning into or out of a
         blended video source.
      [*]Fine tune:  Fine tunes the separation of an extracted video source from
         its background.
      [*]Show foreground key:  Showing the key helps in setting up the clip.
      [*]Swap sources:  This can be necessary when using a folded delta key
         (extracted) transition.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SliceTrans.fx
//
// Version history:
//
// Updated 2026-07-16 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Sliced transition", "Mix", "Wipe transitions", "Separates and splits the image into strips which move on or off horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",          kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Strip direction", kNoGroup, 1,      "Right to left|Left to right|Top to bottom|Bottom to top");
DeclareIntParam   (Mode,           "Strip type",      kNoGroup, 0,      "Mode A|Mode B");
DeclareFloatParam (StripNumber,    "Strip number",    kNoGroup,         kNoFlags, 10.0, 5.0, 20.0);
DeclareBoolParam  (Direction,      "Slice incoming video", kNoGroup,    false);
DeclareBoolParam  (Blended,        "Enable blend transitions",          kNoGroup, false);

DeclareIntParam   (Source,         "Source",          "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",             "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",       "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",               "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",    "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Slice right to left

DeclarePass (Fg_R)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceRight)
{
   float4 Fgnd = tex2D (Fg_R, uv3);
   float4 Bgnd = tex2D (Bg_R, uv3);
   float4 retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      float4 maskBg;

      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         if (SwapDir) {
            amount_1 = pow (1.0 - Amount, 3.0);
            amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

            xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
         }
         else {
            amount_1 = pow (Amount, 3.0);
            amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

            xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
         }

         retval = ReadPixel (Fg_R, xy);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_R, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_R, xy);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Slice left to right

DeclarePass (Fg_L)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceLeft)
{
   float4 Fgnd = tex2D (Fg_L, uv3);
   float4 Bgnd = tex2D (Bg_L, uv3);
   float4 retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      float4 maskBg;

      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         if (SwapDir) {
            amount_1 = pow (1.0 - Amount, 3.0);
            amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

            xy.x += (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
         }
         else {
            amount_1 = pow (Amount, 3.0);
            amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

            xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.y) * strips) * amount_2) + amount_1;
         }

         retval = ReadPixel (Fg_L, xy);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.x -= (Mode == 1) ? (ceil (xy.y * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.y) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_L, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_L, xy);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Slice top to bottom

DeclarePass (Fg_T)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_T)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceTop)
{
   float4 Fgnd = tex2D (Fg_T, uv3);
   float4 Bgnd = tex2D (Bg_T, uv3);
   float4 retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      float4 maskBg;

      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         if (SwapDir) {
            amount_1 = pow (1.0 - Amount, 3.0);
            amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

            xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
         }
         else {
            amount_1 = pow (Amount, 3.0);
            amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

            xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
         }

         retval = ReadPixel (Fg_T, xy);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_T, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_T, xy);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Slice bottom to top

DeclarePass (Fg_B)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_B)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (SliceBottom)
{
   float4 Fgnd = tex2D (Fg_B, uv3);
   float4 Bgnd = tex2D (Bg_B, uv3);
   float4 retval;

   float2 xy = uv3;

   float strips = max (2.0, round (StripNumber));
   float amount_0, amount_1, amount_2;

   if (Blended) {
      float4 maskBg;

      if (ShowKey) {
         retval = Fgnd;
         maskBg = kTransparentBlack;
      }
      else {
         if (SwapDir) {
            amount_1 = pow (1.0 - Amount, 3.0);
            amount_2 = (1.0 - pow (Amount, 3.0)) / (strips * 2.0);

            xy.y -= (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
         }
         else {
            amount_1 = pow (Amount, 3.0);
            amount_2 = (1.0 - pow (1.0 - Amount, 3.0)) / (strips * 2.0);

            xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_2) + amount_1
                                : (ceil ((1.0 - xy.x) * strips) * amount_2) + amount_1;
         }

         retval = ReadPixel (Fg_B, xy);
         maskBg = Bgnd;
      }

      retval = lerp (maskBg, retval, retval.a);
   }
   else {
      amount_0 = Direction ? 1.0 - Amount : Amount;
      amount_1 = (1.0 - pow (1.0 - amount_0, 3.0)) / (strips * 2.0);
      amount_2 = pow (amount_0, 3.0);

      xy.y += (Mode == 1) ? (ceil (xy.x * strips) * amount_1) + amount_2
                          : (ceil ((1.0 - xy.x) * strips) * amount_1) + amount_2;

      if (Direction) { retval = (IsOutOfBounds (xy)) ? Fgnd : tex2D (Bg_B, xy); }
      else retval = (IsOutOfBounds (xy)) ? Bgnd : tex2D (Fg_B, xy);
   }

   return retval;
}
