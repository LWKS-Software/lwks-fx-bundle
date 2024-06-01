// @Maintainer jwrl
// @Released 2024-06-01
// @Author jwrl
// @Created 2024-06-01

/**
 This transition pushes the outgoing video of right, left, up or down to reveal the
 incoming video.  The trailing edge of the outgoing video is smeared and faded out
 over the incoming video.

 Because it relies on having a hard full frame edge in the video this effect does
 not support blended images.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SmearWipe.fx
//
// Version history:
//
// Built 2024-06-01 jwrl
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Smear wipe", "Mix", "Wipe transitions", "A push wipe with a trailing smeared edge", "CanSize|HasMinOutputSize|HasMaxOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear);
DeclareInput (Bg, Linear);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (SmearLen, "Smear length", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Transition direction", kNoGroup, 0, "Wipe right|Wipe left|Wipe up|Wipe down");

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLUR_SCALE 1280.0

#define HALF_PI    1.5708
#define QTR_PI     0.7854

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 SmearSoften (sampler S, float2 uv)
{
   // Recover the smeared video

   float4 retval = tex2D (S, uv);

   // Now blur the foreground

   float2 xy1, xy2, scale = float2 (1.0, _OutputAspectRatio) * 0.01;

   float angle = 0.0;

   // The antialias is an eight by 45 degree rotary blur at three samples deep.  The outer
   // loop achieves eight steps in 4 passes by using both positive and negative offsets.

   for (int i = 0; i < 4; i++) {
      xy1 = 0.0;
      xy2 = sin (float2 (angle, angle + HALF_PI)) * scale;

      for (int j = 0; j < 3; j++) {
         xy1 += xy2;
         retval += tex2D (S, uv + xy1);
         retval += tex2D (S, uv - xy1);
      }

      angle += QTR_PI;
   }

   return retval /= 25.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// technique SmearWipeRight

DeclarePass (Fg_R)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Fe_R)
{
   float edge = saturate (uv3.x * 100.0 * (1.0 - (0.75 * SmearLen)));

   return lerp (0.0.xxxx, tex2D (Fg_R, uv3), edge);
}

DeclarePass (Sm_R)
{
   float offset = 0.5 - (SmearLen * 0.5);
   float vid_fade = smoothstep (offset, 0.5, uv3.x);

   return tex2D (Fg_R, uv3 - float2 (0.5, 0.0)) * vid_fade;
}

DeclarePass (Fs_R)
{ return SmearSoften (Sm_R, uv3); }

DeclareEntryPoint (SmearWipeRight)
{
   float progress = (SmearLen * 0.5) + 1.0;

   progress *= Amount;

   float2 xy1 = float2 (uv3.x - progress, uv3.y);
   float2 xy2 = float2 (xy1.x + 0.5, xy1.y);

   float4 Fgnd  = ReadPixel (Fe_R, xy1);
   float4 Smear = ReadPixel (Fs_R, xy2);
   float4 Bgnd  = lerp (ReadPixel (Bg, uv2), Smear, Smear.a);

   Bgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique SmearWipeLeft

DeclarePass (Fg_L)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Fe_L)
{
   float edge = saturate ((1.0 - uv3.x) * 100.0 * (1.0 - (0.75 * SmearLen)));

   return lerp (0.0.xxxx, tex2D (Fg_L, uv3), edge);
}

DeclarePass (Sm_L)
{
   float offset = 0.5 + (SmearLen * 0.5);
   float vid_fade = 1.0 - smoothstep (0.5, offset, uv3.x);

   return tex2D (Fg_L, uv3 + float2 (0.5, 0.0)) * vid_fade;
}

DeclarePass (Fs_L)
{ return SmearSoften (Sm_L, uv3); }

DeclareEntryPoint (SmearWipeLeft)
{
   float progress = (SmearLen * 0.5) + 1.0;

   progress *= Amount;

   float2 xy1 = float2 (uv3.x + progress, uv3.y);
   float2 xy2 = float2 (xy1.x - 0.5, xy1.y);

   float4 Fgnd  = ReadPixel (Fe_L, xy1);
   float4 Smear = ReadPixel (Fs_L, xy2);
   float4 Bgnd  = lerp (ReadPixel (Bg, uv2), Smear, Smear.a);

   Bgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique SmearWipeUp

DeclarePass (Fg_U)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Fe_U)
{
   float edge = saturate ((1.0 - uv3.y) * 100.0 * (1.0 - (0.75 * SmearLen)));

   return lerp (0.0.xxxx, tex2D (Fg_U, uv3), edge);
}

DeclarePass (Sm_U)
{
   float offset = 0.5 + (SmearLen * 0.5);
   float vid_fade = 1.0 - smoothstep (0.5, offset, uv3.y);

   return tex2D (Fg_U, uv3 + float2 (0.0, 0.5)) * vid_fade;
}

DeclarePass (Fs_U)
{ return SmearSoften (Sm_U, uv3); }

DeclareEntryPoint (SmearWipeUp)
{
   float progress = (SmearLen * 0.5) + 1.0;

   progress *= Amount;

   float2 xy1 = float2 (uv3.x, uv3.y + progress);
   float2 xy2 = float2 (xy1.x, xy1.y - 0.5);

   float4 Fgnd  = ReadPixel (Fe_U, xy1);
   float4 Smear = ReadPixel (Fs_U, xy2);
   float4 Bgnd  = lerp (ReadPixel (Bg, uv2), Smear, Smear.a);

   Bgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique SmearWipeDown

DeclarePass (Fg_D)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Fe_D)
{
   float edge = saturate (uv3.y * 100.0 * (1.0 - (0.75 * SmearLen)));

   return lerp (0.0.xxxx, tex2D (Fg_D, uv3), edge);
}

DeclarePass (Sm_D)
{
   float offset = 0.5 - (SmearLen * 0.5);
   float vid_fade = smoothstep (offset, 0.5, uv3.y);

   return tex2D (Fg_D, uv3 - float2 (0.0, 0.5)) * vid_fade;
}

DeclarePass (Fs_D)
{ return SmearSoften (Sm_D, uv3); }

DeclareEntryPoint (SmearWipeDown)
{
   float progress = (SmearLen * 0.5) + 1.0;

   progress *= Amount;

   float2 xy1 = float2 (uv3.x, uv3.y - progress);
   float2 xy2 = float2 (xy1.x, xy1.y + 0.5);

   float4 Fgnd  = ReadPixel (Fe_D, xy1);
   float4 Smear = ReadPixel (Fs_D, xy2);
   float4 Bgnd  = lerp (ReadPixel (Bg, uv2), Smear, Smear.a);

   Bgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

