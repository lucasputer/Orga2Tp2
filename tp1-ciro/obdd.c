#include "obdd.h"
#include "assert.h"
#include <string.h>

uint32_t obdd_mgr_greatest_ID = 0;
/** DICTIONARY FUNCTIONS **/
struct dictionary_t* dictionary_create(){
	struct dictionary_t* new_dict	= malloc(sizeof(struct dictionary_t));
	new_dict->entries		= malloc(sizeof(dictionary_entry) * INITIAL_DICT_ENTRIES_SIZE);
	new_dict->max_size		= INITIAL_DICT_ENTRIES_SIZE;
	new_dict->size			= 0;
	return new_dict;
}

void dictionary_destroy(struct dictionary_t* dict){
    uint32_t i = 1;
	for(i = 0; i < dict->size; i++){
	   	free(dict->entries[i].key);    ////////////////////////////////
	}
	free(dict->entries);
	dict->entries	= NULL;
	dict->size 		= 0;
	dict->max_size	= 0;
	free(dict);
}

bool dictionary_has_key(struct dictionary_t* dict, char* key){
    uint32_t i = 1;
	for(i = 0; i < dict->size; i++){
	    char *name = dict->entries[i].key;
		if(str_cmp(name, key) == 0)
			return true;
	}
	return false;
}

uint32_t dictionary_add_entry(struct dictionary_t* dict, char* key){
	
	//printf("size: %i \n", dict->size);
	if(dictionary_has_key(dict, key)){
		//printf("HAS_KEY: %d \n", *key);
		return dictionary_value_for_key(dict, key);
	}
	if(dict->size == dict->max_size ){
		struct dictionary_entry_t* entradas = malloc(dict->max_size * sizeof(dictionary_entry) * 2);
		
		dict->max_size = dict->max_size * 2;
		//printf("maxsize: %i \n", dict->max_size);
		uint32_t i = 1;
		for(i = 0; i < dict->size ; i++){
			entradas[i] = dict->entries[i];
			free(dict->entries[i].key);      ///////////////////////////////
			//printf("-%i \n", i); 
		} 
		free(dict->entries);
		dict->entries = entradas;
	}
    
	struct dictionary_entry_t entrada ;
	char* copykey = malloc(str_len(key)+1);
	copykey = str_copy(key);
	entrada.key = copykey;
	entrada.value = dict->size;
	dict->entries[dict->size] = entrada;
	dict->size = dict->size + 1;

	//printf("dict->size: %u \n", dict->size);

	return entrada.value;
}

uint32_t dictionary_value_for_key(struct dictionary_t* dict, char *key){
    uint32_t i = 1;
	for(i = 0; i < dict->size; i++){
	    char *name = dict->entries[i].key;
		if(strcmp(name, key) == 0)
			return dict->entries[i].value;
	}
    return 0;
}

char* dictionary_key_for_value(struct dictionary_t* dict, uint32_t value){
    return dict->entries[value].key;
}

int32_t dictionary_var_cmp(struct dictionary_t* dict, char* a, char* b){
	uint32_t value_a	= dictionary_value_for_key(dict, a);
	uint32_t value_b	= dictionary_value_for_key(dict, b);
	if(value_a == value_b){
		return 0;
	}else if(value_a < value_b){
		return 1;
	}else{
		return -1;	
	}
}

/** MGR FUNCTIONS **/
uint32_t get_new_mgr_ID(){
	uint32_t previous_ID	= obdd_mgr_greatest_ID;
	obdd_mgr_greatest_ID++;
	return previous_ID;
}

