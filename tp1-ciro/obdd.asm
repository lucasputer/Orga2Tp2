extern free
extern malloc
extern dictionary_add_entry
extern obdd_mgr_get_next_node_ID
extern is_constant
extern is_true

OFFSET_MGR_ID equ 0
OFFSET_MGR_greatest_node_ID equ 4
OFFSET_MGR_greatest_var_ID equ 8
OFFSET_MGR_true_obdd equ 12
OFFSET_MGR_false_obdd equ 20
OFFSET_MGR_vars_dict equ 28

OFFSET_NODE_var_ID equ 0
OFFSET_NODE_node_ID equ 4
OFFSET_NODE_ref_count equ 8
OFFSET_NODE_high_obdd equ 12
OFFSET_NODE_low_obdd equ 20

OFFSET_OBDD_MGR equ 0
OFFSET_OBDD_ROOT_OBDD equ 8

global obdd_mgr_mk_node
obdd_mgr_mk_node:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	push r13		;alineada
	push r14
	push r15
	;rdi = mgr
	;rsi = var
	mov r14, rdx
	mov r15, rcx
	;r14 = high
	;r15 = low

	mov r12, rdi 	;r12 = mgr
	mov rdi, [r12 + OFFSET_MGR_vars_dict]

	call dictionary_add_entry 
	mov r13, rax				;r13 = var_ID
	mov rdi, 28 				;sizeof(obdd_node)
	call malloc					;rax = new_node
	mov [rax + OFFSET_NODE_var_ID], r13 
    mov r13, rax				;r13 = new_node

    mov rdi, r12
	call obdd_mgr_get_next_node_ID	;rax = node_id 
	mov [r13 + OFFSET_NODE_node_ID], rax
	mov [r13 + OFFSET_NODE_high_obdd], r14
	cmp r14, 0
	je .highNull
	add dword [r14 + OFFSET_NODE_ref_count], 1
	.highNull:

	mov [r13 + OFFSET_NODE_low_obdd], r15
	je .lowNull
	add dword [r15 + OFFSET_NODE_ref_count], 1
	.lowNull:

	mov dword [r13 + OFFSET_NODE_ref_count], 0
	mov rax, r13		;devuelvo el puntero a new_node en rax

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret


global obdd_node_destroy
obdd_node_destroy:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	push r13		;alineada

	;rdi = node


	mov r12, rdi 	;r12 = node
	mov r13, [r12 + OFFSET_NODE_ref_count]	; r13 = node->ref_cout
	cmp r13, 0
	jne .end

	mov r13, [r12 + OFFSET_NODE_high_obdd] 	; r13 = to_remove (high)
	cmp r13, 0
	je .highNull

	mov dword [r12 + OFFSET_NODE_high_obdd], 0
	sub dword [r13 + OFFSET_NODE_ref_count], 1
	mov rdi, r13
	call obdd_node_destroy

	.highNull:
	mov r13, [r12 + OFFSET_NODE_low_obdd] ; r13 = to_remove (low)
	cmp r13, 0
	je .free

	mov dword [r12 + OFFSET_NODE_low_obdd], 0
	sub dword [r13 + OFFSET_NODE_ref_count], 1
	mov rdi, r13
	call obdd_node_destroy	
	mov dword [r12 + OFFSET_NODE_var_ID], 0
	mov dword [r12 + OFFSET_NODE_node_ID], 0
	
	.free:
	mov rdi, r12
	call free

	.end: 
	pop r13
	pop r12
	pop rbp
	ret

global obdd_create
obdd_create:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	push r13		;alineada

	;rdi = mgr
	;rsi = root

	mov r12, rdi 	;r12 = mgr
	mov r13, rsi	;r13 = root
	
	mov rdi, 16  							; size of obdd????????
	call malloc 							; rax = new_obdd
	mov [rax + OFFSET_OBDD_MGR], r12
	mov [rax + OFFSET_OBDD_ROOT_OBDD], r13

	.end: 
	pop r13
	pop r12
	pop rbp
	ret

global obdd_destroy
obdd_destroy:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	push r13		;alineada

	;rdi = root

	mov r12, rdi 	;r12 = root
	mov r13, [r12 + OFFSET_OBDD_ROOT_OBDD]	; r13 = root->root_obdd
	cmp r13, 0
	je .free
	mov rdi, r13
	call obdd_node_destroy
	mov dword [r12 + OFFSET_OBDD_ROOT_OBDD], 0

	.free:
	mov dword [r12 + OFFSET_OBDD_MGR], 0
	mov rdi, r12
	call free

	pop r13
	pop r12
	pop rbp
	ret

;global obdd_node_apply
;obdd_node_apply:
;obdd_destroy:
;	push rbp		;alineada
;	mov rbp, rsp
;	push r12 		;desalineada
;	push r13		;alineada
;
;	;rdi = root
;
;	mov r12, rdi 	;r12 = root
;	mov r13, [r12 + OFFSET_OBDD_ROOT_OBDD]	; r13 = root->root_obdd
;	cmp r13, 0
;	je .free
;	mov rdi, r13
;	call obdd_node_destroy
;	mov dword [r12 + OFFSET_OBDD_ROOT_OBDD], 0
;
;	.free:
;	mov dword [r12 + OFFSET_OBDD_MGR], 0
;	mov rdi, r12
;	call free
;
;	pop r13
;	pop r12
;	pop rbp
;	ret

