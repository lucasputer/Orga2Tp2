%define NULL 0

%define offset_node_var_id 0
%define offset_node_node_id 4
%define offset_node_ref_count 8
%define offset_node_high_obdd 12
%define offset_node_low_obdd 20
%define node_size 28

%define offset_obdd_mgr 0
%define offset_obdd_node 8
%define obdd_size 16

%define offset_mgr_id 0
%define offset_mgr_greatest_node_id 4
%define offset_mgr_greatest_var_id 8
%define offset_mgr_true_obdd 12
%define offset_mgr_false_obdd 20
%define offset_mgr_vars_dict 28
%define mgr_size 36

extern free
extern malloc
extern obdd_mgr_get_next_node_ID
extern dictionary_value_for_key
extern dictionary_key_for_value
extern dictionary_add_entry
extern dictionary_destroy
extern is_constant
extern is_true
; extern obdd_destroy
; extern obdd_node_destroy

; ; recibe mgr*, char* var, node* high, node* low
global obdd_mgr_mk_node
obdd_mgr_mk_node:
	push rbp
	mov rbp, rsp
	push r12;
	push r13;
	push r14;
	push r15;
	push rbx;
	push r8; para alinear la pila

	mov r12, rdi; meto mgr* en r12
	mov r13, rsi ; meto var en r13
	mov r14, rdx; meto high en r14
	mov r15, rcx; meto low en r15

	xor rdi, rdi
	mov rdi, node_size ;el tamano que tiene un node
	call malloc
	mov rbx, rax ;paso el puntero a la memoria al rbx


	;dictionary_add_entry(mgr->vars_dict, var);
	xor rdi, rdi
	mov rdi, [r12 + offset_mgr_vars_dict] ;meto el mgr->vars_dict
	mov rsi, r13 ;meto var
	call dictionary_add_entry
	mov [rbx + offset_node_var_id], eax; ;muevo el var_id a la estructura

	mov rdi, r12
	call obdd_mgr_get_next_node_ID
	mov [rbx + offset_node_node_id], eax ; muevo el node_id a la estructura

	mov dword [rbx + offset_node_ref_count], NULL ;muevo ref_count a la estructura
	mov [rbx + offset_node_high_obdd], r14; ;muevo el high a la estructura
	mov [rbx + offset_node_low_obdd], r15 ;muevo el low  a la estructura

	jmp obdd_mgr_mk_node_check_null_high
	obdd_mgr_mk_node_check_null_high:
		cmp r14, NULL; chequeo si es null low
		jz obdd_mgr_mk_node_check_null_low	
		xor rax, rax
		mov dword eax, [r14 + offset_node_ref_count]
		inc eax
		mov dword [r14 + offset_node_ref_count], eax
		jmp obdd_mgr_mk_node_check_null_low

	obdd_mgr_mk_node_check_null_low:
		cmp r15, NULL
		jz obdd_mgr_mk_node_continue
		xor rax, rax ; si es null lo incremento en uno 
		mov dword eax, [r15 + offset_node_ref_count]
		inc eax
		mov [r15 + offset_node_ref_count], eax
		jmp obdd_mgr_mk_node_continue

	obdd_mgr_mk_node_continue:
		mov rax, rbx

		pop r8
		pop rbx
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
ret

; ; /** implementar en ASM
; ; void obdd_node_destroy(obdd_node* node){
; ; 	if(node->ref_count == 0){
; ; 		if(node->high_obdd != NULL){
; ; 			obdd_node* to_remove = node->high_obdd;
; ; 			node->high_obdd	= NULL;
; ; 			to_remove->ref_count--;
; ; 			obdd_node_destroy(to_remove);
; ; 		}
; ; 		if(node->low_obdd != NULL){
; ; 			obdd_node* to_remove = node->low_obdd;
; ; 			node->low_obdd	= NULL;
; ; 			to_remove->ref_count--;
; ; 			obdd_node_destroy(to_remove);
; ; 		}
; ; 		node->var_ID	= 0;
; ; 		node->node_ID	= 0;
; ; 		free(node);
; ; 	}
; ; }
; ; **/

; void obdd_node_destroy(obdd_node* node)

