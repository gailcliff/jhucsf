#include <assert.h>
#include <stdlib.h>
#include <stdbool.h>
#include "tctest.h"
#include "imgproc.h"

// An expected color identified by a (non-zero) character code.
// Used in the "Picture" data type.
typedef struct {
  char c;
  uint32_t color;
} ExpectedColor;

// Type representing a "picture" of an expected image.
// Useful for creating a very simple Image to be accessed
// by test functions.
typedef struct {
  ExpectedColor colors[20];
  int width, height;
  const char *data;
} Picture;

// Some "basic" colors to use in test Pictures
#define TEST_COLORS \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0xFF0000FF }, \
      { 'g', 0x00FF00FF }, \
      { 'b', 0x0000FFFF }, \
      { 'c', 0x00FFFFFF }, \
      { 'm', 0xFF00FFFF }, \
    }

// Expected "basic" colors after grayscale transformation
#define TEST_COLORS_GRAYSCALE \
    { \
      { ' ', 0x000000FF }, \
      { 'r', 0x4E4E4EFF }, \
      { 'g', 0x7F7F7FFF }, \
      { 'b', 0x303030FF }, \
      { 'c', 0xB0B0B0FF }, \
      { 'm', 0x7F7F7FFF }, \
    }

// Colors for test overlay image (for testing the composite
// transformation). Has some fully-opaque colors,
// some partially-transparent colors, and a complete
// transparent color.
#define OVERLAY_COLORS \
  { \
    { 'r', 0xFF0000FF }, \
    { 'R', 0xFF000080 }, \
    { 'g', 0x00FF00FF }, \
    { 'G', 0x00FF0080 }, \
    { 'b', 0x0000FFFF }, \
    { 'B', 0x0000FF80 }, \
    { ' ', 0x00000000 }, \
  }

// Data type for the test fixture object.
// This contains data (including Image objects) that
// can be accessed by test functions. This is useful
// because multiple test functions can access the same
// data (so you don't need to create/initialize that
// data multiple times in different test functions.)
typedef struct {
  // smiley-face picture
  Picture smiley_pic;

  // original smiley-face Image object
  struct Image *smiley;

  // empty Image object to use for output of
  // transformation on smiley-face image
  struct Image *smiley_out;

  // Picture for overlay image (for basic imgproc_composite test)
  Picture overlay_pic;

  // overlay image object
  struct Image *overlay;
} TestObjs;

// Functions to create and clean up a test fixture object
TestObjs *setup( void );
void cleanup( TestObjs *objs );

// Helper functions used by the test code
struct Image *picture_to_img( const Picture *pic );
uint32_t lookup_color(char c, const ExpectedColor *colors);
bool images_equal( struct Image *a, struct Image *b );
void destroy_img( struct Image *img );

// Test functions
void test_mirror_h_basic( TestObjs *objs );
void test_mirror_v_basic( TestObjs *objs );
void test_tile_basic( TestObjs *objs );
void test_grayscale_basic( TestObjs *objs );
void test_composite_basic( TestObjs *objs );

// TODO: add prototypes for additional test functions
void test_custom_ceil(TestObjs *objs);
void test_custom_floor(TestObjs *objs);
void test_get_rgba(TestObjs *objs);
void test_get_r(TestObjs *objs);
void test_get_g(TestObjs *objs);
void test_get_b(TestObjs *objs);
void test_get_a(TestObjs *objs);
void test_make_pixel(TestObjs *objs);
void test_to_grayscale(TestObjs *objs);
void test_create_composite_pixel(TestObjs *objs);
// end prototypes for addition unit tests

int main( int argc, char **argv ) {
  // allow the specific test to execute to be specified as the
  // first command line argument
  if ( argc > 1 )
    tctest_testname_to_execute = argv[1];

  TEST_INIT();

  // Run tests.
  // Make sure you add additional TEST() macro invocations
  // for any additional test functions you add.
  TEST( test_mirror_h_basic );
  TEST( test_mirror_v_basic );
  TEST( test_tile_basic );
  TEST( test_grayscale_basic );
  TEST( test_composite_basic );

  // additinal TEST() invocations
  TEST(test_custom_ceil);
  TEST(test_custom_floor);
  TEST(test_get_rgba);
  TEST(test_get_r);
  TEST(test_get_g);
  TEST(test_get_b);
  TEST(test_get_a);
  TEST(test_make_pixel);
  TEST(test_to_grayscale);
  TEST(test_create_composite_pixel);

  TEST_FINI();
}

////////////////////////////////////////////////////////////////////////
// Test fixture setup/cleanup functions
////////////////////////////////////////////////////////////////////////

TestObjs *setup( void ) {
  TestObjs *objs = (TestObjs *) malloc( sizeof(TestObjs) );

  Picture smiley_pic = {
    TEST_COLORS,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };
  objs->smiley_pic = smiley_pic;
  objs->smiley = picture_to_img( &smiley_pic );

  objs->smiley_out = (struct Image *) malloc( sizeof( struct Image ) );
  img_init( objs->smiley_out, objs->smiley->width, objs->smiley->height );

  Picture overlay_pic = {
    OVERLAY_COLORS,
    16, 10,
   "                "
   "                "
   "                "
   "                "
   "                "
   "  rRgGbB        "
   "                "
   "                "
   "                "
   "                "
  };
  objs->overlay_pic = overlay_pic;
  objs->overlay = picture_to_img( &overlay_pic );

  return objs;
}

