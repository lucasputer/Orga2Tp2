%define NULL 0

%define OFFSET_FLUID_SOLVER_N 0
%define OFFSET_FLUID_SOLVER_DT 4
%define OFFSET_FLUID_SOLVER_DIFF 8
%define OFFSET_FLUID_SOLVER_VISC 12
%define OFFSET_FLUID_SOLVER_U 20
%define OFFSET_FLUID_SOLVER_V 28
%define OFFSET_FLUID_SOLVER_U_PREV 36
%define OFFSET_FLUID_SOLVER_V_PREV 44
%define OFFSET_FLUID_SOLVER_DENS 52
%define OFFSET_FLUID_SOLVER_DENS_PREV 60
%define FLUID_SOLVER_SIZE 60


extern malloc
extern free
extern solver_set_bnd



; void solver_lin_solve ( fluid_solver* solver, uint32_t b, float * x, float * x0, float a, float c ){
; IX = ((i)+(solver->N+2)*(j))
; 	uint32_t i, j, k;
; 	for ( k=0 ; k<20 ; k++ ) {
; 		for ( i=1 ; i<=solver->N ; i++ ) {
;			 for ( j=1 ; j<=solver->N ; j++ ) {
; 				x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
; 			}
;		}
; 		solver_set_bnd ( solver, b, x );
section .text
global solver_lin_solve
solver_lin_solve:
	push rbp		
	mov rbp, rsp
	push r12 		
	push r13		
	push r14
	push r15		;alineada

	.debugg:

	;rdi = solver
	;esi = b
	;rdx = x
	;rcx = x0
	;xmm0 = a
	;xmm1 = c

	xor r12, r12
	xor r13, r13 ;k
	xor r14, r14 ;i
	xor r15, r15 ;j
	xor rax, rax

	mov r12d, [rdi +  OFFSET_FLUID_SOLVER_N]	
	
	.ciclok:

		cmp r13d, 20
		je .endK
		mov r14d, 0
	.cicloi:

		cmp r14d, r12d
		je .endi
		mov r15d, 0
	.cicloj:


		cmp r15d, r12d
		je .endj
		;x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
		
		mov eax, r12d
		add eax, 2
		mul r15d			; ACA SE ESTA ESTA PISANDO rdx = 0 
		add eax, r14d

		movups xmm4, [rdx + rax]		; xmm4 =  [a,b,c,d]
		add eax, r12d
		add eax, 2
		movups xmm5, [rdx + rax]		; xmm5 =  [e,f,g,h]
		add eax, r12d
		add eax, 2
		movups xmm6, [rdx + rax]		; xmm6 =  [i,j,k,l]

		;hacemos algo
		movdqu xmm7, xmm5   			; xmm7 = [e,f,g,h]
		PSRLDQ xmm7, 8					; xmm7 = [0,0,e,f]
		addps xmm5, xmm7					


		inc r15d
		jmp .cicloj

	.endj:
	add r14d, 2
	jmp .cicloi
	.endi:
	inc r13d


	;call solver_set_bnd
	jmp .ciclok
	.endK:

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

