/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

// ----------------------- Begin helper functions -----------------------

/*
 * int custom_ceil(int numerator, int denominator);
 *
 * Returns the ceil value of dividing numerator and denominator
 *
 */
	.globl custom_ceil
custom_ceil:
	// MS3
	xorl %eax, %eax
	ret


/*
 * int custom_floor(int numerator, int denominator);
 *
 * Returns the floor value of dividing numerator and denominator
 *
 */
	.globl custom_floor
custom_floor:
	// MS3
	xorl %eax, %eax
	ret


/*
* uint32_t create_composite_pixel(uint32_t bg_pixel, uint32_t fg_pixel) {
* 
* Calculates the composite transformation of the foreground pixel and background pixel
* 
*/
	.globl create_composite_pixel
create_composite_pixel:
	// MS3
	xorl %eax, %eax
	ret

/*
 * uint32_t get_r( uint32_t pixel );
 *
 * Get red value from a pixel.
 *
 * Parameters:
 *   %edi - pixel
 *
 * Return red in %eax
 */
	.globl get_r
get_r:
	subq $8, %rsp // stack alignment

	movl %edi, %eax  // store pixel in return register rax
	shrl $24, %eax  // right shift 24 bits
	andl $0xFF, %eax  // bitwise %eax & 255

	addq $8, %rsp // stack alignment
	ret

/*
 * uint32_t get_g( uint32_t pixel );
 *
 * Get green value from a pixel.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Return green in %eax
 */
	.globl get_g
get_g:
	subq $8, %rsp // stack alignment

	movl %edi, %eax  // store pixel in return register rax
	shrl $16, %eax  // shift right 16 bits
	andl $0xFF, %eax  // bitwise %eax & 255

	addq $8, %rsp // stack alignment
	ret

/*
 * uint32_t get_b( uint32_t pixel );
 *
 * Get blue value from a pixel
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Return blue in %eax
 */
	.globl get_b
get_b:
	subq $8, %rsp // stack alignment

	movl %edi, %eax  // load pixel value into return register rax
	shrl $8, %eax  // shift right 8 bits
	andl $0xFF, %eax  // bitwise %eax & 255

	addq $8, %rsp // stack alignment
	ret

/*
 * uint32_t get_a( uint32_t pixel );
 *
 * Get the alpha value of a pixel
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Return alpha in %eax
 */
	.globl get_a
get_a:
	subq $8, %rsp // stack alignment

	movl %edi, %eax  // load pixel value into local variable
	andl $0xFF, %eax  // bitwise %eax & 255

	addq $8, %rsp // stack alignment
	ret

/*
 * uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a );
 *
 * Make a pixel from its rgba components.
 *
 * Parameters:
 *   %edi - red value
 *   %esi - green value
 *   %edx - blue value
 *   %ecx - alpha
 *
 * Return pixel value in %eax
 */
	.globl make_pixel
make_pixel:
	subq $8, %rsp // stack alignment

	movl %edi, %eax  // move red in return value
	shll $24, %eax  // shift red left 24 bits

	movl %esi, %r8d  // move green in temp
	shll $16, %r8d  // shift green left 16 bits
	orl %r8d, %eax  // or with result

	movl %edx, %r8d  // move blue in temp
	shll $8, %r8d  // shift blue left 8 bits
	orl %r8d, %eax  // or with result

	orl %ecx, %eax  // or alpha with result

	addq $8, %rsp // stack alignment
	ret

/*
 * uint32_t to_grayscale( uint32_t pixel);
 *
 * Transform pixel value to grayscale.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Return grayscale transformation in %eax
 */
	.globl to_grayscale
to_grayscale:
	subq $8, %rsp // stack alignment
	
	call get_r  // execute get_r function
	movl %eax, %esi // store result in esi

	call get_g  // execute get_g function function
	movl %eax, %edx // store result in ex

	call get_b  // execute get_b function
	movl %eax, %ecx // store result in ecx

	call get_a  // execute get_a function
	movl %eax, %r8d // store result in r8d


	// Calculate respective grayscale values of pixel components
	imull $79, %esi  // 79*r
	imull $128, %edx  // 128*g
	imull $49, %ecx  // 49*b
	addl %esi, %edx  // (79*r) + (128*g)
	addl %ecx, %edx  // (79*r) + (128*g) + (49 * blue)
	
	// divide by 256 by shifting right 8 bits
	shrl $8, %edx // (79*r + 128*g + 49 * blue) / 256

	// store grayscale pixel value and alpha to make pixel
	movl %edx, %edi  // r = gray
	movl %edx, %esi  // g = gray
	movl %edx, %edx  // b = gray
	movl %r8d, %ecx  // alpha value is preserved

	call make_pixel  // grayscale pixel is stored in rax after make_pixel returns

	addq $8, %rsp // stack alignment
	ret


