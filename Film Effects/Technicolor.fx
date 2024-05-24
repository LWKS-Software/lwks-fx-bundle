// @Maintainer jwrl
// @Released 2024-05-24
// @Author khaver
// @Created 2011-04-20

/**
 Simulates the look of the classic 2-strip and 3-strip Technicolor film processes.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Technicolor.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Technicolor", "Colour", "Film Effects", "Simulates the look of the classic 2-strip and 3-strip Technicolor film processes", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Emulation", kNoGroup, 0, "Two_Strip|Three_Strip");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (TechnicolorTwoStrip)
{
   float4 source = ReadPixel (Input, uv1);
   float4 output = source;

   output.g += source.b / 2.0;
   output.b += source.g / 2.0;

   output = lerp (_TransparentBlack, output, source.a);

   return lerp (source, output, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (TechnicolorThreeStrip)
{
   float4 source = ReadPixel (Input, uv1);
   float4 output = source;

   output.r += (source.b - source.g) / 2.0;
   output.g += (source.b - source.r) / 2.0;
   output.b += (source.g - source.r) / 2.0;

   output = lerp (_TransparentBlack, output, source.a);

   return lerp (source, output, tex2D (Mask, uv1).x);
}
