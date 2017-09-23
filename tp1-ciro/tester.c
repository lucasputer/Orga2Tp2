#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include "obdd.h"

char *archivoCasoMgr  =  "salida.caso.mgr.txt";
char *archivoCasoObddChico =  "salida.caso.obdd.chico.txt";
char *archivoCasoObddGrande =  "salida.caso.obdd.grande.txt";

void casoManager();
void casoObddChico();
void casoObddGrande();

int main() {
	/*casoManager();
	casoObddChico();
	casoObddGrande();

	int err = open("cerr.log", O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == err) { perror("opening cerr.log"); return 255; }

	int save_out = dup(1);
	int save_err = dup(2);

	if (-1 == dup2(err, 2)) { perror("cannot redirect stderr"); return 255; }

	
	int pFile;

	remove(archivoCasoMgr);
	pFile = open(archivoCasoMgr, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
	casoManager();
	fflush(stdout);
	close( pFile );
	remove(archivoCasoObddChico);
	pFile = open(archivoCasoObddChico, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
	casoObddChico();
	fflush(stdout);
	close( pFile );
	remove(archivoCasoObddGrande);
	pFile = open(archivoCasoObddGrande, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
	casoObddGrande();
	fflush(stdout);
	close( pFile );

	fflush(stderr); close(err);

	dup2(save_out, 1);
	dup2(save_err, 2);
	close(save_err);
*/
	return 0;
}

void casoManager() {
	printf( "Test manager\n");
	obdd_mgr* new_mgr	= obdd_mgr_create();


	/*obdd* x1_obdd		= obdd_mgr_var(new_mgr, "x1");
	obdd* x2_obdd		= obdd_mgr_var(new_mgr, "x2");
	obdd* x3_obdd		= obdd_mgr_var(new_mgr, "x3");
	obdd* x3_obdd_rep	= obdd_mgr_var(new_mgr, "x3");

	obdd_mgr_print(new_mgr);

	obdd_print(x1_obdd);
	
	obdd_destroy(x1_obdd);
	obdd_destroy(x2_obdd);
	obdd_destroy(x3_obdd);
	obdd_destroy(x3_obdd_rep);*/
	obdd_mgr_destroy(new_mgr);
	
}

void casoObddChico() {
	printf( "Test obdd chico\n");
	obdd_mgr* new_mgr	= obdd_mgr_create();

	//compare x1 & !(x2 | x3) == x1 & !x2 & !x3
	obdd* x1_obdd		= obdd_mgr_var(new_mgr, "x1");
	obdd* x2_obdd		= obdd_mgr_var(new_mgr, "x2");
	obdd* x3_obdd		= obdd_mgr_var(new_mgr, "x3");
    	
	obdd* x2_or_x3_obdd	= obdd_apply_or(x2_obdd, x3_obdd);
	obdd* not_x2_or_x3_obdd	= obdd_apply_not(x2_or_x3_obdd);
	obdd* eq1_obdd		= obdd_apply_and(x1_obdd, not_x2_or_x3_obdd);

	//obdd_print(eq1_obdd);

	obdd* not_x2_obdd	= obdd_apply_not(x2_obdd);
	obdd* not_x3_obdd	= obdd_apply_not(x3_obdd);
	obdd* not_x2_and_not_x3_obdd	= obdd_apply_and(not_x2_obdd, not_x3_obdd);
	obdd* eq2_obdd		= obdd_apply_and(x1_obdd, not_x2_and_not_x3_obdd);

	//obdd_print(eq2_obdd);

	obdd* eq1_eq_eq2_obdd	= obdd_apply_equals(eq1_obdd, eq2_obdd);
	
	obdd_print(eq1_eq_eq2_obdd);

	printf("eq1 == eq2 sat? : %s \n", is_sat(new_mgr, eq1_eq_eq2_obdd->root_obdd) ? "yes" : "no");
	printf("eq1 == eq2 taut? : %s \n", is_tautology(new_mgr, eq1_eq_eq2_obdd->root_obdd) ? "yes" : "no");

	obdd* x2_and_not_x2_obdd	= obdd_apply_and(x2_obdd, not_x2_obdd);

	obdd_print(x2_and_not_x2_obdd);

	printf("x2 && !x2 sat? : %s \n", is_sat(new_mgr, x2_and_not_x2_obdd->root_obdd) ? "yes" : "no");
	printf("x2 && !x2 taut? : %s \n", is_tautology(new_mgr, x2_and_not_x2_obdd->root_obdd) ? "yes" : "no");

	obdd_mgr_print(new_mgr);

	obdd_destroy(x1_obdd);
	obdd_destroy(x2_obdd);
	obdd_destroy(x3_obdd);
	obdd_destroy(x2_or_x3_obdd);
	obdd_destroy(not_x2_or_x3_obdd);
	obdd_destroy(eq1_obdd);
	obdd_destroy(not_x2_obdd);
	obdd_destroy(not_x3_obdd);
	obdd_destroy(not_x2_and_not_x3_obdd);
	obdd_destroy(eq2_obdd);
	obdd_destroy(eq1_eq_eq2_obdd);
	obdd_destroy(x2_and_not_x2_obdd);
	obdd_mgr_destroy(new_mgr);
}

void casoObddGrande() {
	printf( "Test obdd grande\n");
	obdd_mgr* new_mgr	= obdd_mgr_create();
	int vars_size		= 10;	
	char *var_name 		= malloc(4 * sizeof(char));
	obdd** obdd_vars_list	= malloc(vars_size * sizeof(obdd*));
	obdd** obdd_func_list	= malloc(vars_size * sizeof(obdd*));


	int i;
	for(i = 0; i < vars_size; i++){
		sprintf(var_name, "x%02d", (i + 1));	
		printf("%s.", var_name);

		obdd_vars_list[i]	= obdd_mgr_var(new_mgr, var_name);
		if(i == 0){
			obdd_func_list[i] = obdd_mgr_var(new_mgr, var_name);
		}else if(i % 2 == 0){
			obdd_func_list[i] = obdd_apply_and(obdd_vars_list[i], obdd_func_list[i-1]);
		}else{
			obdd_func_list[i] = obdd_apply_or(obdd_vars_list[i], obdd_func_list[i-1]);
		}
	}

	


	obdd_print(obdd_func_list[vars_size -1]);
	obdd_mgr_print(new_mgr);

	for(i = 0; i < vars_size; i++){
		obdd_destroy(obdd_vars_list[i]);
		obdd_destroy(obdd_func_list[i]);		
	}

	

	obdd_mgr_destroy(new_mgr);
	free(var_name);
	free(obdd_vars_list);
	free(obdd_func_list);

}
