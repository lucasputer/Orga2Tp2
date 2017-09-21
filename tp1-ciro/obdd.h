#ifndef OBDD_H
#define OBDD_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>

#define INITIAL_DICT_ENTRIES_SIZE	20
#define TRUE_VAR			"1"
#define FALSE_VAR			"0"

typedef enum { false, true } bool;

/** STRUCTS **/


struct dictionary_entry_t {
    char *key;
    uint32_t value;
} __attribute__((__packed__)) dictionary_entry;

struct dictionary_t{
	uint32_t size;
	uint32_t max_size;
	struct dictionary_entry_t* entries;
} __attribute__((__packed__)) dictionary;



typedef struct obdd_mgr_t {
	uint32_t		ID;
	uint32_t		greatest_node_ID;
	uint32_t		greatest_var_ID;
	struct obdd_t*			true_obdd;
	struct obdd_t*			false_obdd;
	struct dictionary_t*		vars_dict;
} __attribute__((__packed__)) obdd_mgr;

typedef struct obdd_node_t{
	uint32_t 		var_ID;
	uint32_t		node_ID;
	uint32_t		ref_count;
	struct obdd_node_t*	high_obdd;
	struct obdd_node_t*	low_obdd;
} __attribute__((__packed__)) obdd_node;

typedef struct obdd_t{
	struct obdd_mgr_t*	mgr;
	struct obdd_node_t*	root_obdd;
} __attribute__((__packed__)) obdd;

/** DICTIONARY **/
struct dictionary_t* dictionary_create();
void dictionary_destroy(struct dictionary_t* dict);
bool dictionary_has_key(struct dictionary_t* dict, char *key);
uint32_t dictionary_add_entry(struct dictionary_t* dict, char* key);
uint32_t dictionary_value_for_key(struct dictionary_t* dict, char *key);
char* dictionary_key_for_value(struct dictionary_t* dict, uint32_t value);
/** GLOBAL **/

uint32_t get_next_mgr_ID();

/** OBDD  MGR**/
obdd_mgr*	obdd_mgr_create();
void obdd_mgr_destroy(obdd_mgr* mgr);
void obdd_mgr_print(obdd_mgr* mgr);
obdd* 	obdd_mgr_true(obdd_mgr* mgr);
obdd* 	obdd_mgr_false(obdd_mgr* mgr);
obdd*	obdd_mgr_var(obdd_mgr* mgr, char* name);
bool obdd_mgr_equals(obdd_mgr* mgr, obdd* left, obdd* right);

uint32_t obdd_mgr_get_next_node_ID(obdd_mgr* mgr);
obdd_node* obdd_mgr_mk_node(obdd_mgr* mgr, char* var, obdd_node* high, obdd_node* low);
void obdd_node_destroy(obdd_node* root);
/** OBDD **/
obdd* obdd_create(obdd_mgr* mgr, obdd_node* root);
void obdd_destroy(obdd* root);

/** CORE COMPUTATION **/
obdd* obdd_restrict(obdd* root, char* var, bool value);
obdd_node* obdd_node_restrict(obdd_mgr* mgr, obdd_node* root, char* var, uint32_t var_ID, bool value);
obdd* obdd_exists(obdd* root, char* var);					//apply reduction based on shannon
obdd* obdd_forall(obdd* root, char* var);					//apply reduction based on shannon
void obdd_print(obdd* root);
void obdd_node_print(obdd_mgr* mgr, obdd_node* root, uint32_t spaces);
void obbd_node_destroy(obdd_node* node);

bool obdd_apply_equals_fkt(bool left, bool right);
bool obdd_apply_xor_fkt(bool left, bool right);
bool obdd_apply_and_fkt(bool left, bool right);
bool obdd_apply_or_fkt(bool left, bool right);

obdd* obdd_apply_not(obdd* value);

obdd* obdd_apply_equals(obdd* left, obdd* right);
obdd* obdd_apply_xor(obdd* left, obdd* right);
obdd* obdd_apply_and(obdd* left, obdd* right);
obdd* obdd_apply_or(obdd* left, obdd* right);
obdd* obdd_apply(bool (*apply_fkt)(bool,bool), obdd *left, obdd* right);	//if not canonical results should be reduced
obdd_node* obdd_node_apply(bool (*apply_fkt)(bool,bool), obdd_mgr* mgr, obdd_node* left_node, obdd_node* right_node);
void obdd_remove_duplicated_terminals(obdd_mgr* mgr, obdd_node* root, obdd_node** true_node, obdd_node** false_node);
void obdd_merge_redundant_nodes(obdd_mgr* mgr, obdd_node* root);
void obdd_reduce(obdd* root);
bool is_true(obdd_mgr* mgr, obdd_node* root);
bool is_constant(obdd_mgr* mgr, obdd_node* root);						//checks if representation is constant
bool is_tautology(obdd_mgr* mgr, obdd_node* root);						//checks if representation is always true
bool is_sat(obdd_mgr* mgr, obdd_node* root);							//checks if representation is satisfiable
/** AUX **/
uint32_t str_len(char* a);
char* str_copy(char* a);
int32_t str_cmp(char* a, char* b);

#endif