void cleanup( TestObjs *objs ) {
  destroy_img( objs->smiley );
  destroy_img( objs->smiley_out );
  destroy_img( objs->overlay );

  free( objs );
}

////////////////////////////////////////////////////////////////////////
// Test code helper functions
////////////////////////////////////////////////////////////////////////

struct Image *picture_to_img( const Picture *pic ) {
  struct Image *img;

  img = (struct Image *) malloc( sizeof(struct Image) );
  img_init( img, pic->width, pic->height );

  for ( int i = 0; i < pic->height; ++i ) {
    for ( int j = 0; j < pic->width; ++j ) {
      int index = i * img->width + j;
      uint32_t color = lookup_color( pic->data[index], pic->colors );
      img->data[index] = color;
    }
  }

  return img;
}

uint32_t lookup_color(char c, const ExpectedColor *colors) {
  for (int i = 0; ; i++) {
    assert(colors[i].c != 0);
    if (colors[i].c == c) {
      return colors[i].color;
    }
  }
}

// Returns true IFF both Image objects are identical
bool images_equal( struct Image *a, struct Image *b ) {
  if ( a->width != b->width || a->height != b->height )
    return false;

  int num_pixels = a->width * a->height;
  for ( int i = 0; i < num_pixels; ++i ) {
    if ( a->data[i] != b->data[i] )
      return false;
  }

  return true;
}

void destroy_img( struct Image *img ) {
  if ( img != NULL )
    img_cleanup( img );
  free( img );
}

////////////////////////////////////////////////////////////////////////
// Test functions
////////////////////////////////////////////////////////////////////////

void test_mirror_h_basic( TestObjs *objs ) {
  Picture smiley_mirror_h_pic = {
    TEST_COLORS,
    16, 10,
    "    cbggrrrm    "
    "   b        c   "
    "  c   b  r   r  "
    " b            b "
    " r            b "
    " r   c    b   g "
    "  b   brgg   c  "
    "   c        m   "
    "    cmbrrggg    "
    "                "
  };
  struct Image *smiley_mirror_h_expected = picture_to_img( &smiley_mirror_h_pic );

  imgproc_mirror_h( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_mirror_h_expected, objs->smiley_out ) );

  destroy_img( smiley_mirror_h_expected );
}

void test_mirror_v_basic( TestObjs *objs ) {
  Picture smiley_mirror_v_pic = {
    TEST_COLORS,
    16, 10,
    "                "
    "    gggrrbmc    "
    "   m        c   "
    "  c   ggrb   b  "
    " g   b    c   r "
    " b            r "
    " b            b "
    "  r   r  b   c  "
    "   c        b   "
    "    mrrrggbc    "
  };
  struct Image *smiley_mirror_v_expected = picture_to_img( &smiley_mirror_v_pic );

  imgproc_mirror_v( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_mirror_v_expected, objs->smiley_out ) );

  destroy_img( smiley_mirror_v_expected );
}

void test_tile_basic( TestObjs *objs ) {
  // implemented in milestone 3

  // Picture smiley_tile_3_pic = {
  //   TEST_COLORS,
  //   16, 10,
  //   "  rg    rg   rg "
  //   "                "
  //   "  gb    gb   gb "
  //   "                "
  //   "  rg    rg   rg "
  //   "                "
  //   "  gb    gb   gb "
  //   "  rg    rg   rg "
  //   "                "
  //   "  gb    gb   gb "
  // };
  // struct Image *smiley_tile_3_expected = picture_to_img( &smiley_tile_3_pic );

  // int success = imgproc_tile( objs->smiley, 3, objs->smiley_out );
  // ASSERT( success );
  // ASSERT( images_equal( smiley_tile_3_expected, objs->smiley_out ) );

  // destroy_img( smiley_tile_3_expected );
}

void test_grayscale_basic( TestObjs *objs ) {
  Picture smiley_grayscale_pic = {
    TEST_COLORS_GRAYSCALE,
    16, // width
    10, // height
    "    mrrrggbc    "
    "   c        b   "
    "  r   r  b   c  "
    " b            b "
    " b            r "
    " g   b    c   r "
    "  c   ggrb   b  "
    "   m        c   "
    "    gggrrbmc    "
    "                "
  };

  struct Image *smiley_grayscale_expected = picture_to_img( &smiley_grayscale_pic );

  imgproc_grayscale( objs->smiley, objs->smiley_out );

  ASSERT( images_equal( smiley_grayscale_expected, objs->smiley_out ) );

  destroy_img( smiley_grayscale_expected );
}