global obdd_node_destroy
obdd_node_destroy:
	push rbp
	push r12
	push r13
	mov rbp, rsp
	;pila alineada
	mov r12, rdi
	xor r13, r13
	mov r13, [r12 + offset_node_ref_count]
	cmp r13, NULL
	jne end_obdd_node_destroy
	jmp high_obdd_node_destroy

	high_obdd_node_destroy:
		xor rdi, rdi
		mov rdi, [r12 + offset_node_high_obdd]
		mov r13, rdi
		cmp rdi, NULL
		je low_obdd_node_destroy
		
		mov qword [r12 + offset_node_high_obdd], NULL ;node->high_obdd	= NULL;
		dec dword [r13 + offset_node_ref_count]
		call obdd_node_destroy
		jmp low_obdd_node_destroy

	low_obdd_node_destroy:
		xor rdi, rdi
		mov rdi, [r12 + offset_node_low_obdd]
		mov r13, rdi
		cmp rdi, NULL
		je end_obdd_node_destroy

		mov qword [r12 + offset_node_low_obdd], NULL ;node->low_obdd	= NULL;
		dec dword [r13 + offset_node_ref_count]
		call obdd_node_destroy
		jmp end_obdd_node_destroy

	end_obdd_node_destroy:
		mov dword [r12 + offset_node_var_id], NULL
		mov dword [r12 + offset_node_node_id], NULL
		xor rdi, rdi
		mov rdi, r12
		call free
		pop r13
		pop r12
		pop rbp
ret

global obdd_create
obdd_create:
	push rbp
	push r12
	push r13
	mov rbp, rsp

	mov r12, rdi ; meto mgr* en r8
	mov r13, rsi ; meto root en r9

	mov rdi, obdd_size
	call malloc ;tengo en rax el puntero

	mov [rax + offset_obdd_mgr], r12
	mov [rax + offset_obdd_node], r13

	pop r13
	pop r12
	pop rbp

ret

; ; /** implementar en ASM
; void obdd_destroy(obdd* root){
; 	if(root->root_obdd != NULL){
; 		obdd_node_destroy(root->root_obdd);
; 		root->root_obdd		= NULL;
; 	}
; 	root->mgr			= NULL;
; 	free(root);
; }
; **/
global obdd_destroy
obdd_destroy:
	push rbp
	push r12
	push r13

	mov rbp, rsp

	mov r12, rdi
	mov rdi, [r12 + offset_obdd_node]

	cmp rdi, NULL
	je end_obdd_destroy
	call obdd_node_destroy
	xor r8, r8
	mov [r12 + offset_obdd_node], r8
	jmp end_obdd_destroy

	end_obdd_destroy:
		xor r8, r8
		mov [r12 + offset_obdd_mgr], r8
		mov rdi, r12
		call free
		
		pop r13
		pop r12
		pop rbp
ret

