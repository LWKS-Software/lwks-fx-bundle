// @Maintainer jwrl
// @Released 2026-06-30
// @Author schrauber
// @Created 2021-01-21

/**
 Designed for simple zooming in.  It's not recommended for stronger negative scaling
 because the effect comes without a minimizing scaling filter.  There's also no
 background input.

   [*]Zoom:  Moves the frame in or out.
   [*]Positioning
      [*]Method:  Allows the positioning to have full control or be limited by
         the zoom size.
      [*]Position:  Self explanatory.
   [*]Mode:  Sets the background to be either transparent or opaque black.

 Features:
 - Supports the resolution in the effect chain from LWKS version 2021.

 - Three scaling modes:
   - "Standard" (similar with the standard LWKS transform effects)
   - Two "zoom center" modes, which also keep edge positions in focus during
     dynamic zooming.  In this mode, you should fine-tune the position with the
     maximum zoom used to ensure the best centering when zooming in.

 - Two backgrounds can be selected: opaque black and transparency.
   - In the transparent mode, the frame edge interpolation is only applied to the
     alpha channel in order to avoid double interpolation when other effects replace
     this transparency.  This mode should only be used if you really need transparency.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleZoomIn.fx
//
// Version history:
//
// Updated 2026-06-30 jwrl.
// Now uses Mask.rgba for masking rather than Mask.r.
// Added settings description to header block.
//
// Updated 2023-06-19 jwrl.
// Changed subcategory from "DVE Extras" to "Transform plus".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-05-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Simple zoom in", "DVE", "Transform plus", "Designed for simple zooming in (not recommended for negative zoom values).", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (In);

DeclareMask;

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

DeclareFloatParam (ScaleExp2, "Zoom",     kNoGroup,      "DisplayAsPercentage", 0.0, -0.5, 2.0);

DeclareIntParam (PosMethod,   "Method",   "Positioning", 0, "Standard|Zoom centre (inactive if original scaling)|Zoom centre;    Offset: +200% zoom");
DeclareFloatParam (Point1x,   "Position", "Positioning", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Point1y,   "Position", "Positioning", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (modeAlpha,   "Mode",     kNoGroup, 1,   "Background: Transparent|Background: Opaque black");

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

float4 fn_tex2D_p1 (sampler s,           // Pass 1 - Sampler function with alpha channel interpolation of edges (use only for the first pass)
                  float2 xy,            // Sampler Coordinates
                  float2 inDimensions,  // Dimensions of the texture in pixels at the input of the sampler used .
                  float scale)          // Linear scaling value of the shader (0 = 0% scaling , 1 = 100% unchanged scaling, etc.) 

{
   float2 inter = 1.0.xx / inDimensions;                              // Dimensions of the interpolation areas (Dimensions of an input text)

   inter /= max (1.0e-9.xx, scale.xx);                                // Adjust input interpolation dimensions to scale so that the interpolation width remains constant relative to the output pixel dimension.
   inter = min (0.5.xx, inter);                                       // Limitation of the scaling-dependent interpolation softness in order to avoid unexpected behavior with extremely small scalings.

   float2 distEdge   = 0.5.xx - abs(xy - 0.5.xx);                     // Distance from the edges of the source frame (negative values are outside)

   distEdge += inter;                                                 // Shift edges outward to avoid seeing interpolated lines at output frame edges when full screen.
   inter = min( 1.0.xx, distEdge * (1.0.xx / max (1e-9.xx, inter) )); // Reverses the direction of action, and scales with the distance of the sampler position from the source frame edge.

   float4 retval = ReadPixel (s, xy);                                 // Take a texture sample

   retval.a *= saturate( min (inter.x, inter.y));                     // Alpha edge softness 

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FixInp)
{ return ReadPixel (In, uv1); }

DeclareEntryPoint (ZoomInSimple)
{ 
   float2 inDimensions = float2 (_OutputWidth, _OutputHeight); // Use of variables compatible with versions before 2021.

   // ... Position vectors ...
   float2 point1 = float2 (Point1x - 0.5, 0.5 - Point1y);  // Zoom cernter (0 corresponds to the frame center)
   float2 point1b = point1 + 0.5.xx;        // Zoom cernter (0.5 corresponds to the frame center)

  
   //  ... Scale ...
   float offset = (PosMethod == 2) ? 2.0 : 0.0; // 200% zoom offset
   float scale = exp2(ScaleExp2 + offset);      // The dimensions of the output image are adjusted proportionally to the scale variable ( 0 = 0% dimensions, 1 = imput dimensions etc.).
                                                // The function `exp2(ScaleExp)` causes an exponential slider characteristic (details see code description below the Technique).

   //  ... Zoom control value ...
   float zoom = (1.0 + (-1.0 / max (1.0e-9, scale )));    // Zoom control value. Details see code description (below the Technique)
   float2 zoomVector = zoom.xx * (point1b - uv2);         // Zoom direction vector. Details see code description (below the Technique)


   //  ... Scaling & Position ...
   float2 posOut;                                                       // Sample position 
   if (PosMethod == 0) posOut = (uv2 + point1 *-1.0.xx) + zoomVector;   // Scaling & Position; Position setting point in sync with the same pixel
   if (PosMethod >= 1) posOut = uv2 + zoomVector;                       // Scaling & Position; Zoom centre (Inactive if original scaling).


   // Sampler, Border
   float4 retval = fn_tex2D_p1 (FixInp, posOut, inDimensions, scale);   // Sampler function with alpha softness
   if (modeAlpha == 1) {
      retval.rgb = retval.rgb * retval.aaa;            // RGB softness from alpha softness
      retval.a = 1.0;                                  // Remove all transparency, including alpha softness.
   }else{
      if (retval.a == 0.0) retval.rgb = 0.0.xxx;       // Disables reflection at alpha 0                             
   }

   // Aded LW mask at exit - jwrl.

   return lerp (tex2D (FixInp, uv2), retval, tex2D (Mask, uv2));
}
