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

; typedef struct fluid_solver_t {
; 	uint32_t N;					//matrix size
; 	float dt, diff, visc;		//phys. coefficients
; 	float * u, * v, * u_prev, * v_prev;	//velocity fields
; 	float * dens, * dens_prev;	//density fields
; } __attribute__((__packed__)) fluid_solver;


extern malloc
extern free
extern solver_set_bnd
extern solver_lin_solve


; void solver_project ( fluid_solver* solver, float * p, float * div ){
; 	uint32_t i, j;
; 	IX = ((i)+(solver->N+2)*(j))
; 	for ( i=1 ; i<=solver->N ; i++ ) {
;		 for ( j=1 ; j<=solver->N ; j++ ) {
; 			div[IX(i,j)] = -0.5f*(solver->u[IX(i+1,j)]-solver->u[IX(i-1,j)]+solver->v[IX(i,j+1)]-solver->v[IX(i,j-1)])/solver->N;
;	 		p[IX(i,j)] = 0;
; 		}
;	}	
; 	solver_set_bnd ( solver, 0, div );
;	solver_set_bnd ( solver, 0, p );
; 	solver_lin_solve ( solver, 0, p, div, 1, 4 );
; 	for ( i=1 ; i<=solver->N ; i++ ) {
;		for ( j=1 ; j<=solver->N ; j++ ) {
; 			solver->u[IX(i,j)] -= 0.5f*solver->N*(p[IX(i+1,j)]-p[IX(i-1,j)]);
; 			solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)]-p[IX(i,j-1)]);
; 		}
; 	}
; 	solver_set_bnd ( solver, 1, solver->u );
;	solver_set_bnd ( solver, 2, solver->v );
; }

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
	;r10 = p
	;r11 = div
	mov r9, rdi
	xor r10, r10
	mov r10d, esi
	mov r11, rdx

	xor r12, r12 ;i
	inc r12d
	xor r13, r13 ;j
	inc r13d
	xor r14, r14
	mov r14d, [r9 + OFFSET_FLUID_SOLVER_N] ;N

	movups xmm6, [valmenos05] ; -0.5

	movd xmm7, r14d ; xmm3 = [N | ? | ? | ?]
	psrldq xmm7, 12 ; xmm3 = [0 | 0 | 0 | N]
	movdqu xmm4, xmm7
	pslldq xmm7, 4; xmm4 = [0 | 0 | N | 0]
	addpd xmm7, xmm4 ; ; xmm3 = [0 | 0 | N | N]
	cvtPS2PD xmm7, xmm7 ; xmm1 = [ N | N ]

	xor r15, r15
	mov r15d, r14d
	; dec r15
	.ciclo1i:
		cmp r12d, r14d ;(i == N)
		jge .finCiclo1i
		xor r13, r13
		inc r13d
		.ciclo1j:
			cmp r13d, r15d ;(j == N)
			jge .finCiclo1j

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
			movups xmm2, [r8 + rax*4] ; xmm2 = [u_i-1,j| u_i,j |u_i+1,j+1| u_i,j]

			;v(i,j-1) = ((i)+(solver->N+2)*(j))
			xor rax, rax
			mov eax, r14d ;N
			add eax, 2
			mov r8, r13
			dec r8
			mul r8
			add rax, r12 ; rax = IX(i,j-1)
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
			pxor xmm3, xmm3
			mov r8, [r9 + OFFSET_FLUID_SOLVER_V]
			movups xmm3, [r8 + rax*4] ; xmm3 = [v_i-1,j+1|v_i,j+1| v_i+1,j+1 | v_i+2,j+1]

			; xmm1 = [v_i-1,j-1|v_i,j-1| v_i+1,j-1 | v_i+2,j-1]
			; xmm2 = [ u_i-1,j | u_i,j | u_i+1,j+1 |   u_i,j  ]
			; xmm3 = [v_i-1,j+1|v_i,j+1| v_i+1,j+1 | v_i+2,j+1]

			; xmm1 = [ a | b | c | d ]
			; xmm2 = [ e | f | g | h ]
			; xmm3 = [ i | j | k | l ]			

			;=> ((g-e) + (j-b)) /// ((h-f) + (k-c))

			movdqu xmm4, xmm2
			psrldq xmm4, 8 ; xmm4 = [ 0 | 0 | e | f ]
			cvtPS2PD xmm2, xmm2 ; xmm2 = [ g | h ]
			cvtPS2PD xmm4, xmm4 ; xmm4 = [ e | f ]
			subpd xmm2, xmm4 ; xmm2 = [ g-e | h-f ]

			psrldq xmm1, 4 ; xmm1 = [ 0 | a | b | c ]
			psrldq xmm3, 4 ; xmm4 = [ 0 | i | j | k ]
			cvtPS2PD xmm1, xmm1 ; xmm1 = [ b | c ]
			cvtPS2PD xmm3, xmm3 ; xmm3 = [ j | k ]
			subpd xmm3, xmm1 ; xmm3 = [ j-b | k-c ]

			addpd xmm2, xmm3 ; xmm2 = [ (g-e) + (j-b) | (h-f) + (k-c) ]
			;movdqu xmm8, [val05] ;NO LEER DE MEMORIA EL VAL, PASARLO ANTES A UN REGISTRO Y USARLO
			mulpd xmm2, xmm6 ;xmm2 = [ -0.5*((g-e) + (j-b)) | -0.5*((h-f) + (k-c)) ]
			
			
			divpd xmm2, xmm7 ; xmm2 = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			cvtPD2PS xmm2, xmm2 ; xmm2 = [0 | 0 | -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			; pslldq xmm3, 8; xmm4 = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N | 0 | 0]
			;el shift anterior mueve a la parte alta, no se si el movq hace eso o no			

			; ; div[IX(i,j)]	IX = ((i)+(solver->N+2)*(j))
			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			add rax, r12 ; rax = IX(i,j)
			movq [r11 + rax*4], xmm2 ; div[IX(i,j)]  = [ -0.5*((g-e) + (j-b))/N | -0.5*((h-f) + (k-c))/N ]
			mov qword [r10 + rax*4], NULL ; p[IX(i,j)] = 0;

			inc r13d ; j++
			jmp .ciclo1j

		.finCiclo1j:
			add r12d, 2
			jmp .ciclo1i

	.finCiclo1i:
		; 	solver_set_bnd ( solver, 0, div );
		;	solver_set_bnd ( solver, 0, p );
		;r9 = solver
		;r10 = p
		;r11 = div
		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r11; rdx = div
		call solver_set_bnd

		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r10; rdx = p
		call solver_set_bnd

		;solver_lin_solve ( solver, 0, p, div, 1, 4 );
		mov rdi, r9 ; rdi = solver
		xor rsi, rsi ; rsi = 0
		mov rdx, r10; rdx = p
		mov rcx, r11; rcx = div
		pxor xmm0, xmm0
		movq xmm0, [val1]  
		pxor xmm1, xmm1
		movq xmm1, [val4]
		call solver_lin_solve