// ----------------------- End helper functions -----------------------


/*
 * Implementations of API functions
 */

/*
 * void imgproc_mirror_h( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by mirroring its pixels horizontally.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_mirror_h
imgproc_mirror_h:
    subq $8, %rsp     // Stack alignment
	
	// save callee-saved registers
	pushq %rbx // variable for source index
	pushq %r12 // temporary variable for computation of mirror_h calculation
	pushq %r13 // variable for holding value at input_img->data[src_index] when copying to output_img

	movl IMAGE_WIDTH_OFFSET(%rdi), %edx // width
	movl IMAGE_HEIGHT_OFFSET(%rdi), %ecx // height
    
    movq IMAGE_DATA_OFFSET(%rdi), %r8    // input_img->data
    movq IMAGE_DATA_OFFSET(%rsi), %r9    // output-img->data

		movl $0, %r10d 					// set row counter to 0

	.LrowLoop_Mirror_h:
		cmpl %ecx, %r10d	// compare row >= height			
		jge .Lend_Mirror_h	// end loop if row >= height

		movl $0, %r11d					// set column counter to 0 for inner loop
	.LcolLoop_Mirror_h:
		cmpl %edx, %r11d              // compare column >= width
		jge .LnextRow_Mirror_h		// go to next iteration of outer loop if col >= width


		// calculation for the source index: row * width + column
		movl %r10d, %ebx             // get row
		imul %edx, %ebx          	 // row * width
		addl %r11d, %ebx             // row * width + column

		
		// calculation for the destination index: row * width + (width - 1 - col)
		
		// step 1. doing row * width
		movl %r10d, %eax            // get row
		imul %edx, %eax             // row * width
		
		// step 2. doing (width - 1 - col)
		movl %edx, %r12d             // get width
		decl %r12d                   // width - 1
		subl %r11d, %r12d            // width - 1 - column

		// destination index = result of step 1 + result of step 2
		addl %r12d, %eax             // row * width + (width - 1 - column)


		// output_img->data[dst_index] = input_img->data[src_index]
		movl (%r8, %rbx, 4), %r13d    // load from input_img
		movl %r13d, (%r9, %rax, 4)    // store in output_img



		incl %r11d                  // increment column
		jmp .LcolLoop_Mirror_h      // go to next iteration of inner loop

	.LnextRow_Mirror_h:
		incl %r10d                  // increment row
		jmp .LrowLoop_Mirror_h      // go to next iteration of outer loop



	.Lend_Mirror_h:
		popq %r13 // restore callee-saved registers
		popq %r12
		popq %rbx

		addq $8, %rsp // stack alignment
		ret


/*
 * void imgproc_mirror_v( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by mirroring its pixels vertically.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_mirror_v
imgproc_mirror_v:
    subq $8, %rsp   // stack alignment

	// callee-saved registers
	pushq %rbx // variable for source index
	pushq %r12 // variable for holding value at input_img->data[src_index] when copying to output_img

	movl IMAGE_WIDTH_OFFSET(%rdi), %edx // width
	movl IMAGE_HEIGHT_OFFSET(%rdi), %ecx // height
    
    movq IMAGE_DATA_OFFSET(%rdi), %r8    // input_img->data
    movq IMAGE_DATA_OFFSET(%rsi), %r9    // output-img->data

		movl $0, %r10d 		// set col counter to 0 for outer loop
	.LcolLoop_Mirror_v:
		cmpl %edx, %r10d	// compare col >= width
		jge .Lend_Mirror_v	// jump to end of function if col >= width


		movl $0, %r11d			// set row counter to 0 for inner loop
	.LrowLoop_Mirror_v:
		cmpl %ecx, %r11d            // compare row >= height
		jge .LnextCol_Mirror_v		// go to next iteration of outer loop if row >= height

		// calculation for the source index: row * width + column
		movl %r11d, %ebx             // get row
		imul %edx, %ebx          	 // row * width
		addl %r10d, %ebx             // row * width + column


		// calculation for the destination index: row * width + (width - 1 - col)
		
		// step 1. doing (height - 1 - col)
		movl %ecx, %eax             // get height
		decl %eax                   // height - 1
		subl %r11d, %eax            // height - 1 - row index

		// step 2. doing (height - 1 - col) * width
		imul %edx, %eax             // (height - 1 - row index) * width
		
		// adding step 1 and step 2
		addl %r10d, %eax			// (height - 1 - row index) * width + col

		// output_img->data[dst_index] = input_img->data[src_index]
		movl (%r8, %rbx, 4), %r12d    
		movl %r12d, (%r9, %rax, 4) 

		incl %r11d                  // increment row
		jmp .LrowLoop_Mirror_v      // go to next iteration of inner loop

	.LnextCol_Mirror_v:
		incl %r10d                  // increment column
		jmp .LcolLoop_Mirror_v      // go to next iteration of outer loop



	.Lend_Mirror_v:
		popq %r12 // restore callee-saved registers
		popq %rbx

		addq $8, %rsp // stack alignment
		ret // end imgproc_mirror_v

/*
 * void imgproc_grayscale( struct Image *input_img, struct Image *output_img );
 *
 * Transform image by converting each pixel to grayscale.
 * This transformation always succeeds.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %rsi - pointer to output struct Image
 */
	.globl imgproc_grayscale