obdd_mgr*	obdd_mgr_create(){
	//instantiate manager
	obdd_mgr* new_mgr	= malloc(sizeof(obdd_mgr));
	new_mgr->ID			= get_new_mgr_ID();
	//is initialized in 1 so that we can later check for already deleted nodes
	new_mgr->greatest_node_ID	= 1;
	new_mgr->greatest_var_ID	= 0;
	
	//create variables dict
	new_mgr->vars_dict		= dictionary_create();
	
	//create constant obdds for true and false values
	obdd* true_obdd		= malloc(sizeof(obdd));
	true_obdd->root_obdd= obdd_mgr_mk_node(new_mgr, TRUE_VAR, NULL, NULL);
	true_obdd->mgr		= new_mgr;
	new_mgr->true_obdd	= true_obdd;
	obdd* false_obdd	= malloc(sizeof(obdd));
	false_obdd->root_obdd= obdd_mgr_mk_node(new_mgr, FALSE_VAR, NULL, NULL);
	false_obdd->mgr		= new_mgr;
	new_mgr->false_obdd	= false_obdd;
	return new_mgr;
}

void obdd_mgr_destroy(obdd_mgr* mgr){									//////////////////////////////////CASI SEGURO PIERDE MEMORIA ACA
	free(mgr->true_obdd);
	free(mgr->false_obdd);
	dictionary_destroy(mgr->vars_dict);
	free(mgr);
}

void obdd_mgr_print(obdd_mgr* mgr){
	printf("[OBDD MANAGER]\nMgr: %d\n", mgr->ID);
	printf("Mgr.Dict:\n");
	uint32_t i;
	struct dictionary_t* dict	= mgr->vars_dict;
	for(i = 0; i < dict->size; i++){
		printf("[%s]:%d\n", dict->entries[i].key, dict->entries[i].value);
	}
}

uint32_t obdd_mgr_get_next_node_ID(obdd_mgr* mgr){
	uint32_t previous_ID	= mgr->greatest_node_ID;
	mgr->greatest_node_ID++;
	return previous_ID;
}

/** implementar en ASM**/	
/*obdd_node* obdd_mgr_mk_node(obdd_mgr* mgr, char* var, obdd_node* high, obdd_node* low){
	uint32_t var_ID		= dictionary_add_entry(mgr->vars_dict, var);
	obdd_node* new_node	= malloc(sizeof(obdd_node));
	new_node->var_ID	= var_ID;
	new_node->node_ID	= obdd_mgr_get_next_node_ID(mgr);
	new_node->high_obdd	= high;
	if(high != NULL)
		high->ref_count++;
	new_node->low_obdd	= low;
	if(low != NULL)
		low->ref_count++;
	new_node->ref_count	= 0;
	return new_node;
}*/

obdd*	obdd_mgr_var(obdd_mgr* mgr, char* name){
	obdd* var_obdd	= malloc(sizeof(obdd));
	var_obdd->mgr	= mgr;
	obdd_node* nodetrue = obdd_mgr_mk_node(mgr, TRUE_VAR, NULL, NULL);
	obdd_node* nodefalse = obdd_mgr_mk_node(mgr, FALSE_VAR, NULL, NULL);
	var_obdd->root_obdd= obdd_mgr_mk_node(mgr, name
		, nodetrue, nodefalse);
	return var_obdd;
}

obdd*	obdd_mgr_true(obdd_mgr* mgr){ return mgr->true_obdd; }
obdd*	obdd_mgr_false(obdd_mgr* mgr){ return mgr->false_obdd; }

/** OBDD FUNCTIONS **/

/** implementar en ASM**/
/*obdd* obdd_create(obdd_mgr* mgr, obdd_node* root){
	obdd* new_obdd		= malloc(sizeof(obdd));
	new_obdd->mgr		= mgr;
	new_obdd->root_obdd	= root;
	return new_obdd;
}*/

/** implementar en ASM**/
/*void obdd_destroy(obdd* root){
	if(root->root_obdd != NULL){
		obdd_node_destroy(root->root_obdd);
		root->root_obdd		= NULL;
	}
	root->mgr			= NULL;
	free(root);
}
*/

bool obdd_apply_equals_fkt(bool left, bool right)	{ 	return left == right;	}
bool obdd_apply_xor_fkt(bool left, bool right)	{	return left ^ right;	}
bool obdd_apply_and_fkt(bool left, bool right)	{	return left && right;	}
bool obdd_apply_or_fkt(bool left, bool right)	{	return left || right;	}

