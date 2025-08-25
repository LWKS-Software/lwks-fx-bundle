// @Maintainer jwrl
// @Released 2025-08-25
// @Author jwrl
// @Created 2022-08-28

/**
 This is just a simple rule of thirds grid generator.  That's it.  It will handle both
 portrait and landscape format media at any resolution supported by Lightworks.  The
 display is locked to the sequence size and aspect ratio.  It is NOT intended to be
 locked to the size and aspect ratio of the input video.

 It is suitable for LW version 2022.2 and above, but is unlikely to compile on older
 versions.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RuleOfThirds.fx
//
// Version history:
//
// Updated 2025-08-25 jwrl.
// Corrected a geometry bug affecting rotated media.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Rule of thirds", "User", "Technical", "A simple rule of thirds grid generator", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity,   "Opacity",      kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Lweight,   "Line weight",  kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareIntParam   (BlendMode, "Grid display", kNoGroup, 0, "Add|Subtract|Difference");

DeclareFloatParam (_OutputAspectRatio);

DeclareIntParam   (_InputOrientation);

DeclareFloat4Param (_InputExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SUBTRACT 1       // Subtract value used by BlendMode
#define DIFFRNCE 2       // Difference value used by BlendMode

#define WHITE    1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hline (float4 video, float2 uv, float pos, float thickness)
{
   // To calculate the position of the horizontal guide we only need the y coordinate.
   // Since y values in Lightworks have 0 at the top of frame and HLSL / GLSL place
   // it at the bottom the position must be inverted by subtracting it from 1.0.

   float position = 1.0 - pos;

   // First remap the Y coords to sequence space if there's 0 degree orientation.

   if (_InputOrientation == 0)
      uv.y = (uv.y - _InputExtents.y) / (_InputExtents.w - _InputExtents.y);

   // Now we calculate the boundaries by adding and subtracting the line thickness.

   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   // If the Y position is inside the boundaries we can now blend the line over the video.

   if ((uv.y > Abounds) && (uv.y < Bbounds)) {
      video = BlendMode == DIFFRNCE ? abs (video - WHITE) :
              BlendMode == SUBTRACT ? saturate (video - WHITE) : saturate (video + WHITE);

      // Regardless of the blend mode used, alpha is turned fully on.  This ensures that
      // even if we blend this effect with something else the guide will still show.

      video.a = 1.0;
   }

   return video;
}

float4 Vline (float4 video, float2 uv, float position, float thickness)
{
   // X coordinates don't need inversion so this process is as shown in Hline() after
   // the position inversion.  First remap the X coords to sequence space if there's
   // 0 degree orientation.

   if (_InputOrientation == 0)
      uv.x = (uv.x - _InputExtents.x) / (_InputExtents.z - _InputExtents.x);

   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   if ((uv.x > Abounds) && (uv.x < Bbounds)) {
      video = BlendMode == DIFFRNCE ? abs (video - WHITE) :
              BlendMode == SUBTRACT ? saturate (video - WHITE) : saturate (video + WHITE);

      video.a = 1.0;
   }

   return video;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ThirdsRule)
{
   // Start by calculating the H and V guide line weights, allowing for the aspect ratio.

   float Hweight = ((Lweight * 4.5) + 0.5) * 0.001;
   float Vweight;

   // Next adjust the line weight variation caused by rotation.

   if ((_InputOrientation == 0) || (_InputOrientation == 180)) {
      Vweight  = Hweight;
      Hweight *= _OutputAspectRatio;
   }
   else Vweight = Hweight * _OutputAspectRatio;

   // Recover the video input and do the rule of thirds.

   float4 video  = ReadPixel (Input, uv1);
   float4 retval = Hline (video, uv1, 0.33333333, Hweight);

   retval = Hline (retval, uv1, 0.66666667, Hweight);
   retval = Vline (retval, uv1, 0.33333333, Vweight);
   retval = Vline (retval, uv1, 0.66666667, Vweight);

   return lerp (video, retval, Opacity);
}
