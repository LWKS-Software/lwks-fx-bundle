// @Maintainer jwrl
// @Released 2024-05-24
// @Author jwrl
// @Created 2020-04-23

/**
 This is a simple black and white balance utility.  To use it, first sample the point that
 you want to use as a white reference with the eyedropper, then get the black reference
 point.  Switch off "Select white and black reference points" and set up the white and
 black levels.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WhiteBlackBalance.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-05-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("White and black balance", "Colour", "Colour Tools", "A simple black and white balance utility", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (Reference, "Select white and black reference points", kNoGroup, true);

DeclareColourParam (WhitePoint, "White", "Reference points", kNoFlags, 1.0, 1.0, 1.0);
DeclareColourParam (BlackPoint, "Black", "Reference points", kNoFlags, 0.0, 0.0, 0.0);

DeclareFloatParam (WhiteLevel, "White", "Target levels", "DisplayAsPercentage", 1.0, 0.5, 1.5);
DeclareFloatParam (BlackLevel, "Black", "Target levels", "DisplayAsPercentage", 0.0, -0.5, 0.5);

//-----------------------------------------------------------------------------------------//
// Definitions and Declarations
//-----------------------------------------------------------------------------------------//

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Vid)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (WhiteBalance)
{
   if (IsOutOfBounds (uv2)) return _TransparentBlack;

   float4 retval, source = tex2D (Vid, uv2);

   if (!Reference) {
      // Get the black and white reference points

      retval = ((source - BlackPoint) / WhitePoint);

      // Convert the black and white reference values to the target values

      retval = ((retval * WhiteLevel) + BlackLevel.xxxx);

      retval.a = source.a;
   }
   else retval = source;

   retval = lerp (_TransparentBlack, saturate (retval), source.a);

   return lerp (source, retval, tex2D (Mask, uv2).x);
}