; ; obdd_node* obdd_node_apply(bool (*apply_fkt)(bool,bool), obdd_mgr* mgr, obdd_node* left_node, obdd_node* right_node){

; global obdd_node_apply
; section .data
; 	TRUE_VAR: db '1', 0
; 	FALSE_VAR: db '0', 0
; section .text
; obdd_node_apply:
; 	push rbp
; 	mov rbp, rsp
; 	push rbx
; 	push r10
; 	push r8
; 	push r9
; 	push r12
; 	push r13
; 	push r14
; 	push r15

; 	mov r12, rdi ;apply_fkt
; 	mov r13, rsi ;mgr
; 	mov r14, rdx ;left_node
; 	mov r15, rcx ;right_node

; 	xor r8, r8
; 	xor r9, r9
; 	mov r8d, [r14 + offset_node_var_id] ; 	uint32_t left_var_ID	=  left_node->var_ID;
; 	mov r9d, [r15 + offset_node_var_id] ;	uint32_t right_var_ID	=  right_node->var_ID;

; 	; char* left_var			= dictionary_key_for_value(mgr->vars_dict,left_var_ID);
; 	mov rdi, [r13 + offset_mgr_vars_dict]
; 	mov rsi, r8
; 	call dictionary_key_for_value
; 	mov r8, rax; r8 <-left_var

; 	; char* right_var			= dictionary_key_for_value(mgr->vars_dict,right_var_ID);
; 	mov rdi, [r13 + offset_mgr_vars_dict]
; 	mov rsi, r9
; 	call dictionary_key_for_value
; 	mov r9, rax; r9 <-right_var

; 	mov rdi, r13; rdi <- mgr
; 	mov rsi, r14; rsi <- left_node
; 	xor rax, rax
; 	call is_constant ; rax <- is_left_constant
; 	xor rbx, rbx
; 	mov rbx, rax; rbx <- is_left_constant

; 	mov rdi, r13; rdi <- mgr
; 	mov rsi, r15; rsi <- right_node
; 	xor rax, rax
; 	call is_constant ; rax <- is_right_constant
; 	xor rcx, rcx
; 	mov rcx, rax; rcx <- is_right_constant

; 	and rax, rbx ; if(is_left_constant && is_right_constant)
; 	jz obdd_node_apply_check_is_left_constant


; 	;if((*apply_fkt)(is_true(mgr, left_node), is_true(mgr, right_node))){
; 	xor rax, rax
; 	mov rdi, r13
; 	mov rsi, r14
; 	call is_true
; 	mov rbx, rax ;rbx<- is_true left no necesito mas rdx porque muere aca la funcion

; 	xor rax, rax
; 	mov rdi, r13
; 	mov rsi, r15
; 	call is_true

; 	mov rdi, rbx
; 	mov rsi, rax
; 	xor rax, rax
; 	call r12

; ; return obdd_mgr_mk_node(mgr, TRUE_VAR, NULL, NULL);
; 	mov rdi, r13 ; rdi <- mgr
; 	mov rdx, NULL
; 	mov rcx, NULL

; 	cmp rax, NULL ;me fijo si es creo
; 	jnz obdd_node_apply_two_contants_apply_true
; 	jmp obdd_node_apply_two_contants_apply_false

; 	obdd_node_apply_two_contants_apply_true:
; 		mov rsi, TRUE_VAR
; 		call obdd_mgr_mk_node
; 		jmp obdd_node_apply_end

; 	obdd_node_apply_two_contants_apply_false:
; 		mov rsi, FALSE_VAR
; 		call obdd_mgr_mk_node
; 		jmp obdd_node_apply_end


; 	obdd_node_apply_check_is_left_constant:
; 		cmp rbx, NULL; if(is_left_constant)
; 		je obdd_node_apply_check_is_right_constant
; 		; 		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));
; 		xor rdx, rdx
; 		xor rax, rax
; 		mov rdx, r14
; 		mov rcx, [r15 + offset_node_high_obdd]
; 		mov r10, r14
; 		mov r11, [r15 +offset_node_low_obdd]
; 		jmp obdd_node_apply_applied_node


; 	obdd_node_apply_check_is_right_constant:
; 		cmp rcx, NULL
; 		je obdd_node_apply_check_var_ids_equal
; 		; 		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
; 		mov r9, r8
; 		xor rdx, rdx
; 		xor rax, rax
; 		mov rdx, [r14 + offset_node_high_obdd]
; 		mov rcx, r15
; 		mov r10, [r14 + offset_node_low_obdd]
; 		mov r11, r15
; 		jmp obdd_node_apply_applied_node

; 	obdd_node_apply_check_var_ids_equal:
; 		xor rax, rax
; 		xor rdx, rdx
; 		mov eax, [r14 + offset_node_var_id] ; 	uint32_t left_var_ID	=  left_node->var_ID;
; 		mov edx, [r15 + offset_node_var_id] ;	uint32_t right_var_ID	=  right_node->var_ID;
; 		cmp eax, edx
; 		jnz obdd_node_apply_check_var_ids_lower
; 		; 		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node->high_obdd), 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node->low_obdd));
; 		mov r9, r8
; 		xor rdx, rdx
; 		xor rax, rax
; 		mov rdx, [r14 + offset_node_high_obdd]
; 		mov rcx, [r15 + offset_node_high_obdd]
; 		mov r10, [r15 + offset_node_low_obdd]
; 		mov r11, [r14 + offset_node_low_obdd]
; 		jmp obdd_node_apply_applied_node

; 	obdd_node_apply_check_var_ids_lower:
; 		xor rax, rax
; 		xor rdx, rdx
; 		mov eax, [r14 + offset_node_var_id] ; 	uint32_t left_var_ID	=  left_node->var_ID;
; 		mov edx, [r15 + offset_node_var_id]
; 		cmp eax, edx
; 		jge obdd_node_apply_check_var_ids_else
; 		; 		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
; 		mov r9, r8
; 		xor rdx, rdx
; 		xor rax, rax
; 		mov rdx, [r14 + offset_node_high_obdd]
; 		mov rcx, r15
; 		mov r10, [r14 + offset_node_low_obdd]
; 		mov r11, r15
; 		jmp obdd_node_apply_applied_node

; 	obdd_node_apply_check_var_ids_else:
; 		; 		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
; 		; 			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));

