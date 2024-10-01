/*
 * x86-64 assembly language implementations of functions
 */

	.section .text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

/*
 * uint32_t get_r( uint32_t pixel );
 *
 * Extracts the red component of a pixel.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   extracted red color component
 */
	.globl get_r
get_r:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	pushq %rbx  // callee-saved register for local variable

	movl %edi, %ebx  // load pixel value into local variable
	shrl $24, %ebx  // shift right 24 bits to get red component
	andl $0xFF, %ebx  // and with 255
	movl %ebx, %eax  // move result into return value

	/* epilogue */
	popq %rbx  // restore callee-saved register
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t get_g( uint32_t pixel );
 *
 * Extracts the green component of a pixel.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   extracted green color component
 */
	.globl get_g
get_g:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	pushq %rbx  // callee-saved register for local variable

	movl %edi, %ebx  // load pixel value into local variable
	shrl $16, %ebx  // shift right 16 bits to get green component
	andl $0xFF, %ebx  // and with 255
	movl %ebx, %eax  // move result into return value

	/* epilogue */
	popq %rbx  // restore callee-saved register
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t get_b( uint32_t pixel );
 *
 * Extracts the blue component of a pixel.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   extracted blue color component
 */
	.globl get_b
get_b:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	pushq %rbx  // callee-saved register for local variable

	movl %edi, %ebx  // load pixel value into local variable
	shrl $8, %ebx  // shift right 8 bits to get blue component
	andl $0xFF, %ebx  // and with 255
	movl %ebx, %eax  // move result into return value

	/* epilogue */
	popq %rbx  // restore callee-saved register
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t get_a( uint32_t pixel );
 *
 * Extracts the alpha component of a pixel.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   extracted alpha component
 */
	.globl get_a
get_a:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	pushq %rbx  // callee-saved register for local variable

	movl %edi, %ebx  // load pixel value into local variable
	andl $0xFF, %ebx  // and with 255
	movl %ebx, %eax  // load alpha value into return value

	/* epilogue */
	popq %rbx  // restore callee-saved register
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a );
 *
 * Creates a new pixel based on the passed r, g, b, a components.
 *
 * Parameters:
 *   %edi - the red component
 *   %esi - the green component
 *   %edx - the blue component
 *   %ecx - the alpha component
 *
 * Returns:
 *   the newly created pixel value
 */
	.globl make_pixel
make_pixel:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	pushq %rbx  // callee-saved register for local variable

	movl %edi, %ebx  // move red in return value
	shll $24, %ebx  // shift red left 24 bits

	movl %esi, %r8d  // move green in temp
	shll $16, %r8d  // shift green left 16 bits
	orl %r8d, %ebx  // or with result

	movl %edx, %r8d  // move blue in temp
	shll $8, %r8d  // shift blue left 8 bits
	orl %r8d, %ebx  // or with result

	orl %ecx, %ebx  // or alpha with result
	movl %ebx, %eax  // store pixel in return value

	/* epilogue */
	popq %rbx  // restore callee-saved register
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t to_grayscale( uint32_t pixel);
 *
 * Converts pixel value to grayscale.
 *
 * Parameters:
 *   %edi - pixel value
 *
 * Returns:
 *   the grayscale equivalent of the pixel
 */
	.globl to_grayscale
to_grayscale:
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	
	call get_r  // get red value in pixel
	movl %eax, %esi // store returned red value
	call get_g  // get green value in pixel
	movl %eax, %edx // store returned green value
	call get_b  // get blue value in pixel
	movl %eax, %ecx // store returned blue value
	call get_a  // get alpha value in pixel
	movl %eax, %r8d // store returned alpha value

	// calculate grayscale pixel value using formula
	imull $79, %esi  // 79 * red
	imull $128, %edx  // 128 * green
	imull $49, %ecx  // 49 * blue
	addl %esi, %edx  // (79 * red) + (128 * green)
	addl %ecx, %edx  // result above + (49 * blue)

	shrl $8, %edx  // divide result of addition by 256

	// store grayscale pixel value and alpha to make pixel
	movl %edx, %edi  // set red param to gray value
	movl %edx, %esi  // set green param to gray value
	movl %edx, %edx  // set blue param to gray value
	movl %r8d, %ecx  // set alpha value to original value
	call make_pixel  // make pixel with params


	/* epilogue */
	addq $8, %rsp
	popq %rbp
	ret

/*
 * uint32_t blend_components( uint32_t fg, uint32_t bg, uint32_t alpha );
 *
 * Blend two color components based on the alpha values.
 *
 * Parameters:
 *   %edi - foreground pixel value
 *   %esi - background pixel value
 *   %edx - alpha value determining the blending
 *
 * Returns:
 *   the blended pixel value
 */
	.globl blend_components
blend_components:
	// implemented in MS 3
	ret

/*
 * uint32_t blend_colors( uint32_t fg, uint32_t bg );
 *
 * Blend foreground and background pixel values.
 *
 * Parameters:
 *   %edi - foreground pixel to be processed
 *   %esi - background pixel to be processed
 *
 * Returns:
 *   the blended pixel value
 */
	.globl blend_colors
blend_colors:
	// implemented in MS 3
	ret

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
    subq $8, %rsp                // Align the stack

    movq %rdi, %r8               // r8 = input_img
    movq %rsi, %r9               // r9 = output_img

    // Get height and width from input_img
    movl IMAGE_HEIGHT_OFFSET(%r8), %eax  // %eax = input_img->height
    movl IMAGE_WIDTH_OFFSET(%r8), %ebx   // %ebx = input_img->width

    movq IMAGE_DATA_OFFSET(%r8), %r8               // r8 = input_img->data
    movq IMAGE_DATA_OFFSET(%r9), %r9               // r9 = output-img->data

		movl $0, %r12d 								// r12d == row == 0