;obdd_node* obdd_node_apply(bool (*apply_fkt)(bool,bool), obdd_mgr* mgr, obdd_node* left_node, obdd_node* right_node){
;	uint32_t left_var_ID	=  left_node->var_ID;
;	uint32_t right_var_ID	=  right_node->var_ID;
;	char* left_var			= dictionary_key_for_value(mgr->vars_dict,left_var_ID);
;	char* right_var			= dictionary_key_for_value(mgr->vars_dict,right_var_ID);
;	bool is_left_constant		= is_constant(mgr, left_node);
;	bool is_right_constant		= is_constant(mgr, right_node);
;	if(is_left_constant && is_right_constant){
;		if((*apply_fkt)(is_true(mgr, left_node), is_true(mgr, right_node))){
;			return obdd_mgr_mk_node(mgr, TRUE_VAR, NULL, NULL);
;		}else{
;			return obdd_mgr_mk_node(mgr, FALSE_VAR, NULL, NULL);
;		}
;	}
;	obdd_node* applied_node;
;	if(is_left_constant){
;		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
;			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
;			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));
;	}else if(is_right_constant){
;		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
;			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
;			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
;	}else if(left_var_ID == right_var_ID){
;		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
;			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node->high_obdd), 
;			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node->low_obdd));
;	}else if(left_var_ID < right_var_ID){
;		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
;			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
;			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
;	}else{
;		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
;			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
;			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));
;	}
;	return applied_node;	


global is_tautology
is_tautology:
	push rbp		;alineada
	mov rbp, rsp
	push r12		;desalineada
	push r13		;alineada
	
	mov r12, rdi
	mov r13, rsi
	call is_constant	
	cmp rax, 0
	je .false 
	mov rdi, r12
	mov rsi, r13
	call is_true

	pop r13
	pop r12
	pop rbp
	ret

	.false:
	mov rdi, r12
	mov rsi, [r13 + OFFSET_NODE_high_obdd]
	call is_tautology
	
	mov	rdi, r12
	mov rsi, [r13 + OFFSET_NODE_low_obdd]
	mov r12, rax			;r12 = is_tautology(high)
	call is_tautology		;rax = is_tautology(low)

	and rax, r12

	pop r13
	pop r12
	pop rbp
	ret	

global is_sat
is_sat:
	push rbp		;alineada
	mov rbp, rsp
	push r12		;desalineada
	push r13		;alineada
	
	mov r12, rdi
	mov r13, rsi
	call is_constant	
	cmp rax, 0
	je .false 
	mov rdi, r12
	mov rsi, r13
	call is_true

	pop r13
	pop r12
	pop rbp
	ret

	.false:
	mov rdi, r12
	mov rsi, [r13 + OFFSET_NODE_high_obdd]
	call is_sat
	
	mov	rdi, r12
	mov rsi, [r13 + OFFSET_NODE_low_obdd]
	mov r12, rax			;r12 = is_sat(high)
	call is_sat		;rax = is_sat(low)

	or rax, r12

	pop r13
	pop r12
	pop rbp
	ret	

;section .text	
global str_len
str_len:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	sub rsp, 8		;alineada
	
    xor r12, r12		; R12 = inicializo acumulador	
    ;xor cl, cl
	.ciclo:
		mov cl, [rdi + r12]
		inc r12
		cmp cl, 0
		jne .ciclo
	dec r12
	mov rax, r12			; devuelvo resultado

	add rsp, 8
	pop r12
	pop rbp
	ret

;section .text	
global str_copy
str_copy:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	push r13 		;alineada
	
	mov r13, rdi	; char* esta en r13 y rdi
	call str_len 	; en rax queda el largo
	inc rax		 	; rax = largo + 1
	mov rdi, rax	; solicito la cantidad de bytes del largo de len + 1
	call malloc 	; llamo a malloc que devuelve en rax el puntero a la memoria solicitada
	xor r12, r12   	; inicializo el contador
	.ciclo:
		mov cl, [r13 + r12]	;en cl esta el contenido de la posicion r12 del arreglo
		mov [rax + r12], cl
		inc r12
		cmp cl, 0			;si lo ultimo que copie es 0, salgo del ciclo.
		jne .ciclo
	
	pop r13
	pop r12
	pop rbp

	ret ; en rax queda el puntero al string copiado

;section .text
global str_cmp
str_cmp:
	push rbp		;alineada
	mov rbp, rsp
	push r12 		;desalineada
	sub rsp, 8		;alineada

	;rdi y rsi
	xor r12, r12 			;inicializo el contador
	xor rcx, rcx
	xor rdx, rdx
	.cicloComparo:
		mov cl, [rdi + r12] 	;en cl esta el contanido de la posicion r12 de str1
		mov dl, [rsi + r12] 	;en dl esta el contanido de la posicion r12 de str2
		inc r12
		cmp cl, 0
		je .endCicloCmp
		cmp dl, 0
		je .endB 				;str2 es menor

		cmp cl, dl
		je .cicloComparo
	
	.endCicloCmp:
	cmp cl, dl
	jl .endA
	jg .endB

	.end0:
	mov rax, 0
	jmp .endCmp
	.endA:
	mov rax, 1
	jmp .endCmp
	.endB:
	mov rax, -1
	jmp .endCmp

	.endCmp:
	add rsp, 8
	pop r12
	pop rbp
	ret