; 		xor rdx, rdx
; 		xor rax, rax
; 		mov rdx, r14
; 		mov rcx, [r15 + offset_node_high_obdd]
; 		mov r10, r14
; 		mov r11, [r15 +offset_node_low_obdd]
; 		jmp obdd_node_apply_applied_node


; ; RDI, RSI, RDX, RCX, R8 y R9

; 	;PARAMETRO 1 (segundo de obdd_mgr_mk_node) => r9
; 	;PARAMETRO 2 (tercero de obdd_node_apply 1) => rdx
; 	;PARAMETRO 3 (cuarto de obdd_node_apply 1) => rcx
; 	;PARAMETRO 4 (tercero de obdd_node_apply 2) => r10
; 	;PARAMETRO 5 (cuarto de obdd_node_apply 1) => r11
; 	obdd_node_apply_applied_node:
; 		mov rdi, r12
; 		mov rsi, r13
; 		call obdd_node_apply
; 		mov r8,rax

; 		mov rdi, r12
; 		mov rsi, r13
; 		mov rdx, r10
; 		mov rcx, r11
; 		call obdd_node_apply

; 		mov rdi, r13
; 		mov rsi, r9
; 		mov rdx, r8
; 		mov rcx, rax
; 		call obdd_mgr_mk_node
; 		jmp obdd_node_apply_end



; 	obdd_node_apply_end:
; 		pop r15
; 		pop r14
; 		pop r13
; 		pop r12
; 		pop r9
; 		pop r8
; 		pop r10
; 		pop rbx
; 		pop rbp

; ret


global is_tautology
is_tautology:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	mov r13, rsi
	call is_constant
	cmp rax, NULL
	jne constant_is_tautology

	mov rdi, r12
	mov rsi, [r13 + offset_node_high_obdd]
	call is_tautology
	mov r14, rax
	mov rdi, r12
	mov rsi, [r13 + offset_node_low_obdd]
	call is_tautology
	and rax, r14
	jmp end_is_tautology

	constant_is_tautology:
		mov rdi, r12
		mov rsi, r13
		call is_true
		jmp end_is_tautology

	end_is_tautology:
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
ret

global is_sat
is_sat:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	mov r12, rdi
	mov r13, rsi
	call is_constant
	cmp rax, NULL
	jne constant_is_sat

	mov rdi, r12
	mov rsi, [r13 + offset_node_high_obdd]
	call is_sat
	cmp rax, NULL
	jnz end_is_sat
	mov r14, rax
	mov rdi, r12
	mov rsi, [r13 + offset_node_low_obdd]
	call is_sat
	jmp end_is_sat


	constant_is_sat:
		mov rdi, r12
		mov rsi, r13
		call is_true
		jmp end_is_sat

	end_is_sat:
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbp
ret

global str_len
str_len:
	push rbp
	mov rbp, rsp
	; Pila alineada
	xor rax, rax
	ciclo:
		cmp byte [rdi], NULL
		jz end
		inc rax
		inc rdi
		loop ciclo
	end:
		pop rbp
ret

global str_copy
str_copy:
	push rbp
	mov rbp, rsp
	; Pila alineada
	mov r9, rdi ; tengo el string a copiar en r9
	call str_len

	mov r8, rax
	inc r8 ; tengo la longitud en r8, aunmento uno por el null
	mov rdi, r8
	call malloc
	;tengo el puntero en rax
	mov r10, rax ; pongo el primer puntero en r10
	ciclo_copy:
		mov r11, [r9]
		mov [r10], r11
		cmp byte [r10], NULL
		jz end_copy
		inc r9
		inc r10
		loop ciclo_copy
	 end_copy:
		pop rbp
ret

global str_cmp
str_cmp:
	push rbp
	mov rbp, rsp
	xor rax, rax
	ciclo_str_cmp:
		xor r8, r8
		xor r9, r9
		mov r8b, [rdi]
		mov r9b, [rsi]
		cmp r8, r9
		jne str_cmp_distintos
		cmp r8b, NULL
		jz end_str_cmp
		inc rdi
		inc rsi
		loop ciclo_str_cmp

	str_cmp_distintos:
		cmp r8, r9
		jl positivo
		jmp negativo

	negativo:
		mov rax, -1
		jmp end_str_cmp

	positivo:
		mov rax, 1
		jmp end_str_cmp

	end_str_cmp:
		pop rbp	
ret