; 	for ( i=1 ; i<=solver->N ; i++ ) {
;		for ( j=1 ; j<=solver->N ; j++ ) {

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
			jge .finCiclo2j

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
			mov r8, r12
			dec r8
			add rax, r8 ; rax = IX(i-1,j-1)
			movups xmm2,[r10 + rax*4] ; xmm2 = [p_i-1,j-1|p_i,j-1|p_i+1,j-1|p_i+2,j-1]

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mul r13
			mov r8, r12
			dec r8
			add rax, r8 ; rax = IX(i-1,j)
			movups xmm3, [r10 + rax*4] ; xmm3 = [p_i-1,j|p_i,j|p_i+1,j|p_i+2,j]

			xor rax, rax
			mov eax, r14d
			add eax, 2
			mov r8, r13
			inc r8
			mul r8
			mov r8, r12
			dec r8
			add rax, r8 ; rax = IX(i-1,j+1)
			movups xmm4, [r10 + rax*4] ; xmm4 = [p_i-1,j+1|p_i,j+1|p_i+1,j+1|p_i+2,j+1]


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

			; busco [j - b | k - c] y [g - e | h - f]
			psrldq xmm4, 4 ; xmm4 = [0|i|j|k]
			psrldq xmm2, 4 ; xmm2 = [0|a|b|c]
			cvtPS2PD xmm4, xmm4 ; xmm4 = [j|k]
			cvtPS2PD xmm2, xmm2 ; xmm2 = [b|c]
			subpd xmm4, xmm2 ; xmm4 = [j-b|k-c]

			movaps xmm2, xmm3 ; xmm2 = [e|f|g|h]
			psrldq xmm2, 8 ; xmm2 = [0|0|e|f]
			cvtPS2PD xmm2, xmm2
			cvtPS2PD xmm3, xmm3
			subpd xmm3, xmm2 ; xmm3 = [g-e|h-f]

			mulpd xmm4, xmm6 ; xmm4 = [0.5*(j-b)|0.5*(k-c)]
			mulpd xmm3, xmm6 ; xmm3 = [0.5*(g-e)|0.5*(h-f)]

			;habia guardado N en xmm7
			mulpd xmm4, xmm7 ; xmm7 = [N*0.5*(j-b)|N*0.5*(k-c)]
			mulpd xmm3, xmm7 ; xmm7 = [N*0.5*(g-e)|N*0.5*(h-f)]

			; xmm0 = [  u_i,j  |u_i+1,j| u_i+2,j | u_i+3,j ]
			; xmm1 = [  v_i,j  |v_i+1,j| v_i+2,j | v_i+3,j ]
			psrldq xmm0, 8 ; xmm0 = [0|0|  u_i,j  |u_i+1,j]
			psrldq xmm1, 8 ; xmm1 = [0|0|  v_i,j  |v_i+1,j]
			cvtPS2PD xmm0, xmm0 ; xmm0 = [  u_i,j  |u_i+1,j]
			cvtPS2PD xmm1, xmm1 ; xmm1 = [  v_i,j  |v_i+1,j]

			subpd xmm0, xmm3 ; xmm0 = [  u_i,j - N*0.5*(j-b) |u_i+1,j -0.5*(k-c)]
			subpd xmm1, xmm4 ; xmm1 = [  v_i,j - N*0.5*(g-e)  |v_i+1,j - N*0.5*(h-f)]

			;esto no se si lo reduce o estoy flasheando ver tambien en el ciclo anterior
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

		; mov rsi, [r9 + OFFSET_FLUID_SOLVER_U] 
		; mov rcx, [r9 + OFFSET_FLUID_SOLVER_V]

		push rcx
		push rsi
		

		mov rdi, r9 ; rdi = solver
		xor rsi, rsi 
		inc rsi ; rsi = 1
		pop rdx ; rdx = [r9 + OFFSET_FLUID_SOLVER_U] 
		call solver_set_bnd

		mov rdi, r9 ; rdi = solver
		xor rsi, rsi
		add rsi, 2 ; rsi = 2
		pop rdx ; rdx = [r9 + OFFSET_FLUID_SOLVER_V] 
		call solver_set_bnd

		push r15
		push r14
		push r13
		push r12 		
		push rbp		
		
ret



