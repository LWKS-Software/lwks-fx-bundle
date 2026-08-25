// @Maintainer jwrl
// @Released 2026-08-25
// @Author jwrl
// @Created 2022-06-23

/**
 Frame lock locks the frame size and aspect ratio of the image to that of the sequence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FrameLock.fx
//
// Version history:
//
// Updated 2026-08-25 jwrl.
// Removed redundant "_utils.fx" inclusion.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-11 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Frame lock", "User", "Technical", "This effect locks the frame size and aspect ratio of the image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FrameLock)
{ return ReadPixel (Input, uv1); }