obdd* obdd_apply_not(obdd* value){
	return obdd_apply_xor(value->mgr->true_obdd, value);
}

obdd* obdd_apply_equals(obdd* left, obdd* right){
	return obdd_apply(&obdd_apply_equals_fkt, left, right);
}

obdd* obdd_apply_xor(obdd* left, obdd* right){
	return obdd_apply(&obdd_apply_xor_fkt, left, right);
}

obdd* obdd_apply_and(obdd* left, obdd* right){
	return obdd_apply(&obdd_apply_and_fkt, left, right);
}

obdd* obdd_apply_or(obdd* left, obdd* right){
	return obdd_apply(&obdd_apply_or_fkt, left, right);
}

void obdd_remove_duplicated_terminals(obdd_mgr* mgr, obdd_node* root, obdd_node** true_node, obdd_node** false_node){
	
	if(is_constant(mgr, root))
		return;
	if(is_constant(mgr, root->high_obdd)){
		if(is_true(mgr, root->high_obdd)){
			if(*true_node == NULL){
				*true_node	= root->high_obdd;
			}else{
				if(root->high_obdd != NULL)
					root->high_obdd->ref_count--;
				obdd_node_destroy(root->high_obdd);
				root->high_obdd = *(true_node);
				(*(true_node))->ref_count++;
			}
		}else{
			if(*false_node == NULL){
				*false_node	= root->high_obdd;
			}else{
				if(root->high_obdd != NULL)
					root->high_obdd->ref_count--;
				obdd_node_destroy(root->high_obdd);
				root->high_obdd = *(false_node);
				(*(false_node))->ref_count++;
			}
		}
	}else{
		obdd_remove_duplicated_terminals(mgr, root->high_obdd, true_node, false_node);
	}
	if(is_constant(mgr, root->low_obdd)){
		if(is_true(mgr, root->low_obdd)){
			if(*true_node == NULL){
				*true_node	= root->low_obdd;
			}else{
				if(root->low_obdd != NULL)
					root->low_obdd->ref_count--;
				obdd_node_destroy(root->low_obdd);
				root->low_obdd = *(true_node);
				(*(true_node))->ref_count++;
			}
		}else{
			if(*false_node == NULL){
				*false_node	= root->low_obdd;
			}else{
				if(root->low_obdd != NULL)
					root->low_obdd->ref_count--;
				obdd_node_destroy(root->low_obdd);
				root->low_obdd = *(false_node);
				(*(false_node))->ref_count++;
			}
		}
	}else{
		obdd_remove_duplicated_terminals(mgr, root->low_obdd, true_node, false_node);
	}

}

void obdd_merge_redundant_nodes(obdd_mgr* mgr, obdd_node* root){
	if(is_constant(mgr, root))
		return;
	obdd_merge_redundant_nodes(mgr, root->high_obdd);
	obdd_merge_redundant_nodes(mgr, root->low_obdd);
	if(!is_constant(mgr, root->high_obdd)){
		if(root->high_obdd->high_obdd->node_ID == root->high_obdd->low_obdd->node_ID){
			obdd_node* to_remove	= root->high_obdd;
			root->high_obdd = root->high_obdd->high_obdd;
			root->high_obdd->ref_count++;
			to_remove->ref_count--;
			obdd_node_destroy(to_remove);
		}
	}
	if(!is_constant(mgr, root->low_obdd)){
		if(root->low_obdd->high_obdd->node_ID == root->low_obdd->low_obdd->node_ID){
			obdd_node* to_remove	= root->low_obdd;
			root->low_obdd = root->low_obdd->high_obdd;
			root->low_obdd->ref_count++;
			to_remove->ref_count--;
			obdd_node_destroy(to_remove);
		}
	}
}

void obdd_reduce(obdd* root){
	obdd_node* true_node	= NULL;
	obdd_node* false_node	= NULL;
	obdd_remove_duplicated_terminals(root->mgr, root->root_obdd, &true_node, &false_node);
	obdd_merge_redundant_nodes(root->mgr, root->root_obdd);
}

