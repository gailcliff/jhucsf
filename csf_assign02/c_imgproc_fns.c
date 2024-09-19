// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include <stdio.h> // remove this
#include "imgproc.h"

// TODO: define your helper functions here

// Mirror input image horizontally.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_mirror_h( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement
  int width = input_img->width;
  int height = input_img->height;

  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) { 
        // Calculate the source and destination indices
        int src_index = row * width + col;
        int dst_index = row * width + (width - 1 - col);

        // Copy the pixel from source to destination
        output_img->data[dst_index] = input_img->data[src_index];
    }
  }
}

// Mirror input image vertically.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_mirror_v( struct Image *input_img, struct Image *output_img ) {
  // TODO: implement
  int width = input_img->width;
  int height = input_img->height;

  
  uint32_t temp;

    for (int col = 0; col < width; col++) {
      for (int row = 0; row < height; row++) {
        // Calculate the indices of the pixels to swap
        int src_index = row * width + col;
        int dst_index = (height - 1 - row) * width + col;

        // Swap the pixels
        output_img->data[dst_index] = input_img->data[src_index];
      }
    }  
}

// Transform image by generating a grid of n x n smaller tiles created by
// sampling every n'th pixel from the original image.
//
// Parameters:
//   input_img  - pointer to original struct Image
//   n          - tiling factor (how many rows and columns of tiles to generate)
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
// Returns:
//   1 if successful, or 0 if either
//     - n is less than 1, or
//     - the output can't be generated because at least one tile would
//       be empty (i.e., have 0 width or height)
// int imgproc_tile( struct Image *input_img, int n, struct Image *output_img ) {
//   // TODO: implement
//   return 0;
// }


int imgproc_tile(struct Image *input_img, int n, struct Image *output_img) {
    // Check for invalid input (n must be at least 1)
    if (n < 1) {
        return 0;
    }

    int input_width = input_img->width;
    int input_height = input_img->height;

    // Calculate the size of each tile
    int tile_width = input_width / n;
    int tile_height = input_height / n;

    // Ensure that tiles have non-zero dimensions
    if (tile_width == 0 || tile_height == 0) {
        return 0;
    }

    // Set output image dimensions
    output_img->width = tile_width * n;
    output_img->height = tile_height * n;

    // Loop over each tile
    for (int ty = 0; ty < n; ty++) {
        for (int tx = 0; tx < n; tx++) {
            // Loop over each pixel within the tile
            for (int y = 0; y < tile_height; y++) {
                for (int x = 0; x < tile_width; x++) {
                    // Calculate source and destination indices
                    int src_x = x;
                    int src_y = y;
                    int src_index = src_y * input_width + src_x;
                    
                    int dst_x = tx * tile_width + x;
                    int dst_y = ty * tile_height + y;
                    int dst_index = dst_y * (tile_width * n) + dst_x;

                    // Copy the pixel from source to destination
                    output_img->data[dst_index] = input_img->data[src_index];
                }
            }
        }
    }

    return 1; // Success
}

// Convert input pixels to grayscale.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_grayscale( struct Image *input_img, struct Image *output_img ) {
    // TODO: implement
    //for each pixel, apply a formula to the rgb values to determine the grayscale value
    for (int i = 0; i < input_img->width * input_img->height; i++) {
        // gray = (in.data[i].r + in.data[i].g + in.data[i].b)/3;
        uint32_t pixel = input_img->data[i];

        uint8_t r   = (pixel >> 24) & 0xFF; // Bits 24-31
        uint8_t g = (pixel >> 16) & 0xFF; // Bits 16-23
        uint8_t b  = (pixel >> 8)  & 0xFF; // Bits 8-15
        uint8_t a = pixel & 0xFF;

        uint8_t gray = (79*r + 128*g + 49*b)/256;

        output_img->data[i] = (gray << 24) | (gray << 16) | (gray << 8) | a;
        // i have no idea what the fuck is going on
    }
    // return out;
}

// Overlay a foreground image on a background image, using each foreground
// pixel's alpha value to determine its degree of opacity in order to blend
// it with the corresponding background pixel.
//
// Parameters:
//   base_img - pointer to base (background) image
//   overlay_img - pointer to overlaid (foreground) image
//   output_img - pointer to output Image
//
// Returns:
//   1 if successful, or 0 if the transformation fails because the base
//   and overlay image do not have the same dimensions
int imgproc_composite( struct Image *base_img, struct Image *overlay_img, struct Image *output_img ) {
  // TODO: implement

  //initialize variables
    int num_pixels = base_img->width * base_img->height;
    int num_pixels_b = overlay_img->width * overlay_img->height;

    if (num_pixels != num_pixels_b) {
      return 0;
    }
    
    //iterate through all pixels in the combined image, and calculate the resulting rgb value once overlayed
    for (int c = 0; c < num_pixels; c++) {
        //calculate the x and y value of the current pixel
        uint32_t bg_pixel = base_img->data[c];
        uint32_t fg_pixel = overlay_img->data[c];

        // background
        uint8_t bg_r   = (bg_pixel >> 24) & 0xFF; // Bits 24-31
        uint8_t bg_g = (bg_pixel >> 16) & 0xFF; // Bits 16-23
        uint8_t bg_b  = (bg_pixel >> 8)  & 0xFF; // Bits 8-15
        // uint8_t bg_a = bg_pixel & 0xFF;

        // foreground
        uint8_t fg_r   = (fg_pixel >> 24) & 0xFF; // Bits 24-31
        uint8_t fg_g = (fg_pixel >> 16) & 0xFF; // Bits 16-23
        uint8_t fg_b  = (fg_pixel >> 8)  & 0xFF; // Bits 8-15
        uint8_t fg_a = fg_pixel & 0xFF;

        uint8_t composite_r = ((fg_a * fg_r) + ((255 - fg_a) * bg_r)) / 255;
        uint8_t composite_g = ((fg_a * fg_g) + ((255 - fg_a) * bg_g)) / 255;
        uint8_t composite_b = ((fg_a * fg_b) + ((255 - fg_a) * bg_b)) / 255;
        uint8_t composite_a = 255;

        output_img->data[c] = (composite_r << 24) | (composite_g << 16) | (composite_b << 8) | composite_a;
    }
  return 1;
}
