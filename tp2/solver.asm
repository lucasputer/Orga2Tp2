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

section .text
global solver_lin_solve
solver_lin_solve:
;call solver_lin_solve_1pixel_por_lectura
call solver_lin_solve_2pixel_por_lectura
ret

section .text
solver_lin_solve_2pixel_por_lectura:
	push rbp		
	mov rbp, rsp
	push r12 		
	push r13		
	push r14
	push r15
	push rbx
	sub rsp, 8		;alineada

	;rdi = solver
	;esi = b
	;rdx = x
	;rcx = x0
	;xmm0 = 0 | 0 | 0 | a
	;xmm1 = 0 | 0 | 0 | c
	cvtPS2PD xmm0, xmm0
	cvtPS2PD xmm1, xmm1

	shufpd xmm0, xmm0, 00000000b 	; xmm0 =  a | a
	shufpd xmm1, xmm1, 00000000b 	; xmm1 =  c | c


	xor r12, r12
	xor r13, r13 											; r13 = k
	xor r14, r14 											; r14 = i
	xor r15, r15 											; r15 = j
	

	mov r12d, [rdi + OFFSET_FLUID_SOLVER_N]					;r12 = solver->N
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

		movups xmm8, [rbx + rax*4]		; xmm8 =  a | b | c | d
		
		add eax, r12d
		add eax, 2

		mov r8, rax						; r8 = posicion temporal dentro de la matriz correspondiente al i-1,j de la iteración

		movups xmm9, [rbx + rax*4]		; xmm9 =  e | f | g | h
		add eax, r12d
		add eax, 2

		movups xmm10, [rbx + rax*4]		; xmm10 =  i | j| k | l
	
		movdqu xmm4, xmm8				
		movdqu xmm5, xmm9				; preservo xmm8, xmm9 y xmm10 para usarlos en la 2da iteración
		movdqu xmm6, xmm10

		;ITERACION 1
		movdqu xmm7, xmm5   			; xmm7 =  e | f | g | h
		PSRLDQ xmm7, 8					; xmm7 =  g | h | 0 | 0 
		
		addps xmm5, xmm7				; xmm5 = e+g|f+h| 0 | 0
		

		addps xmm4, xmm6				; xmm4 =...|b+j|c+k|...

		PSRLDQ xmm4, 4					; xmm4 = b+j|c+k|...| 0

		cvtPS2PD xmm2, xmm4				; xmm2 = b+j | c+k
		cvtPS2PD xmm7, xmm5				; xmm7 = e+g | f+h
		ADDPD xmm2, xmm7				; xmm2 = b+j+e+g | c+k+f+h					;OK

		MULPD xmm2, xmm0				; xmm2 = a * (b+j+e+g) | a * (c+k+f+h)

		movups xmm15, [rcx + r8*4]		; xmm15 = e0 | f0 | g0 | h0
		PSRLDQ xmm15, 4					; xmm15 = f0 | g0 | h0 | 00

		cvtPS2PD xmm14, xmm15			; xmm14 = f0 | g0

		ADDPD xmm2, xmm14				; xmm2 = f0 + a * (b+j+e+g) | g0 + a * (c+k+f+h)
		

		DIVPD xmm2, xmm1 				; xmm2 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f+h)) / c

		cvtPD2PS xmm3, xmm2				; xmm3 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f+h)) / c | 0 | 0
		movd [rbx + r8*4 + 4], xmm3		; escribe un solo resultado

		;Reemplazo f por el nuevo valor en xmm9

		xor r10, r10
		xor r11, r11

		movd r10d, xmm3					;r10 = f' | 0
		shl r10, 32						;r10 = 0  | f'
		movd r11d, xmm9					;r11 = e  | 0
		or r10, r11 					;r10 = e  | f'

		pxor xmm11, xmm11
		movq xmm11, r10 				;xmm11 = e | f' | 0 | 0

		PSRLDQ xmm9, 8					; xmm9 = g | h  | 0 | 0
		PSLLDQ xmm9, 8					; xmm9 = 0 | 0  | g | h

		POR xmm9, xmm11					; xmm9 = e | f' | g | h

		movdqu xmm4, xmm8				
		movdqu xmm5, xmm9				
		movdqu xmm6, xmm10

		;ITERACION 2
		movdqu xmm7, xmm5   			; xmm7 =  e | f' | g | h
		PSRLDQ xmm7, 8					; xmm7 =  g | h | 0 | 0 
		
		addps xmm5, xmm7				; xmm5 = e+g|f'+h| 0 | 0
		

		addps xmm4, xmm6				; xmm4 =...|b+j|c+k|...

		PSRLDQ xmm4, 4					; xmm4 = b+j|c+k|...| 0

		cvtPS2PD xmm2, xmm4				; xmm2 = b+j | c+k
		cvtPS2PD xmm7, xmm5				; xmm7 = e+g | f'+h
		ADDPD xmm2, xmm7				; xmm2 = b+j+e+g | c+k+f'+h

		MULPD xmm2, xmm0				; xmm2 = a * (b+j+e+g) | a * (c+k+f'+h)

		movups xmm15, [rcx + r8*4]		; xmm15 = e0 | f0 | g0 | h0
		PSRLDQ xmm15, 4					; xmm15 = f0 | g0 | h0 | 00

		cvtPS2PD xmm14, xmm15			; xmm14 = f0 | g0

		ADDPD xmm2, xmm14				; xmm2 = f0 + a * (b+j+e+g) | g0 + a * (c+k+f'+h)
		

		DIVPD xmm2, xmm1 				; xmm2 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f'+h)) / c

		cvtPD2PS xmm3, xmm2				; xmm3 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f'+h)) / c | 0 | 0
		PSRLDQ xmm3, 4					; xmm3 = (g0 + a * (c+k+f'+h)) / c | 0 | 0 | 0
		movd [rbx + r8*4 + 8], xmm3		; escribe un solo resultado

		inc r15d
		jmp .cicloj

	.endj:
	add r14d, 2
	jmp .cicloi

	.endi:
	inc r13d

	push rcx
	push rdi 
	push rsi 
	
	;Push xmm0
	sub rsp, 16
	movdqu [rsp], xmm0
	;Push xmm1
	sub rsp, 16
	movdqu [rsp], xmm1

	sub rsp, 8

	mov rdx, rbx
	call solver_set_bnd
	
	add rsp, 8

	;Pop xmm1
	movdqu xmm1, [rsp]
	add rsp, 16
	;Pop xmm0
	movdqu xmm0, [rsp]
	add rsp, 16

	pop rsi
	pop rdi
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

section .text
solver_lin_solve_1pixel_por_lectura:
	push rbp		
	mov rbp, rsp
	push r12 		
	push r13		
	push r14
	push r15
	push rbx
	sub rsp, 8		;alineada

	;rdi = solver
	;esi = b
	;rdx = x
	;rcx = x0
	;xmm0 = 0 | 0 | 0 | a
	;xmm1 = 0 | 0 | 0 | c
	cvtPS2PD xmm0, xmm0
	cvtPS2PD xmm1, xmm1

	shufpd xmm0, xmm0, 00000000b 	; xmm0 =  a | a
	shufpd xmm1, xmm1, 00000000b 	; xmm1 =  c | c


	xor r12, r12
	xor r13, r13 											; r13 = k
	xor r14, r14 											; r14 = i
	xor r15, r15 											; r15 = j
	

	mov r12d, [rdi + OFFSET_FLUID_SOLVER_N]					;r12 = solver->N
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
		
		addps xmm4, xmm6				; xmm4 =...|b+j|c+k|...

		PSRLDQ xmm4, 4					; xmm4 = b+j|c+k|...| 0

		cvtPS2PD xmm2, xmm4				; xmm2 = b+j | c+k
		cvtPS2PD xmm7, xmm5				; xmm7 = e+g | f+h
		ADDPD xmm2, xmm7				; xmm2 = b+j+e+g | c+k+f+h					;OK

		MULPD xmm2, xmm0				; xmm2 = a * (b+j+e+g) | a * (c+k+f+h)

		movups xmm15, [rcx + r8*4]		; xmm15 = e0 | f0 | g0 | h0
		PSRLDQ xmm15, 4					; xmm15 = f0 | g0 | h0 | 00

		cvtPS2PD xmm14, xmm15			; xmm14 = f0 | g0

		ADDPD xmm2, xmm14				; xmm2 = f0 + a * (b+j+e+g) | g0 + a * (c+k+f+h)
		

		DIVPD xmm2, xmm1 				; xmm2 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f+h)) / c

		cvtPD2PS xmm3, xmm2				; xmm3 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f+h)) / c | 0 | 0
		movd [rbx + r8*4 + 4], xmm3		; escribe un solo resultado por iteracion

		inc r15d
		jmp .cicloj

	.endj:
	add r14d, 1
	jmp .cicloi
	.endi:
	inc r13d

	push rcx
	push rdi 
	push rsi 
	
	;Push xmm0
	sub rsp, 16
	movdqu [rsp], xmm0
	;Push xmm1
	sub rsp, 16
	movdqu [rsp], xmm1

	sub rsp, 8

	mov rdx, rbx
	call solver_set_bnd
	
	add rsp, 8

	;Pop xmm1
	movdqu xmm1, [rsp]
	add rsp, 16
	;Pop xmm0
	movdqu xmm0, [rsp]
	add rsp, 16

	pop rsi
	pop rdi
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