.Lrowloop_h:
		cmpl %eax, %r12d				// if row >= height
		jge .LstopLoop_h				// exit out of loop

    //start inner loop for columns
    movl $0, %r13d					//r13d == columns == 0

.LcolumnLoop_h:
    cmpl %ebx, %r13d              //if column >= width
    jge .LnextRow_h								//exit out of loop

    // Calculate output_img->data[row * width + column]
    movl %r12d, %edi             // rdi = row index
    imul %ebx, %edi           	 // rdi = row * width
    addl %r13d, %edi             // rdi = row * width + column index

    // Calculate input_img->data[row * width + (width - 1 - column)]
    //first completing the first half of equations (row * width)
		movl %r12d, %edx            // rdx = row
    imul %ebx, %edx             // rdx = row * width
		//now completing second part of equation
		movl %ebx, %esi             // rsi = width
    decl %esi                   // rsi = width - 1
    subl %r13d, %esi            //rsi = width - 1 - column index

		//adding the equations together
    addl %esi, %edx             // rdx = (row * width) + (width - 1 - column) (input index)

    // Move pixel from input_img to output_img
    movl (%r8, %rdx, 4), %esi    // Load pixel from input_img
    movl %esi, (%r9, %rdi, 4)    // Store pixel in output_img

    // moving to the next loop cycle
    incl %r13d                  // column++
    jmp .LcolumnLoop_h          // Repeat inner loop

.LnextRow_h:
    incl %r12d                  // row++
    jmp .Lrowloop_h             // Repeat outer loop

.LstopLoop_h:
    addq $8, %rsp               // Fix the stack pointer
    ret                         // end of function


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
    subq $8, %rsp                // Align the stack

    movq %rdi, %r8               // r8 = input_img
    movq %rsi, %r9               // r9 = output_img

    // Get height and width from input_img
    movl IMAGE_HEIGHT_OFFSET(%r8), %eax  // %eax = input_img->height
    movl IMAGE_WIDTH_OFFSET(%r8), %ebx   // %ebx = input_img->width

    movq IMAGE_DATA_OFFSET(%r8), %r8         // r8 = input_img->data
    movq IMAGE_DATA_OFFSET(%r9), %r9         // r9 = copying input_img data into output->img

		movl $0, %r12d 				 // r12d == row == 0

.Lvrowloop_h:
		cmpl %eax, %r12d				// if row >= height
		jge .LvstopLoop_h				// exit out of loop

    //start inner loop for columns
    movl $0, %r13d					//r13d == columns == 0

.LvcolumnLoop_h:
    cmpl %ebx, %r13d      //if column >= width
    jge .LvnextRow_h			//exit out of loop

		// Calculate output_img->data[(input_img->height - 1 - row) * output_img->width + column] 
    //doing first part of equation
		movl %eax, %esi             // esi = height
    decl %esi                   // esi = height - 1
    subl %r12d, %esi            // esi = height - 1 - row
		
		//completing second half of equation
    imul %ebx, %esi             // esi = (height - 1 - row) *  width
		addl %r13d, %esi            // esi = (height - 1 - rows) * width + column index


    //  Calculating input_img->data[row * output_img->width + column];
    movl %r12d, %edi           // rdi = row index
    imul %ebx, %edi            // rdi = row * width
    addl %r13d, %edi           // rdi = row * width + column index

    // Move pixel from input_img to output_img
    movl (%r8, %rsi, 4), %edx    // Load pixel from input_img 
    movl %edx, (%r9, %rdi, 4)    // Store pixel in output_img 

    //moving to the next loop cycle
    incl %r13d                   // column++
    jmp .LvcolumnLoop_h          // Repeat inner loop

.LvnextRow_h:
    incl %r12d                   // row++
    jmp .Lvrowloop_h             // Repeat outer loop

.LvstopLoop_h:
    // Cleanup and return
    addq $8, %rsp               // Fix the stack pointer
		ret													// end of function

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
	/* prologue to align stack */
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp

	// callee-saved registers local variables
	pushq %rbx  // total number of pixels
	pushq %r12  // input_img->data 
	pushq %r13  // output_img->data
	pushq %r14  // looping variable

    // get width and height
    movl IMAGE_WIDTH_OFFSET(%rdi), %edx  // Get width
    movl IMAGE_HEIGHT_OFFSET(%rdi), %ecx  // Get height

    // get number of pixels in image
    imull %edx, %ecx  // height * width
	movl %ecx, %ebx

    // prepare registers for looping
    movq IMAGE_DATA_OFFSET(%rdi), %r12  // Get input_img->data
    movq IMAGE_DATA_OFFSET(%rsi), %r13  // Get output_img->data
    movl $0, %r14d  // use %ebx as looping variable (i)

.Lgrayscale_loop:
    cmpl %ebx, %r14d  // check if we have exhausted pixels to loop over
    jge .Lgrayscale_loop_end // exit loop once we exhaust pixels

    movl (%r12, %r14, 4), %edi  // Load current pixel to be converted
    call to_grayscale  // call grayscale on pixel value

    movl %eax, (%r13, %r14, 4)  // Store grayscale pixel

    incl %r14d  // increment looping variable (i++)
    jmp .Lgrayscale_loop  // jump to start of loop

.Lgrayscale_loop_end:
	// restore callee-saved registers
	popq %r14
	popq %r13
	popq %r12
	popq %rbx

	/* epilogue */
	addq $8, %rsp
	popq %rbp
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
	xorl %eax, %eax
	ret

/*
vim:ft=gas:
*/
