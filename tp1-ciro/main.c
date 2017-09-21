#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include "obdd.h"

char *formulasFile  =  "formulas.txt";

void test_add_entry(){ 
	
	printf("a \n"); 
	struct dictionary_t* diccionario = dictionary_create();
	printf("b \n");
	char clave1 = 'a';
	char clave2 = 'b';
	char clave3 = 'c';
	char clave4 = 'd';
	char clave5 = 'e';
	char clave6 = 'f';
	char clave7 = 'g';
	char *key1 = &clave1;
	char *key2 = &clave2;
	char *key3 = &clave3;
	char *key4 = &clave4;
	char *key5 = &clave5;
	char *key6 = &clave6;
	char *key7 = &clave7;

	uint32_t indice1 = dictionary_add_entry(diccionario, key1);
	printf("c \n"); 
	uint32_t indice2 = dictionary_add_entry(diccionario, key2);
	printf("indice2: %u \n",indice2);
	uint32_t indice3 = dictionary_add_entry(diccionario, key3);
	printf("indice3: %u \n",indice3);
	uint32_t indice4 = dictionary_add_entry(diccionario, key4);
	printf("indice4: %u \n",indice4);
	uint32_t indice5 = dictionary_add_entry(diccionario, key5);
	uint32_t indice6 = dictionary_add_entry(diccionario, key6);
	uint32_t indice7 = dictionary_add_entry(diccionario, key7);
	printf("d \n"); 
	uint32_t tammax = diccionario->max_size;
	uint32_t tam = diccionario->size;
	char *keyy = diccionario->entries[3].key;
	printf("%c  %c %u maxsize: %u, size: %u \n", *key4, *keyy, indice3, tammax, tam); 
	
	dictionary_destroy(diccionario);
}

void test_mgr_destroy(){
	struct obdd_mgr_t* manager = obdd_mgr_create();
	obdd_mgr_destroy(manager);
}

void test_asm_str(){
	char* hola = "Hola";
	uint32_t largo = str_len(hola);
	printf("largo hola: %u\n", largo);

	char* holaCopia = str_copy(hola);
	uint32_t largoCopia = str_len(holaCopia);
	printf("largo copia: %u\n", largoCopia);
	
	hola = "Hello";
	uint32_t largoHello = str_len(hola);
	printf("Largo hola nuevo: %u \n", largoHello);
	printf("Hola nuevo: %s \n", hola);
	printf("Hola copia: %s \n", holaCopia);
	
	int compareABC_AAA = str_cmp("ABC", "AAA");
	printf("cmp ABC_AAA (-1): %i \n", compareABC_AAA);

	int compareAAA_ABC = str_cmp("AAA", "ABC");
	printf("cmp AAA_ABC (1): %i \n", compareAAA_ABC);

	int compareAAA_AAA = str_cmp("AAA", "AAA");
	printf("cmp AAA AAA (0): %i \n", compareAAA_AAA);

	int compareA_AA = str_cmp("A", "AA");
	printf("cmp A AA (1): %i \n", compareA_AA );

	int compareAA_A = str_cmp("AA", "A");
	printf("cmp AA A (-1): %i \n", compareAA_A);
}

void test_asm_mgr(){
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
}

void run_tests(){
	
	//test_add_entry();
	test_mgr_destroy();

	//test_asm_str();
	//test_asm_mgr();
}

int main (void){

	run_tests();
	int save_out = dup(1);
	remove(formulasFile);
	int pFile = open(formulasFile, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
	run_tests();
	fflush(stdout);
	close( pFile );
	dup2(save_out, 1);

	run_tests();
	printf("asdasf \n");
	return 0;    
}


