// @Maintainer jwrl
// @Released 2024-08-29
// @Author Vision-victory
// @Created 2024-08-28

/**
 This effect uses a simple median filter algorithm to reduce video noise.  The range
 of correction is controlled by the spread setting, and the amount of filtration
 mixed back is set by the Amount setting.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect NoiseReduction.fx
//
// Version history:
//
// Built 2024-08-28 by Vision-victory.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Noise reduction", "Stylize", "Repair tools", "This uses a median filter to reduce video noise.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask();

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Spread, "Spread", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 f_median (sampler2D sam, float2 uv)
{
   float Step  = Spread * 0.005;
   float rmid,gmid,bmid,rmidy,gmidy,bmidy = 0.0;

   float4 input  = ReadPixel(sam, uv );
   
   float inx2 = uv.x+(Step/_OutputAspectRatio);
   if ((uv.x+(Step/_OutputAspectRatio))> 1.0) inx2 = 2.0-(uv.x+(Step/_OutputAspectRatio));
   float inx3 = uv.x-((Step/_OutputAspectRatio)*2);
   if ((uv.x+(Step/_OutputAspectRatio)*2.0)> 1.0) inx3 = 2.0-(uv.x+(Step/_OutputAspectRatio));
   
   float iny2 = uv.y+(Step);
   if ((uv.y+(Step))> 1.0) iny2 = 2.0-(uv.y+(Step));
   float iny3 = uv.y-(Step*2);
   if ((uv.y+(Step)*2.0)> 1.0) iny3 = 2.0-(uv.y+(Step));
   
   float4 input2  = ReadPixel( sam, float2(inx2,uv.y) );
   float4 input3  = ReadPixel( sam, float2(inx3,uv.y) );
   
   float4 input2y  = ReadPixel( sam, float2(uv.x,iny2) );
   float4 input3y  = ReadPixel( sam, float2(uv.x,iny3) );
      
   float rpix1 = input.r;
   float rpix2 = input2.r;
   float rpix3 = input3.r;
   
   float rpix1y = input.r;
   float rpix2y = input2y.r;
   float rpix3y = input3y.r;
     
   if (max(rpix1, rpix2) == max(rpix2, rpix3)) rmid = max(rpix1, rpix3);
    else rmid = max(rpix2, min(rpix1, rpix3));
    
   if (max(rpix1y, rpix2y) == max(rpix2y, rpix3y)) rmidy = max(rpix1y, rpix3y);
    else rmidy = max(rpix2y, min(rpix1y, rpix3y));
   
   float gpix1 = input.g;
   float gpix2 = input2.g;
   float gpix3 = input3.g;
   
   float gpix1y = input.g;
   float gpix2y = input2y.g;
   float gpix3y = input3y.g;
    
   if (max(gpix1, gpix2) == max(gpix2, gpix3)) gmid = max(gpix1, gpix3);
    else gmid = max(gpix2, min(gpix1, gpix3));
    
   if (max(gpix1y, gpix2y) == max(gpix2y, gpix3y)) gmidy = max(gpix1y, gpix3y);
    else gmidy = max(gpix2y, min(gpix1y, gpix3y)); 
   
   float bpix1 = input.b;
   float bpix2 = input2.b;
   float bpix3 = input3.b;
   
   float bpix1y = input.b;
   float bpix2y = input2y.b;
   float bpix3y = input3y.b;
   
   if (max(bpix1, bpix2) == max(bpix2, bpix3)) bmid = max(bpix1, bpix3);
    else bmid = max(bpix2, min(bpix1, bpix3));
    
   if (max(bpix1y, bpix2y) == max(bpix2y, bpix3y)) bmidy = max(bpix1y, bpix3y);
    else bmidy = max(bpix2y, min(bpix1y, bpix3y)); 
  
   input.r = (rmid+rmidy)/2.0;
   input.g = (gmid+gmidy)/2.0;
   input.b = (bmid+bmidy)/2.0;

   return input;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (p_median1)
{
   return f_median (Input, uv1);
}

DeclarePass (p_median2)
{
   return f_median (p_median1, uv1);
}

DeclarePass (p_median3)
{
   return f_median (p_median2, uv1);
}

DeclareEntryPoint (NoiseReduction)
{
   float4 input  = ReadPixel (Input, uv1);
   float4 output = f_median  (p_median3, uv1);

   return lerp (input, output, ReadPixel (Mask, uv1).x * Amount);
}