void test_composite_basic( TestObjs *objs ) {
  // implemented in milestone 3

  // imgproc_composite( objs->smiley, objs->overlay, objs->smiley_out );

  // // for all of the fully-transparent pixels in the overlay image,
  // // the result image should have a pixel identical to the corresponding
  // // pixel in the base image
  // for ( int i = 0; i < 160; ++i ) {
  //   if ( objs->overlay->data[i] == 0x00000000 )
  //     ASSERT( objs->smiley->data[i] == objs->smiley_out->data[i] );
  // }

  // // check the computed colors for the partially transparent or
  // // fully opaque colors in the overlay image
  // ASSERT( 0xFF0000FF == objs->smiley_out->data[82] );
  // ASSERT( 0x800000FF == objs->smiley_out->data[83] );
  // ASSERT( 0x00FF00FF == objs->smiley_out->data[84] );
  // ASSERT( 0x00807FFF == objs->smiley_out->data[85] );
  // ASSERT( 0x0000FFFF == objs->smiley_out->data[86] );
  // ASSERT( 0x000080FF == objs->smiley_out->data[87] );
}

// additional test functions

void test_custom_ceil(TestObjs *objs) {
  // ----- stub -----
  // milestone 3
}

void test_custom_floor(TestObjs *objs) {
  // ----- stub -----
  // milestone 3
}

void test_get_rgba(TestObjs *objs) {
  uint32_t pixel = 0x12345678;
  ASSERT(get_r(pixel) == 0x12);
  ASSERT(get_g(pixel) == 0x34);
  ASSERT(get_b(pixel) == 0x56);
  ASSERT(get_a(pixel) == 0x78);
}

void test_get_r(TestObjs *objs) {
    ASSERT(get_r(0xFF000000) == 0xFF);
    ASSERT(get_r(0x00FFFFFF) == 0x00);
    ASSERT(get_r(0x12345678) == 0x12);
    ASSERT(get_r(0x87654321) == 0x87);
    ASSERT(get_r(0xFFFFFFFF) == 0xFF);
    ASSERT(get_r(0x00000000) == 0x00);
    ASSERT(get_r(0x80808080) == 0x80);
}

void test_get_g(TestObjs *objs) {
    ASSERT(get_g(0x00FF0000) == 0xFF);
    ASSERT(get_g(0xFF00FFFF) == 0x00);
    ASSERT(get_g(0x12345678) == 0x34);
    ASSERT(get_g(0x87654321) == 0x65);
    ASSERT(get_g(0xFFFFFFFF) == 0xFF);
    ASSERT(get_g(0x00000000) == 0x00);
    ASSERT(get_g(0x80808080) == 0x80);
}

void test_get_b(TestObjs *objs) {
    ASSERT(get_b(0x0000FF00) == 0xFF);
    ASSERT(get_b(0xFFFF00FF) == 0x00);
    ASSERT(get_b(0x12345678) == 0x56);
    ASSERT(get_b(0x87654321) == 0x43);
    ASSERT(get_b(0xFFFFFFFF) == 0xFF);
    ASSERT(get_b(0x00000000) == 0x00);
    ASSERT(get_b(0x80808080) == 0x80);
}

void test_get_a(TestObjs *objs) {
    ASSERT(get_a(0x000000FF) == 0xFF);
    ASSERT(get_a(0xFFFFFF00) == 0x00);
    ASSERT(get_a(0x12345678) == 0x78);
    ASSERT(get_a(0x87654321) == 0x21);
    ASSERT(get_a(0xFFFFFFFF) == 0xFF);
    ASSERT(get_a(0x00000000) == 0x00);
    ASSERT(get_a(0x80808080) == 0x80);
}

void test_make_pixel(TestObjs *objs) {
  uint32_t pixel = make_pixel(0x12, 0x34, 0x56, 0x78);
  ASSERT(pixel == 0x12345678);

  // Test case 1: Standard RGBA values
    uint32_t pixel1 = make_pixel(100, 150, 200, 255);
    ASSERT(get_r(pixel1) == 100);
    ASSERT(get_g(pixel1) == 150);
    ASSERT(get_b(pixel1) == 200);
    ASSERT(get_a(pixel1) == 255);

    // Test case 2: All maximum values
    uint32_t pixel2 = make_pixel(255, 255, 255, 255);
    ASSERT(pixel2 == 0xFFFFFFFF);

    // Test case 3: All minimum values
    uint32_t pixel3 = make_pixel(0, 0, 0, 0);
    ASSERT(pixel3 == 0x00000000);

    // Test case 4: Mixed values
    uint32_t pixel4 = make_pixel(0x12, 0x34, 0x56, 0x78);
    ASSERT(pixel4 == 0x12345678);
}

void test_to_grayscale(TestObjs *objs) {
  uint32_t color_pixel = 0xFF8000FF; 
  uint32_t gray_pixel = to_grayscale(color_pixel);
  ASSERT(get_r(gray_pixel) == get_g(gray_pixel));
  ASSERT(get_g(gray_pixel) == get_b(gray_pixel));
  ASSERT(get_a(gray_pixel) == 0xFF);
  
  uint8_t expected_gray = (79*255 + 128*128 + 49*0) / 256;
  ASSERT(get_r(gray_pixel) == expected_gray);
}

void test_create_composite_pixel(TestObjs *objs) {
  // ----- stub -----
  // milestone 3
}