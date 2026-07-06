// @Maintainer jwrl
// @Released 2026-07-06
// @Author jwrl
// @Created 2019-04-10

/**
 As the name says, this is a lightning flash effect.  The number of flash cycles can be
 adjusted from one to five and the flash duration can be set from one to three frames.
 A colour cast can be added to the flash - blue for high energy, purple for even higher
 energy would probably be good - and the duration of the fade back to normal can be set
 from two to thirty frames.  Although decimal numbers of frames can be entered they will
 always round to the nearest available whole number.

   [*]Number of flash cycles:  This sets the number of repeated flashes in a single
      lightning flash sequence.  It can range from one to five.
   [*]Duration of flashes:  The duration of individual flashes in a flash sequence
      can be from 1 to 3 frames.
   [*]Fade (frames):  The fade out (decay) of an individual flash can range from 2 to
      30 frames.  Longer is NOT better.
   [*]Colour cast:  The flash colour.  The default is a very light blue.

 This is not designed as a transition so it is up to the user to ensure that there is
 room for the effect to function fully.  The required duration will be double the number
 of flashes times the flash duration plus the fade duration minus one.  For example,
 three one frame flashes with a fade duration of six frames will need eleven frames to
 fully function.  Once the flash sequence fade ends it will not affect the image further
 and can be left in place.  Then the next time that you need a flash just press the C
 key to force a cut in the timeline and you'll have a fresh bolt of Lightning.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LightningFlash.fx
//
// Version history:
//
// Updated 2026-07-06 jwrl.
// Changed "Fade (in frames)" to "Fade (frames)".
// Rewrote header block.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Lightning flash", "Stylize", "Special Effects", "Simulates a high energy lightning flash at the cut point", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (FlashCycle,    "Number of flash cycles", kNoGroup, 2, "1 flash|2 flashes|3 flashes|4 flashes|5 flashes");
DeclareIntParam (FlashDuration, "Duration of flashes",    kNoGroup, 0, "1 frame|2 frames|3 frames");

DeclareFloatParam (FadeAmount,  "Fade (frames)",          kNoGroup, kNoFlags, 6.0, 2.0, 30.0);
DeclareColourParam (ColourCast, "Colour cast",            kNoGroup, kNoFlags, 0.33, 0.67, 1.0, 1.0);

DeclareFloatParam (_LengthFrames);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (LightningFlash)
{
   float4 video = ReadPixel (Inp, uv1);
   float4 flash = float4 ((ColourCast.rgb * 0.2) + 0.8.xxx, 1.0);
   float4 ngtve = float4 (flash.rgb - pow ((video.r + video.g + video.b) / 3.0, 1.5).xxx, 1.0);

   float frame = floor ((_LengthFrames * _Progress) + 0.5);
   float durtn = FlashDuration + 1.0;
   float cycle = (FlashCycle * (durtn * 2.0)) + durtn;

   if (cycle > frame) {
      frame = floor (frame / durtn);

      return ((floor (frame / 2.0) * 2.0) == frame) ? flash : ngtve;
   }

   float fade = saturate ((frame - cycle) / floor (FadeAmount + 0.5));

   return lerp (ngtve, video, fade);
}