imgproc_grayscale:
	subq $8, %rsp // stack alignment

	// save callee-saved registers
	pushq %r12 // for storing input_img->data
	pushq %r13 // for storing output_img->data
	pushq %r14 // loop counter

    movl IMAGE_WIDTH_OFFSET(%rdi), %r10d  // input_img->width
    movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d  // input_img->height
	movq IMAGE_DATA_OFFSET(%rdi), %r12  // input_img->data
    movq IMAGE_DATA_OFFSET(%rsi), %r13  // output_img->data

    imull %r10d, %r11d  // height * width (num pixels)
    
	movl $0, %r14d  // set loop counter to 0

	.LGrayScale_Loop:
		cmpl %r11d, %r14d // check if counter >= (width * height)
		jge .LGrayScale_End // r14d >= width * height, jump to end of function

		movl (%r12, %r14, 4), %edi // put pixel at current source index in edi register for the to_grayscale function
		call to_grayscale  // Transform pixel at current index in input_img->data to grayscale

		movl %eax, (%r13, %r14, 4)  // Get returned pixel from %eax and store in output_img->data

		incl %r14d  // increment the counter
		jmp .LGrayScale_Loop  // go to next iteration of loop



	.LGrayScale_End:
		popq %r14 // restore callee-saved registers
		popq %r13
		popq %r12

		addq $8, %rsp // stack alignment
		ret

/*
 * int imgproc_tile( struct Image *input_img, int n, struct Image *output_img );
 *
 * Transform image by generating a grid of n x n smaller tiles created by
 * sampling every n'th pixel from the original image.
 *
 * Parameters:
 *   %rdi - pointer to original struct Image
 *   %esi - tiling factor (how many rows and columns of tiles to generate)
 *   %rdx - pointer to the output Image (in which the transformed
 *          pixels should be stored)
 *
 * Returns (in %eax):
 *   1 if successful, or 0 if either
 *     - n is less than 1, or
 *     - the output can't be generated because at least one tile would
 *       be empty (i.e., have 0 width or height)
 */
	.globl imgproc_tile
imgproc_tile:
	/* TODO: implement (this stub implementation just returns 0) */
	xorl %eax, %eax
	ret

/*
 * int imgproc_composite( struct Image *base_img, struct Image *overlay_img );
 *
 * Overlay a foreground image on a background image, using each foreground
 * pixel's alpha value to determine its degree of opacity in order to blend
 * it with the corresponding background pixel.
 *
 * Parameters:
 *   %rdi - pointer to base (background) image
 *   %rsi - pointer to overlaid (foreground) image
 *   %rdx - pointer to output Image
 *
 * Returns:
 *   1 if successful, or 0 if the transformation fails because the base
 *   and overlay image do not have the same dimensions
 */
	.globl imgproc_composite
imgproc_composite:
	/* TODO: implement (this stub implementation just returns 0) */
	subq $8, %rsp
	
	subq $8, %rsp
	ret

/*
vim:ft=gas:
*/