obdd* obdd_apply(bool (*apply_fkt)(bool,bool), obdd *left, obdd* right){
	if(left->mgr != right->mgr)
		return NULL;
	
	obdd* applied_obdd	= obdd_create(left->mgr, obdd_node_apply(apply_fkt, left->mgr, left->root_obdd, right->root_obdd));
	obdd_reduce(applied_obdd);
	return applied_obdd;
}	

/** implementar en ASM**/
obdd_node* obdd_node_apply(bool (*apply_fkt)(bool,bool), obdd_mgr* mgr, obdd_node* left_node, obdd_node* right_node){

	uint32_t left_var_ID	=  left_node->var_ID;
	uint32_t right_var_ID	=  right_node->var_ID;

	char* left_var			= dictionary_key_for_value(mgr->vars_dict,left_var_ID);
	char* right_var			= dictionary_key_for_value(mgr->vars_dict,right_var_ID);

	bool is_left_constant		= is_constant(mgr, left_node);
	bool is_right_constant		= is_constant(mgr, right_node);

	if(is_left_constant && is_right_constant){
		if((*apply_fkt)(is_true(mgr, left_node), is_true(mgr, right_node))){
			return obdd_mgr_mk_node(mgr, TRUE_VAR, NULL, NULL);
		}else{
			return obdd_mgr_mk_node(mgr, FALSE_VAR, NULL, NULL);
		}
	}

	obdd_node* applied_node;

	if(is_left_constant){
		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));
	}else if(is_right_constant){
		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
	}else if(left_var_ID == right_var_ID){
		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node->high_obdd), 
			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node->low_obdd));
	}else if(left_var_ID < right_var_ID){
		applied_node 	= obdd_mgr_mk_node(mgr, left_var, 
			obdd_node_apply(apply_fkt, mgr, left_node->high_obdd, right_node), 
			obdd_node_apply(apply_fkt, mgr, left_node->low_obdd, right_node));
	}else{
		applied_node 	= obdd_mgr_mk_node(mgr, right_var, 
			obdd_node_apply(apply_fkt, mgr, left_node, right_node->high_obdd), 
			obdd_node_apply(apply_fkt, mgr, left_node, right_node->low_obdd));
	}

	return applied_node;	
}

obdd* obdd_restrict(obdd* root, char* var, bool value){
	uint32_t var_ID	=  dictionary_value_for_key(root->mgr->vars_dict, var);
	obdd_node* restricted_node	= obdd_node_restrict(root->mgr, root->root_obdd, var, var_ID, value);

	return (obdd_create(root->mgr, restricted_node));
}

obdd_node* obdd_node_restrict(obdd_mgr* mgr, obdd_node* root, char* var, uint32_t var_ID, bool value){
	bool is_root_constant	= is_constant(mgr, root);
	uint32_t root_var_ID	= root->var_ID;
	char* root_var		= dictionary_key_for_value(mgr->vars_dict,root_var_ID);

	if(is_root_constant){
		return root;
	}

	uint32_t low_var_ID	=  root->low_obdd->var_ID;
	uint32_t high_var_ID	=  root->high_obdd->var_ID;

	char* low_var			= dictionary_key_for_value(mgr->vars_dict,low_var_ID);
	char* high_var			= dictionary_key_for_value(mgr->vars_dict,high_var_ID);

	bool is_low_constant		= is_constant(mgr, root->low_obdd);
	bool is_high_constant		= is_constant(mgr, root->high_obdd);

	obdd_node* applied_node;

	if(root_var_ID == var_ID){
		if(value){
			applied_node 	= obdd_mgr_mk_node(mgr, high_var
				, root->high_obdd->high_obdd, root->high_obdd->low_obdd); 
		}else{
			applied_node 	= obdd_mgr_mk_node(mgr, low_var
				, root->low_obdd->high_obdd, root->low_obdd->low_obdd);  
		}
	}else{
		applied_node 	= obdd_mgr_mk_node(mgr, root_var
			, obdd_node_restrict(mgr, root->high_obdd, var, var_ID, value)
			, obdd_node_restrict(mgr, root->low_obdd, var, var_ID, value));  	
	}
	return applied_node;	
}

