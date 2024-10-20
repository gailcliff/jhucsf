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
	.globl custom_ceil // helper function for tile function
custom_ceil:
	addl %esi, %edi
	subl $1, %edi

	// calculate ceiling of division of %edi / %esi

	movl %edi, %eax 	// dividend
	xorl %edx, %edx
	movl %esi, %ecx		// divisor
	divl %ecx			// divide

	// result of ceiling is implicitly set in %eax by divl
	ret


/*
 * int custom_floor(int numerator, int denominator);
 *
 * Returns the floor value of dividing numerator and denominator
 *
 */
	.globl custom_floor // helper function for tile function
custom_floor:

	// calculate floor of division of %edi / %esi

	movl %edi, %eax 	// dividend
	xorl %edx, %edx
	movl %esi, %ecx 	// divisor
	divl %ecx 			// divide

	// result of floor is implicitly set in %eax by divl
	ret


/*
* uint32_t create_composite_pixel(uint32_t bg_pixel, uint32_t fg_pixel) {
* 
* Calculates the composite transformation of the foreground pixel and background pixel
* 
*/
	.globl create_composite_pixel
create_composite_pixel:
	pushq %rbp
	movq %rsp, %rbp

	subq $32, %rsp 					// allocate space for variables in memory

	call get_r						// get r component of background image
	movl %eax, -32(%rbp) 			// background r
	call get_g						// get g component of background image
	movl %eax, -28(%rbp)		 	// background g
	call get_b						// get b component of background image
	movl %eax, -24(%rbp) 			// background b

	movl %esi, %edi

	call get_r					// get r component of foreground image
	movl %eax, -20(%rbp) 		// foreground r
	call get_g 					// get g component of foreground image
	movl %eax, -16(%rbp) 		// foreground g
	call get_b 					// get b component of foreground image
	movl %eax, -12(%rbp) 		// foreground b
	call get_a 					// get a component of background image
	movl %eax, -8(%rbp) 		// foreground a

	// calculating composite r
	movl -8(%rbp), %r8d 		// fg_a
	imull -20(%rbp), %r8d 		// fg_a * fg_r
	movl $255, %r9d				// move 255 into register for calculation
	subl -8(%rbp), %r9d 		// 255 - fg_a
	imull -32(%rbp), %r9d 		// (255 - fg_a) * bg_r
	addl %r8d, %r9d 			// (fg_a * fg_r) + ((255 - fg_a) * bg_r)

	// division by 255
	movl %r9d, %eax 			// dividend is (fg_a * fg_r) + ((255 - fg_a) * bg_r)
	xorl %edx, %edx 			// edx register is used in division
	movl $255, %ecx 			// divisor is 255
	divl %ecx 					// divide
	movl %eax, -20(%rbp) 		// after division by 255, composite value of r is returned in eax. store it in memory


	// calculating composite g
	movl -8(%rbp), %r8d 		// fg_a
	imull -16(%rbp), %r8d 		// fg_a * fg_g
	movl $255, %r9d 			// move 255 into register for calculation
	subl -8(%rbp), %r9d 		// 255 - fg_a
	imull -28(%rbp), %r9d 		// (255 - fg_a) * bg_g
	addl %r8d, %r9d 			// (fg_a * fg_g) + ((255 - fg_a) * bg_g)

	// division by 255
	movl %r9d, %eax				// dividend is (fg_a * fg_g) + ((255 - fg_a) * bg_g)
	xorl %edx, %edx				// edx register is used in division
	movl $255, %ecx 			// divisor is 255
	divl %ecx 					// divide
	movl %eax, -16(%rbp) 		// after division by 255, composite value of g is returned in eax. store it in memory


	// calculating composite b
	movl -8(%rbp), %r8d 		// fg_a
	imull -12(%rbp), %r8d 		// fg_a * fg_b
	movl $255, %r9d 			// move 255 into register for calculation
	subl -8(%rbp), %r9d 		// 255 - fg_a
	imull -24(%rbp), %r9d 		// (255 - fg_a) * bg_b
	addl %r8d, %r9d 			// (fg_a * fg_g) + ((255 - fg_a) * bg_b)

	// division by 255
	movl %r9d, %eax 			// dividend is (fg_a * fg_g) + ((255 - fg_a) * bg_b)
	xorl %edx, %edx				// edx register is used for division
	movl $255, %ecx 			// divisor is 255
	divl %ecx 					// divide
	movl %eax, -12(%rbp) 		// after division by 255, composite value of b is returned in eax. store it in memory

	movl $255, -8(%rbp) 		// the composite value of the a component is just 255. store it in memory


	// making pixel
	movl -20(%rbp), %edi		// r component of composite pixel
	movl -16(%rbp), %esi		// g component of composite pixel
	movl -12(%rbp), %edx		// b component of composite pixel
	movl -8(%rbp), %ecx			// a component of composite pixel

	call make_pixel				 // the returned pixel will be stored in eax in the make_pixel function

	addq $32, %rsp				// deallocate memory by adding to rsp

	popq %rbp					// restore value of rbp
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
	addl %ecx, %edx  // (79*r) + (128*g) + (49*b)
	
	// divide by 256 by shifting right 8 bits
	shrl $8, %edx // (79*r + 128*g + 49 * b) / 256

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
		cmpl %edx, %r11d              	// compare column >= width
		jge .LnextRow_Mirror_h			// go to next iteration of outer loop if col >= width


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

		movl $0, %r10d 					// set col counter to 0 for outer loop
	.LcolLoop_Mirror_v:
		cmpl %edx, %r10d				// compare col >= width
		jge .Lend_Mirror_v				// jump to end of function if col >= width


		movl $0, %r11d					// set row counter to 0 for inner loop
	.LrowLoop_Mirror_v:
		cmpl %ecx, %r11d            	// compare row >= height
		jge .LnextCol_Mirror_v			// go to next iteration of outer loop if row >= height

		// calculation for the source index: row * width + column
		movl %r11d, %ebx             	// get row
		imul %edx, %ebx          	 	// row * width
		addl %r10d, %ebx             	// row * width + column


		// calculation for the destination index: row * width + (width - 1 - col)
		
		// step 1. doing (height - 1 - col)
		movl %ecx, %eax             		// get height
		decl %eax                   		// height - 1
		subl %r11d, %eax            		// height - 1 - row index

		// step 2. doing (height - 1 - col) * width
		imul %edx, %eax             		// (height - 1 - row index) * width
		
		// adding step 1 and step 2
		addl %r10d, %eax					// (height - 1 - row index) * width + col

		// output_img->data[dst_index] = input_img->data[src_index]
		movl (%r8, %rbx, 4), %r12d    
		movl %r12d, (%r9, %rax, 4) 

		incl %r11d                  	// increment row
		jmp .LrowLoop_Mirror_v      	// go to next iteration of inner loop

	.LnextCol_Mirror_v:
		incl %r10d                  	// increment column
		jmp .LcolLoop_Mirror_v      	// go to next iteration of outer loop



	.Lend_Mirror_v:
		popq %r12 					// restore callee-saved registers
		popq %rbx					// restore

		addq $8, %rsp				// stack alignment
		ret 						// end imgproc_mirror_v

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
	pushq %r12 									// for storing input_img->data
	pushq %r13 									// for storing output_img->data
	pushq %r14 									// loop counter

    movl IMAGE_WIDTH_OFFSET(%rdi), %r10d  		// input_img->width
    movl IMAGE_HEIGHT_OFFSET(%rdi), %r11d  		// input_img->height
	movq IMAGE_DATA_OFFSET(%rdi), %r12  		// input_img->data
    movq IMAGE_DATA_OFFSET(%rsi), %r13  		// output_img->data

    imull %r10d, %r11d  						// height * width (num pixels)
    
	movl $0, %r14d  							// set loop counter to 0

	.LGrayScale_Loop:
		cmpl %r11d, %r14d 						// check if counter >= (width * height)
		jge .LGrayScale_End 					// r14d >= width * height, jump to end of function

		movl (%r12, %r14, 4), %edi 				// put pixel at current source index in edi register for the to_grayscale function
		call to_grayscale  						// Transform pixel at current index in input_img->data to grayscale

		movl %eax, (%r13, %r14, 4)  			// Get returned pixel from %eax and store in output_img->data

		incl %r14d  							// increment the counter
		jmp .LGrayScale_Loop  					// go to next iteration of loop



	.LGrayScale_End:
		popq %r14 // restore callee-saved registers
		popq %r13
		popq %r12

		addq $8, %rsp // stack alignment
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
	subq $8, %rsp // stack alignment

	movq IMAGE_DATA_OFFSET(%rdi), %r10 			// base_img->data
	movq IMAGE_DATA_OFFSET(%rsi), %r11 			// overlay_img->data
	movq IMAGE_DATA_OFFSET(%rdx), %r15 			// output_img->data

	movl IMAGE_WIDTH_OFFSET(%rdi), %r12d 		// width of base_img
	imull IMAGE_HEIGHT_OFFSET(%rdi), %r12d 		// multiply by height of base_img to get number of pixels

	movl IMAGE_WIDTH_OFFSET(%rsi), %r13d 		// width of overlay_img
	imull IMAGE_HEIGHT_OFFSET(%rsi), %r13d  	// multiply by height of base_img to get number of pixels

	movl $0, %eax 								// set 0 as tentative value. if no. of pixels doesn't match, 0 (failure) is returned at end of function
	cmpl %r12d, %r13d 							// compare number of pixels of base image to number of pixels of overlay image
	jne .LEnd_Composite							// if number of pixels doesn't match, go to end of function, with return value 0 in eax



	movl $0, %r13d 								// loop counter variable. overwrite r13d because we don't need it's previous value anymore

	.LComposite_Loop:
		cmpl %r12d, %r13d 						// check if counter >= number of pixels
		jge .LSet_Success_Code 					// if >= then all pixels have been transformed. set success code (return value) to 1
		
		movl (%r10, %r13, 4), %edi			 	// get pixel of background image at current index
		movl (%r11, %r13, 4), %esi 				// get pixel of foreground image at current index

		call create_composite_pixel 			// call the create_composite_pixel function to do the transformation

		movl %eax, (%r15, %r13, 4)			 	// copy the transformed composite pixel to the output image
 
		incl %r13d 								// increment the loop counter

		jmp .LComposite_Loop 					// go to next iteration of loop

	.LSet_Success_Code: 						// when we jump to this label, we set the return value in eax to 1 to indicate success of function
		movl $1, %eax 							// set return value to 1 (successful)
	


	.LEnd_Composite: 
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
	pushq %rbp
	movq %rsp, %rbp
	
	movl $0, %eax							// put return value of 0, in %eax. if the function fails, 0 will be returned
	
	cmpl $1, %esi							// check if no. of tiles < 1
	jl .LTile_End							// if no. of tiles < 1, end function

	movl IMAGE_WIDTH_OFFSET(%rdi), %r15d 	// input_img->width
	movl IMAGE_HEIGHT_OFFSET(%rdi), %r14d 	// input_img->height
	movq IMAGE_DATA_OFFSET(%rdi), %r13 		// input_img->data
	movq IMAGE_DATA_OFFSET(%rdx), %r12 		// output_img->data
	movl %esi, %r11d 						// n
	movq %rdx, %r9 							// output_img
	movq %rdi, %r8 							// input_img

	// set input width and input height of output image
	movl %r15d, IMAGE_WIDTH_OFFSET(%rdx)	// set input width
	movl %r14d, IMAGE_HEIGHT_OFFSET(%rdx)	// set input height

	movl $0, %edx							// clear the value in edx

	// calculate tile width
	movl %r15d, %eax 						// input width
	xorl %edx, %edx							// edx is used by divl for division
	movl %r11d, %ecx						// n
	divl %ecx 								// divide by n to get tile width
	movl %eax, %r10d 						// tile width is the result. store in r10d

	// calculate tile height
	movl %r14d, %eax 						// input height
	xorl %edx, %edx							// edx is used by divl for division
	movl %r11d, %ecx 						// n
	divl %ecx 								// divide by n to get tile height
	movl %eax, %r9d 						// tile height is the result. store in r9d


	cmpl $0, %r10d 							// check if tile width == 0
	jz .LTile_End 							// if tile width == 0, end the function and return 0
	cmpl $0, %r9d							// check if tile height == 0
	jz .LTile_End							// if tile height == 0, end the function and return 0]

	/*

	.Lprocess_Tiles_Loop:
    	// This loop creates tiles and puts them on the grid.
		// Calculate the width and height of each tile.
		// Some tiles might need adjustment of height and width to fit on the grid

		// The 'custom_ceil' and 'custom_floor' helper functions are used to adjust the dimensions of tiles in cases where
		// the dimensions of the input image are not evenly divisible by n (the no. of tiles)

		// Create loops to process tiles.
		// Allocate memory for tiles and place them on grid

		.LinnerTile_Loop: 	// there will be multiple inner nested loops below this
			// other inner loops
    	
			call malloc		// allocate space in memory for tiles
			
			.....			// place tiles on grid

			call free		// deallocate memory for tiles

			jmp .LinnerTile_Loop

	.Lprocess_Tiles_Loop_End:
		jmp .LSet_Success_Code			// after tiling image, jump to this label to set return value in rax to 1
	*/

	.LTile_Success_Code: 				// when we jump to this label, we set the return value in eax to 1 to indicate success of function
		movl $1, %eax 					// set return value to 1 (successful)
	
	
   	.LTile_End:
		popq %rbp 						// restore value of %rbp
		ret

/*
vim:ft=gas:
*/
