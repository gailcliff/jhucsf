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
	/* TODO: implement */
	; ret
	
	.globl imgproc_mirror_h
	.type imgproc_mirror_h, @function

imgproc_mirror_h:
    pushq %rbp
    movq %rsp, %rbp
    
    # Preserve callee-saved registers
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15
    
    # Load input_img and output_img pointers
    movq %rdi, %r12  # input_img
    movq %rsi, %r13  # output_img
    
    # Load width and height
    movl (%r12), %r14d  # width
    movl 4(%r12), %r15d  # height
    
    # Initialize row counter
    xorl %ebx, %ebx  # row = 0
    
outer_loop:
    # Check if row < height
    cmpl %r15d, %ebx
    jge end_outer_loop
    
    # Initialize column counter
    xorl %ecx, %ecx  # col = 0
    
inner_loop:
    # Check if col < width
    cmpl %r14d, %ecx
    jge end_inner_loop
    
    # Calculate src_index = row * width + col
    movl %ebx, %eax
    imull %r14d, %eax
    addl %ecx, %eax
    
    # Calculate dst_index = row * width + (width - 1 - col)
    movl %r14d, %edx
    subl $1, %edx
    subl %ecx, %edx
    addl %eax, %edx
    
    # Load input_img->data[src_index]
    movq 8(%r12), %rsi  # input_img->data
    movb (%rsi, %rax), %dl
    
    # Store to output_img->data[dst_index]
    movq 8(%r13), %rdi  # output_img->data
    movb %dl, (%rdi, %rdx)
    
    # Increment col
    incl %ecx
    jmp inner_loop
    
end_inner_loop:
    # Increment row
    incl %ebx
    jmp outer_loop
    
end_outer_loop:
    # Restore callee-saved registers
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    
    # Epilogue
    movq %rbp, %rsp
    popq %rbp
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
	/* TODO: implement */
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
	/* TODO: implement */
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