obdd* obdd_exists(obdd* root, char* var){ 

	return  obdd_apply_or(obdd_restrict(root, var, true),obdd_restrict(root, var, false));
}

obdd* obdd_forall(obdd* root, char* var){ 

	return obdd_apply_and(obdd_restrict(root, var, true),obdd_restrict(root, var, false));
}

void obdd_print(obdd* root){
	printf("[OBDD]\nMgr_ID:%d\nValue:", root->mgr->ID);
	printf("\n");
	obdd_node_print(root->mgr, root->root_obdd, 0);
	printf("\n");
}

void obdd_node_print(obdd_mgr* mgr, obdd_node* root, uint32_t spaces){
	
	uint32_t i = 1;
	for(i = 0; i < spaces ; i++)
		printf(" ");

	printf("%s",mgr->vars_dict->entries[root->var_ID].key);

	if(!is_constant(mgr, root->high_obdd)){
		printf(" & \n");
		obdd_node_print(mgr, root->high_obdd, spaces + 1);
	}
	else{
		if(is_true(mgr, root->high_obdd))
			printf("-> 1 \n");
		else
			printf("-> 0 \n");
	}

	for(i = 0; i < spaces ; i++)
		printf(" ");

	printf("| \n");
	for(i=0; i < spaces ; i++)
		printf(" ");

	printf("(!%s)",mgr->vars_dict->entries[root->var_ID].key);

	if(!is_constant(mgr, root->low_obdd)){
		printf(" & \n");
		obdd_node_print(mgr, root->low_obdd, spaces + 1);
	}
	else{
		if(is_true(mgr, root->low_obdd))
			printf("-> 1 \n");
		else
			printf("-> 0 \n");	
	}
}

bool is_true(obdd_mgr* mgr, obdd_node* root){
	return mgr->true_obdd->root_obdd->var_ID == root->var_ID;
}
bool is_constant(obdd_mgr* mgr, obdd_node* root){
	return root->high_obdd == NULL && root->low_obdd == NULL;
}

/** implementar en ASM**/
/*bool is_tautology(obdd_mgr* mgr, obdd_node* root){
	if(is_constant(mgr, root)){
		return is_true(mgr, root);
	}else{
		return is_tautology(mgr, root->high_obdd) && is_tautology(mgr, root->low_obdd);	
	}
}*/

/** implementar en ASM **/
/*bool is_sat(obdd_mgr* mgr, obdd_node* root){

	if(is_constant(mgr, root)){
		return is_true(mgr, root);
	}else{
		return is_sat(mgr, root->high_obdd) || is_sat(mgr, root->high_obdd);	
	}
}
*/
/** OBDD NODE FUNCTIONS **/

/** implementar en ASM**/
/*void obdd_node_destroy(obdd_node* node){

	if(node->ref_count == 0){
		if(node->high_obdd != NULL){
			obdd_node* to_remove = node->high_obdd;
			node->high_obdd	= NULL;
			to_remove->ref_count--;
			obdd_node_destroy(to_remove);
		}
		if(node->low_obdd != NULL){
			obdd_node* to_remove = node->low_obdd;
			node->low_obdd	= NULL;
			to_remove->ref_count--;
			obdd_node_destroy(to_remove);
		}
		node->var_ID	= 0;
		node->node_ID	= 0;
		free(node);
	}
}*/

/** AUX FUNCTIONS **/

/** implementar en ASM**/
/*
uint32_t str_len(char* a) {
	return 0;
}*/

/** implementar en ASM**/
/*
char* str_copy(char* a) {
	return NULL;
}
*/

/** implementar en ASM**/

/*
int32_t str_cmp(char* a, char* b) {
	//Para poder correr los tests:
  	return strcmp(a,b);
}
*/