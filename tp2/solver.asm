%define NULL 0

%define OFFSET_FLUID_SOLVER_N 0
%define OFFSET_FLUID_SOLVER_DT 4
%define OFFSET_FLUID_SOLVER_DIFF 8
%define OFFSET_FLUID_SOLVER_VISC 12
%define OFFSET_FLUID_SOLVER_U 16
%define OFFSET_FLUID_SOLVER_V 24
%define OFFSET_FLUID_SOLVER_U_PREV 32
%define OFFSET_FLUID_SOLVER_V_PREV 40
%define OFFSET_FLUID_SOLVER_DENS 48
%define OFFSET_FLUID_SOLVER_DENS_PREV 56
%define FLUID_SOLVER_SIZE 56


extern malloc
extern free
extern solver_set_bnd
;extern solver_lin_solve

section .text
global solver_lin_solve
solver_lin_solve:

;siempre tener uno de los dos call comentados

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

		ADDPD xmm2, xmm14				; xmm2 = f0 + a * (b+j+e+g) | g0 + a * (c+k+f'+h)
		

		DIVPD xmm2, xmm1 				; xmm2 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f'+h)) / c

		cvtPD2PS xmm3, xmm2				; xmm3 = (f0 + a * (b+j+e+g)) / c | (g0 + a * (c+k+f'+h)) / c | 0 | 0
		PSRLDQ xmm3, 4					; xmm3 = (g0 + a * (c+k+f'+h)) / c | 0 | 0 | 0

		movd r11d, xmm3
		shl r11, 32
		shr r10, 32
		or r10, r11

		mov [rbx + r8*4 + 4], r10		; escribe dos resultados

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

section .rodata
	valmenos05: dq -0.5, -0.5
	val05: dq 0.5, 0.5
	val1: dd 1.0
	val4: dd 4.0
section .text
global solver_project
solver_project:
	push rbp		
	push r12 		
	push r13		
	push r14
	push r15	;alineada
	mov rbp, rsp

	;r9 = solver
	;r15 = p
	;r11 = div
	mov r9, rdi
	xor r10, r10
	mov r15, rsi
	mov r11, rdx

	xor r12, r12 ;i
	inc r12d
	xor r13, r13 ;j
	inc r13d
	xor r14, r14
	mov r14d, [r9 + OFFSET_FLUID_SOLVER_N] ;N

	movups xmm6, [valmenos05] ; -0.5

	movd xmm12, r14d ; xmm3 = [N | ? | ? | ?]
	;psrldq xmm7, 12 ; xmm3 = [0 | 0 | 0 | N]
	cvtdq2pd xmm12, xmm12
	movdqu xmm4, xmm12
	pslldq xmm12, 8; xmm4 = [0 | N | 0 | 0]
	addpd xmm12, xmm4 ; ; xmm3 = [N| N]
	

	xor r10, r10
	mov r10d, r14d
	; dec r10
	.ciclo1i:
		cmp r12d, r14d ;(i == N)
		jg .finCiclo1i
		xor r13, r13
		inc r13d
		.ciclo1j:
			cmp r13d, r10d ;(j == N)
			jg .finCiclo1j

			; div[IX(i,j)] = -0.5f*(solver->u[IX(i+1,j)]-solver->u[IX(i-1,j)]+solver->v[IX(i,j+1)]-solver->v[IX(i,j-1)])/solver->N;


			; i es la columna y j la fila !!!!!!!!!!!!!!!!!

			;u(i-1,j)  = ((i)+(solver->N+2)*(j-1))
			xor rax, rax
			mov eax, r14d ;N
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i,j-1)
			dec rax
			pxor xmm2, xmm2
			; [reg + reg*escala + desp]
			mov r8, [r9 + OFFSET_FLUID_SOLVER_U]
			movups xmm2, [r8 + rax*4] ; xmm2 = [u_i-1,j| u_i,j |u_i+1,j| u_i,j]

			;v(i,j-1) = ((i)+(solver->N+2)*(j))
			xor rax, rax
			mov eax, r14d ;N
			add eax, 2
			mov r8, r13
			dec r8
			mul r8
			add rax, r12 ; rax = IX(i,j-1)
			dec rax
			pxor xmm1, xmm1
			mov r8, [r9 + OFFSET_FLUID_SOLVER_V]
			movups xmm1, [r8 + rax*4] ; xmm1 = [v_i-1,j-1|v_i,j-1| v_i+1,j-1 | v_i+2,j-1]

			;u(i,j+1) = ((i)+(solver->N+2)*(j+1))
			xor rax, rax
			mov eax, r14d ;N
			add eax, 2
			mov r8, r13
			inc r8
			mul r8
			add rax, r12 ; rax = IX(i,j+1)
			dec rax
			pxor xmm3, xmm3
			mov r8, [r9 + OFFSET_FLUID_SOLVER_V]
			movups xmm3, [r8 + rax*4] ; xmm3 = [v_i-1,j+1|v_i,j+1| v_i+1,j+1 | v_i+2,j+1]

			; xmm1 = [v_i-1,j-1|v_i,j-1| v_i+1,j-1 | v_i+2,j-1]
			; xmm2 = [ u_i-1,j | u_i,j | u_i+1,j   |  u_i+2,j ]
			; xmm3 = [v_i-1,j+1|v_i,j+1| v_i+1,j+1 | v_i+2,j+1]

			; xmm1 = [ a | b | c | d ]
			; xmm2 = [ e | f | g | h ]
			; xmm3 = [ i | j | k | l ]	

			;esto de arriba es para debuggear	

			;=> ((g-e) + (j-b)) /// ((h-f) + (k-c))

			movdqu xmm4, xmm2
			psrldq xmm4, 8 ; xmm4 = [ 0 | 0 | e | f ]
			cvtps2pd xmm2, xmm2 ; xmm2 = [ g | h ]
			cvtps2pd xmm4, xmm4 ; xmm4 = [ e | f ]
			subpd xmm4, xmm2 ; xmm2 = [ g-e | h-f ]

			psrldq xmm1, 4 ; xmm1 = [ 0 | a | b | c ]
			psrldq xmm3, 4 ; xmm4 = [ 0 | i | j | k ]
			cvtps2pd xmm1, xmm1 ; xmm1 = [ b | c ]
			cvtps2pd xmm3, xmm3 ; xmm3 = [ j | k ]
			subpd xmm3, xmm1 ; xmm3 = [ j-b | k-c ]

			addpd xmm4, xmm3 ; xmm2 = [ (g-e) + (j-b) | (h-f) + (k-c) ]
			mulpd xmm4, xmm6 ;xmm2 = [ -0.5*((g-e) + (j-b)) | -0.5*((h-f) + (k-c)) ]
			
			
			divpd xmm4, xmm12 ; xmm2 = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			cvtpd2ps xmm4, xmm4 ; xmm2 = [0 | 0 | -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			; pslldq xmm3, 8; xmm4 = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N | 0 | 0]
			;el shift anterior mueve a la parte alta, no se si el movq hace eso o no			

			; ; div[IX(i,j)]	IX = ((i)+(solver->N+2)*(j))
			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i,j)
			movq [r11 + rax*4], xmm4 ; div[IX(i,j)]  = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			mov qword [r15 + rax*4], NULL ; p[IX(i,j)] = 0;

			inc r13d ; j++
			jmp .ciclo1j

		.finCiclo1j:
			add r12d, 2
			jmp .ciclo1i

	.finCiclo1i:
		; solver_set_bnd ( solver, 0, div );
		; solver_set_bnd ( solver, 0, p );
		;r9 = solver
		;r15 = p
		;r11 = div
		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r11; rdx = div
		push r11
		push r9
		call solver_set_bnd

		pop r9
		pop r11

		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r15; rdx = p

		push r11
		push r9
		call solver_set_bnd

		pop r9
		pop r11

		;solver_lin_solve ( solver, 0, p, div, 1, 4 );
		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r15; rdx = p
		mov rcx, r11; rcx = div
		pxor xmm0, xmm0
		movq xmm0, [val1]  
		pxor xmm1, xmm1
		movq xmm1, [val4]

		push r11
		push r9

		call solver_lin_solve

		pop r9
		pop r11


	; for ( i=1 ; i<=solver->N ; i++ ) {
	; 	for ( j=1 ; j<=solver->N ; j++ ) {

	movd xmm12, r14d ; xmm3 = [N | ? | ? | ?]
	cvtdq2pd xmm12, xmm12
	movdqu xmm4, xmm12
	pslldq xmm12, 8; xmm4 = [0 | N | 0 | 0]
	addpd xmm12, xmm4 ; ; xmm3 = [N| N]

	xor r12, r12 ;i
	inc r12d
	xor r13, r13 ;j
	inc r13d
	xor r14, r14
	mov r14d, [r9 + OFFSET_FLUID_SOLVER_N] ;N
	movups xmm6, [val05] ; 0.5
	mov rsi, [r9 + OFFSET_FLUID_SOLVER_U] 
	mov rcx, [r9 + OFFSET_FLUID_SOLVER_V]
	.ciclo2i:
		cmp r12d, r14d ;(i == N)
		jge .finCiclo2i
		xor r13d, r13d
		inc r13d
		.ciclo2j:
			cmp r13d, r14d ;(j == N)
			jg .finCiclo2j

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i,j)

			movups xmm0, [rsi + rax*4] ; xmm0 = [u_i,j|u_i+1,j|u_i+2,j|u_i+3,j]
			movups xmm1, [rcx + rax*4] ; xmm1 = [v_i,j|v_i+1,j|v_i+2,j|v_i+3,j]


			xor rax, rax
			mov eax, r14d
			add eax, 2
			mov r8, r13
			dec r8
			mul r8
			add rax, r12 ; rax = IX(i-1,j-1)
			dec rax
			movups xmm2,[r15 + rax*4] ; xmm2 = [p_i-1,j-1|p_i,j-1|p_i+1,j-1|p_i+2,j-1]

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i-1,j)
			dec rax
			movups xmm3, [r15 + rax*4] ; xmm3 = [p_i-1,j|p_i,j|p_i+1,j|p_i+2,j]

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mov r8, r13
			inc r8
			mul r8
			add rax, r12 ; rax = IX(i-1,j+1)
			dec rax
			movups xmm4, [r15 + rax*4] ; xmm4 = [p_i-1,j+1|p_i,j+1|p_i+1,j+1|p_i+2,j+1]


			; xmm0 = [  u_i,j  |u_i+1,j| u_i+2,j | u_i+3,j ]
			; xmm1 = [  v_i,j  |v_i+1,j| v_i+2,j | v_i+3,j ]

			; xmm2 = [p_i-1,j-1|p_i,j-1|p_i+1,j-1|p_i+2,j-1]
			; xmm3 = [ p_i-1,j | p_i,j | p_i+1,j | p_i+2,j ]
			; xmm4 = [p_i-1,j+1|p_i,j+1|p_i+1,j+1|p_i+2,j+1]

			; xmm2 = [a|b|c|d]
			; xmm3 = [e|f|g|h]
			; xmm4 = [i|j|k|l]

			;esto me conviene hacerlo de a pares o meter [g-r|h-f|j-b|k-c] ????
			; hago las mismas subidas de memoria y cuando hago las bajadas tambien
			;el tema es que hago la mitad de multiplicaciones
			;lo hago asi para tener mayor precision, CONSULTAR

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i,j)
			;lo de arruba es para test

			; busco [j - b | k - c] y [g - e | h - f]
			psrldq xmm4, 4 ; xmm4 = [0|i|j|k]
			psrldq xmm2, 4 ; xmm2 = [0|a|b|c]
			cvtps2pd xmm4, xmm4 ; xmm4 = [j|k]
			cvtps2pd xmm2, xmm2 ; xmm2 = [b|c]
			subpd xmm4, xmm2 ; xmm4 = [j-b|k-c]

			movaps xmm2, xmm3 ; xmm2 = [e|f|g|h]
			psrldq xmm2, 8 ; xmm2 = [0|0|e|f]
			cvtps2pd xmm2, xmm2
			cvtps2pd xmm3, xmm3
			subpd xmm2, xmm3 ; xmm3 = [g-e|h-f]

			mulpd xmm4, xmm6 ; xmm4 = [0.5*(j-b)|0.5*(k-c)]
			mulpd xmm2, xmm6 ; xmm3 = [0.5*(g-e)|0.5*(h-f)]

			;habia guardado N en xmm7
			mulpd xmm4, xmm12 ; xmm7 = [N*0.5*(j-b)|N*0.5*(k-c)]
			mulpd xmm2, xmm12 ; xmm7 = [N*0.5*(g-e)|N*0.5*(h-f)]

			; xmm0 = [  u_i,j  |u_i+1,j| u_i+2,j | u_i+3,j ]
			; xmm1 = [  v_i,j  |v_i+1,j| v_i+2,j | v_i+3,j ]
			;psrldq xmm0, 8 ; xmm0 = [0|0|  u_i,j  |u_i+1,j]
			;psrldq xmm1, 8 ; xmm1 = [0|0|  v_i,j  |v_i+1,j]
			cvtps2pd xmm0, xmm0 ; xmm0 = [  u_i,j  |u_i+1,j]
			cvtps2pd xmm1, xmm1 ; xmm1 = [  v_i,j  |v_i+1,j]

			subpd xmm0, xmm2 ; xmm0 = [  u_i,j - N*0.5*(j-b) |u_i+1,j -0.5*(k-c)]
			subpd xmm1, xmm4 ; xmm1 = [  v_i,j - N*0.5*(g-e)  |v_i+1,j - N*0.5*(h-f)]

			;esto no se si lo reduce o estoy flasheando ver tambien en el ciclo anterior
			cvtpd2ps xmm0, xmm0
			cvtpd2ps xmm1, xmm1
			movq [rsi + rax*4], xmm0 ; [  u_i,j - N*0.5*(j-b) |u_i+1,j -0.5*(k-c)]
			movq [rcx + rax*4], xmm1 ; [  v_i,j - N*0.5*(g-e)  |v_i+1,j - N*0.5*(h-f)]

			inc r13d; j = j++;

			jmp .ciclo2j

		.finCiclo2j:
			add r12d, 2
			jmp .ciclo2i

	.finCiclo2i:

		; 	solver_set_bnd ( solver, 0, div );
		;	solver_set_bnd ( solver, 0, p );
		;r9 = solver
		;r10 = p
		;r11 = div

		mov rsi, [r9 + OFFSET_FLUID_SOLVER_U] 
		mov rcx, [r9 + OFFSET_FLUID_SOLVER_V]

		push rcx
		push rsi
		

		mov rdi, r9 ; rdi = solver
		xor rsi, rsi 
		inc rsi ; rsi = 1
		pop rdx ; rdx = [r9 + OFFSET_FLUID_SOLVER_U] 
		push r9
		call solver_set_bnd

		pop r9
		mov rdi, r9 ; rdi = solver
		xor rsi, rsi
		add rsi, 2 ; rsi = 2
		pop rdx ; rdx = [r9 + OFFSET_FLUID_SOLVER_V] 
		call solver_set_bnd

		pop r15
		pop r14
		pop r13
		pop r12 		
		pop rbp		
		
ret
