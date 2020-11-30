#define ASM_FILE   1


	.globl _start
_start:
	/* check CPU ID = 0x0, or jump to hang */
	mrs	x0, mpidr_el1
	and	x0, x0, #3 
	cmp	x0, #0
	bne	hang

	/*
	 * Reset Vector Base Address,
	 */
reset_vector_base:
	/*
		GDB hang if access:
			vbar_el3, vbar_el2
			scr_el3, hcr_el2
	*/
	ldr	x1, = vectors
	msr	vbar_el1, x1

disable_l1_caches:
	MRS X0, SCTLR_EL3 // Read SCTLR_EL3.
	BIC X0, X0, #(0x1 << 2) // Disable D Cache.
	MSR SCTLR_EL3, X0 // Write SCTLR_EL3.

// Invalidate Data cache to make the code general purpose.
// Calculate the cache size first and loop through each set +
// way.
	MOV X0, #0x0 // X0 = Cache level
	MSR CSSELR_EL1, x0 // 0x0 for L1 Dcache 0x2 for L2 Dcache.
	MRS X4, CCSIDR_EL1 // Read Cache Size ID.
	AND X1, X4, #0x7
	ADD X1, X1, #0x4 // X1 = Cache Line Size.
	LDR X3, =0x7FFF
	AND X2, X3, X4, LSR #13 // X2 = Cache Set Number – 1.
	LDR X3, =0x3FF
	AND X3, X3, X4, LSR #3 // X3 = Cache Associativity Number – 1.
	CLZ W4, W3 // X4 = way position in the CISW instruction.
	MOV X5, #0 // X5 = way counter way_loop.
	way_loop:
	MOV X6, #0 // X6 = set counter set_loop.
set_loop:
	LSL X7, X5, X4
	ORR X7, X0, X7 // Set way.
	LSL X8, X6, X1
	ORR X7, X7, X8 // Set set.
	DC cisw, X7 // Clean and Invalidate cache line.
	ADD X6, X6, #1 // Increment set counter.
	CMP X6, X2 // Last set reached yet?
	BLE set_loop // If not, iterate set_loop,
	ADD X5, X5, #1 // else, next way.
	CMP X5, X3 // Last way reached yet?
	BLE way_loop // If not, iterate way_loop.

boot_cpu:
	/* configure stack */
	adrp	x0, stack_top	// Address of 4KB page at a PC-relative offset

main_label:					// Why we need this label let GDB step into main()?
	mov	sp, x0				// sp = stack_top (align with 4KB page)
	bl	main

hang:
	wfi
	b	hang

