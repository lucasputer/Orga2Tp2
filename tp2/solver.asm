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
	push r15
	push rbx
	sub rsp, 8		;alineada

	LDMXCSR 
	mov mxcsr, 0x5f81
	;rdi = solver
	;esi = b
	;rdx = x
	;rcx = x0
	;xmm0 = 0 | 0 | 0 | a
	;xmm1 = 0 | 0 | 0 | c
	cvtPS2PD xmm0, xmm0
	cvtPS2PD xmm1, xmm1

	divpd xmm0, xmm1				; xmm0 =  a/c | ?
	shufpd xmm0, xmm0, 00000000b 	; xmm0 =  a/c | a/c

	xor r12, r12
	xor r13, r13 											; r13 = k
	xor r14, r14 											; r14 = i
	xor r15, r15 											; r15 = j
	

	mov r12d, [rdi +  OFFSET_FLUID_SOLVER_N]				;r12 = solver->N
	mov rbx, rdx											;rbx = x

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
		xor rax, rax
		mov eax, r12d
		add eax, 2						
		mul r15d						; parte alta en edx, parte baja en eax
		shl rdx, 16						; rdx parte alta		
		or rax, rdx						; rax = (solver->N + 2) * j
		add eax, r14d					; rax = (solver->N + 2) * j + i

										; [a,b,c,d]
										; [e,f,g,h]
										; [i,j,q,k]
										; necesito: e+g, b+j, f+h, c+k

		movups xmm4, [rbx + rax*4]		; xmm4 =  a | b | c | d
		add eax, r12d
		add eax, 2

		mov r8, rax						; r8 = posicion temporal dentro de la matriz correspondiente al i-1,j de la iteración

		movups xmm5, [rbx + rax*4]		; xmm5 =  e | f | g | h
		add eax, r12d
		add eax, 2
		movups xmm6, [rbx + rax*4]		; xmm6 =  i | j| k | l

		
		movdqu xmm7, xmm5   			; xmm7 =  e | f | g | h			;diferencia movdqu con movups?
		PSRLDQ xmm7, 8					; xmm7 =  g | h | 0 | 0 
		addps xmm5, xmm7				; xmm5 = e+g|f+h| 0 | 0
		
		.debugg:

		addps xmm4, xmm6				; xmm4 =...|b+j|c+k|...

		PSRLDQ xmm4, 4					; xmm4 = b+j|c+k|...| 0

;	version sin conversion a double presicion:
;		ADDPS xmm4, xmm5				; xmm4 = 0 | 0 | b+j+e+g | c+k+f+h	
;		movdqu xmm2, xmm4				; xmm2 = 0 | 0 | b+j+e+g | c+k+f+h 	para que quede en el mismo registro que la version con conversion 

;	version con conversion a double presicion:
		cvtPS2PD xmm2, xmm4				; xmm2 = b+j | c+k
		cvtPS2PD xmm7, xmm5				; xmm7 = e+g | f+h
		ADDPD xmm2, xmm7				; xmm2 = b+j+e+g | c+k+f+h					;OK

		MULPD xmm2, xmm0				; xmm2 = (a/c) * (b+j+e+g) | (a/c) * (c+k+f+h)

		cvtPD2PS xmm3, xmm2 			; xmm3 = (a/c) * (b+j+e+g) | (a/c) * (c+k+f+h) | 0 | 0

		movups xmm15, [rcx + r8*4]		; xmm15 = x0[e,f,g,h]
		PSRLDQ xmm15, 4					; xmm15 = x0[f,g,h,0]

		ADDPS xmm3, xmm15				; xmm3 = x0[f] + (a/c) * (b+j+e+g) | x0[g] + (a/c) * (c+k+f+h) | ? | ?

		movd [rbx + r8*4 + 4], xmm3		; escribe un solo resultado por iteracion


		



		inc r15d
		jmp .cicloj

	.endj:
	add r14d, 1
	jmp .cicloi
	.endi:
	inc r13d

	mov rdx, rbx
	push rcx
	sub rsp, 8
	call solver_set_bnd
	add rsp, 8
	pop rcx
	jmp .ciclok
	.endK:

	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

