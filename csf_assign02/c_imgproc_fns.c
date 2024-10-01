// c_imgproc_fns.c

// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"

// TODO: define your helper functions here
// Custom ceiling function
int custom_ceil(int numerator, int denominator) {
    return (numerator + denominator - 1) / denominator;
}

// Custom floor function
int custom_floor(int numerator, int denominator) {
    return numerator / denominator;
}

uint32_t get_r( uint32_t pixel ) {
    return (pixel >> 24) & 0xFF;
}
uint32_t get_g( uint32_t pixel ) {
    return (pixel >> 16) & 0xFF;
}
uint32_t get_b( uint32_t pixel ) {
    return (pixel >> 8)  & 0xFF;
}
uint32_t get_a( uint32_t pixel ) {
    return pixel & 0xFF;
}

uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a ) {
    return (r << 24) | (g << 16) | (b << 8) | a;
}

uint32_t create_composite_pixel(uint32_t bg_pixel, uint32_t fg_pixel) {
    // background
    uint8_t bg_r   = get_r(bg_pixel);
    uint8_t bg_g = get_g(bg_pixel); 
    uint8_t bg_b  = get_b(bg_pixel);

    // foreground
    uint8_t fg_r   = get_r(fg_pixel); 
    uint8_t fg_g = get_g(fg_pixel); 
    uint8_t fg_b  = get_b(fg_pixel); 
    uint8_t fg_a = get_a(fg_pixel);

    uint8_t composite_r = ((fg_a * fg_r) + ((255 - fg_a) * bg_r)) / 255;
    uint8_t composite_g = ((fg_a * fg_g) + ((255 - fg_a) * bg_g)) / 255;
    uint8_t composite_b = ((fg_a * fg_b) + ((255 - fg_a) * bg_b)) / 255;
    uint8_t composite_a = 255;

    return make_pixel(composite_r, composite_g, composite_b, composite_a);
}

uint32_t to_grayscale(uint32_t pixel) {
    uint8_t r   = get_r(pixel);
    uint8_t g = get_g(pixel);   
    uint8_t b  = get_b(pixel);
    uint8_t a = get_a(pixel);

    uint8_t gray = (79*r + 128*g + 49*b) / 256;

    return make_pixel(gray, gray, gray, a);
}

// end helper functions

// Mirror input image horizontally.
// This transformation always succeeds.
//
// Parameters:
//   input_img  - pointer to the input Image
//   output_img - pointer to the output Image (in which the transformed
//                pixels should be stored)
void imgproc_mirror_h( struct Image *input_img, struct Image *output_img ) {
  int width = input_img->width;
  int height = input_img->height;

  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) { 

        int src_index = row * width + col;
        int dst_index = row * width + (width - 1 - col);

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

  int width = input_img->width;
  int height = input_img->height;

  
    for (int col = 0; col < width; col++) {
      for (int row = 0; row < height; row++) {
        
        int src_index = row * width + col;
        int dst_index = (height - 1 - row) * width + col;

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

    int tile_width = input_width / n;
    int tile_height = input_height / n;
    
    // Ensure that tiles have non-zero dimensions
    if (tile_width == 0 || tile_height == 0) {
        return 0;
    }

    // Set output image dimensions
    output_img->width = input_width;
    output_img->height = input_height;

    // if the dimensions are not divisible by n, then the dimensions 
    // of some tiles will be bigger than others

    int ceil_w = custom_ceil(input_width, n);
    int floor_w = custom_floor(input_width, n);
    int ceil_h = custom_ceil(input_height, n);
    int floor_h = custom_floor(input_height, n);
    
    // Calculate the number of tiles out of 'n' along 
    // both the width and height that will be bigger in dimension
    // (this matters in the case where the dimensions are not divisible by 'n')
    int num_ceil_w = input_width - (floor_w * n);
    int num_ceil_h = input_height - (floor_h * n);
    
    // store the dimensions of tiles along the width
    // and height
    // e.g [267, 267, 266] for widths and [200, 200, 200] for heights
    int widths[n];
    int heights[n];
    
    // Fill each dimension array with respective dimensions.
    // widths
    for (int i = 0; i < num_ceil_w; i++) {
        widths[i] = ceil_w;
    }
    for (int i = num_ceil_w; i < n; i++) {
        widths[i] = floor_w;
    }

    // heights
    for (int i = 0; i < num_ceil_h; i++) {
        heights[i] = ceil_h;
    }
    for (int i = num_ceil_h; i < n; i++) {
        heights[i] = floor_h;
    }


    int totalHeightTraversed = 0;

    for(int i = 0; i < n; i++) {
        
        int widthTraversedAtCurrentEpoch = 0;

        for (int j = 0; j < n; j++) {
            // create each tile and place it on the grid
            uint32_t* scaledTile = (uint32_t*) malloc(heights[i] * widths[j] * sizeof(uint32_t));

            if (scaledTile == NULL) {
                exit(1);  // Memory allocation failed
            }

            for (int y = 0; y < heights[i]; y++) {
                for (int x = 0; x < widths[j]; x++) {
                    int originalX = x * n;
                    int originalY = y * n;
                    scaledTile[y * widths[j] + x] = input_img->data[originalY * input_img->width + originalX];
                }
            } // tile has been fully created, now place it on the grid

            // move tile onto grid
            for (int y = 0; y < heights[i]; y++) {
                for (int x = 0; x < widths[j]; x++) {
                    int destX = widthTraversedAtCurrentEpoch + x;
                    int destY = totalHeightTraversed + y;
                    output_img->data[destY * output_img->width + destX] = scaledTile[y * widths[j] + x];
                }
                
            } 
            widthTraversedAtCurrentEpoch += widths[j];
            
            free(scaledTile);
        }
        totalHeightTraversed += heights[i];
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
    for (int i = 0; i < input_img->width * input_img->height; i++) {
        
        uint32_t pixel = input_img->data[i];

        output_img->data[i] = to_grayscale(pixel);
    }
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

    int num_pixels = base_img->width * base_img->height;
    int num_pixels_b = overlay_img->width * overlay_img->height;

    if (num_pixels != num_pixels_b) {
      return 0;
    }
    
    for (int c = 0; c < num_pixels; c++) { 
        uint32_t bg_pixel = base_img->data[c];
        uint32_t fg_pixel = overlay_img->data[c];

        output_img->data[c] = create_composite_pixel(bg_pixel, fg_pixel);
    }
  return 1;
}
