// @Maintainer jwrl
// @Released 2024-08-30
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
// Modified 2024-08-30 Vision-victory.
// Fixed the found errors and changed the algorithm a little.
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
DeclareFloatParam( Step, "Step", kNoGroup, kNoFlags, 0.0, 0.0, 0.003 );

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 f_median (sampler2D sam, float2 uv)
{
   float rmid,gmid,bmid,rmidy,gmidy,bmidy;

   float4 input  = ReadPixel(sam, uv );
   
   float sas = (Step/_OutputAspectRatio);
   
   float inx2 = uv.x+(sas*2);
    if (inx2 > 1.0) inx2 = 2.0-inx2;
   float inx3 = uv.x-(sas*2);
    if (inx3 < 0.0) inx3 = abs(inx3); 
   float inx4 = uv.x+(sas*4);
    if (inx4 > 1.0) inx4 = 2.0-inx4;
   float inx5 = uv.x-(sas*4);
    if (inx5 < 1.0) inx5 = abs(inx5);
   
   float iny2 = uv.y+(Step*2);
    if (iny2 > 1.0) iny2 = 2.0-iny2;
   float iny3 = uv.y-(Step*2);
    if (iny3 < 0.0) iny3 = abs(iny3);
   float iny4 = uv.y+(Step*4);
    if (iny4 > 1.0) iny4 = 2.0-iny4;
   float iny5 = uv.y-(Step*4);
    if (iny5 < 0.0) iny5 = abs(iny5);
   
   float4 input2  = ReadPixel( sam, float2(inx2,uv.y) );
   float4 input3  = ReadPixel( sam, float2(inx3,uv.y) );
   float4 input4  = ReadPixel( sam, float2(inx4,uv.y) );
   float4 input5  = ReadPixel( sam, float2(inx5,uv.y) );
   
   float4 input2y  = ReadPixel( sam, float2(uv.x,iny2) );
   float4 input3y  = ReadPixel( sam, float2(uv.x,iny3) );
   float4 input4y  = ReadPixel( sam, float2(uv.x,iny4) );
   float4 input5y  = ReadPixel( sam, float2(uv.x,iny5) );
      
   float rpix1 = input.r;
   float rpix2 = input2.r;
   float rpix3 = input3.r;
   float rpix4 = input4.r;
   float rpix5 = input5.r;
   
   float rpix1y = input.r;
   float rpix2y = input2y.r;
   float rpix3y = input3y.r;
   float rpix4y = input4y.r;
   float rpix5y = input5y.r;
     
   if (max(rpix1, rpix2) == max(rpix2, rpix3)) rmid = max(rpix1, rpix3);
    else rmid = max(rpix2, min(rpix1, rpix3));
   if (max(rmid, rpix4) == max(rpix4, rpix5)) rmid = max(rmid, rpix5);
    else rmid = max(rpix4, min(rmid, rpix5)); 
    
   if (max(rpix1y, rpix2y) == max(rpix2y, rpix3y)) rmidy = max(rpix1y, rpix3y);
    else rmidy = max(rpix2y, min(rpix1y, rpix3y));
   if (max(rmidy, rpix4y) == max(rpix4y, rpix5y)) rmidy = max(rmidy, rpix5y);
    else rmidy = max(rpix4y, min(rmidy, rpix5y)); 
   
   float gpix1 = input.g;
   float gpix2 = input2.g;
   float gpix3 = input3.g;
   float gpix4 = input4.g;
   float gpix5 = input5.g;
   
   float gpix1y = input.g;
   float gpix2y = input2y.g;
   float gpix3y = input3y.g;
   float gpix4y = input4y.g;
   float gpix5y = input5y.g;
    
   if (max(gpix1, gpix2) == max(gpix2, gpix3)) gmid = max(gpix1, gpix3);
    else gmid = max(gpix2, min(gpix1, gpix3));
   if (max(gmid, gpix4) == max(gpix4, gpix5)) gmid = max(gmid, gpix5);
    else gmid = max(gpix4, min(gmid, gpix5));
    
   if (max(gpix1y, gpix2y) == max(gpix2y, gpix3y)) gmidy = max(gpix1y, gpix3y);
    else gmidy = max(gpix2y, min(gpix1y, gpix3y));
   if (max(gmidy, gpix4y) == max(gpix4y, gpix5y)) gmidy = max(gmidy, gpix5y);
    else gmidy = max(gpix4y, min(gmidy, gpix5y));  
   
   float bpix1 = input.b;
   float bpix2 = input2.b;
   float bpix3 = input3.b;
   float bpix4 = input4.b;
   float bpix5 = input5.b;
   
   float bpix1y = input.b;
   float bpix2y = input2y.b;
   float bpix3y = input3y.b;
   float bpix4y = input4y.b;
   float bpix5y = input5y.b;
   
   if (max(bpix1, bpix2) == max(bpix2, bpix3)) bmid = max(bpix1, bpix3);
    else bmid = max(bpix2, min(bpix1, bpix3));
   if (max(bmid, bpix4) == max(bpix4, bpix5)) bmid = max(bmid, bpix5);
    else bmid = max(bpix4, min(bmid, bpix5));
    
   if (max(bpix1y, bpix2y) == max(bpix2y, bpix3y)) bmidy = max(bpix1y, bpix3y);
    else bmidy = max(bpix2y, min(bpix1y, bpix3y)); 
   if (max(bmidy, bpix4y) == max(bpix4y, bpix5y)) bmidy = max(bmidy, bpix5y);
    else bmidy = max(bpix4y, min(bmidy, bpix5y));  
  
   input.r = (rmid+rmidy)/2;
   input.g = (gmid+gmidy)/2;
   input.b = (bmid+bmidy)/2;

   return input;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (p_median1)
{ return f_median (Input, uv1); }

DeclarePass (p_median2)
{ return f_median (p_median1, uv1); }

DeclarePass (p_median3)
{ return f_median (p_median2, uv1); }

DeclarePass (p_median4)
{ return f_median (p_median3, uv1); }

DeclarePass (p_median5)
{ return f_median (p_median4, uv1); }

DeclareEntryPoint (NoiseReduction)
{
   float4 input  = ReadPixel (Input, uv1);
   float4 output = f_median  (p_median5, uv1);

   return lerp (input, output, ReadPixel (Mask, uv1).x * Amount);
}
