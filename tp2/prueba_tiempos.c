#include "solver.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <stdlib.h>

fluid_solver* solver;

char *archivo_out_c  =  "tiempos_solver_lin_solve_c_o3.out";
char *archivo_out_asm_1px  =  "tiempos_solver_lin_solve_asm_1px_o3.out";
char *archivo_out_asm_2px  =  "tiempos_solver_lin_solve_asm_2px_o3.out";
char *archivo_out_asm_opt  =  "tiempos_solver_lin_solve_asm_opt_o3.out";

int CANTIDADDIMENSIONES = 25;
int SALTO_MEDICION = 4;
int ITERACIONESDISTINTAS = 10;
int ITERACIONESIGUALES = 100;

void llenarX(float ** x, int N){
	srand(time(NULL));
	int i = 0;
	for(i = 0 ; i < N ; i++){
		float random = rand() % 256;  //floats entre 0 y 255
		(*x)[i] = random;  
	}
}

void printMatriz(float * x, int N){
	int i = 0;
	for(i = 0 ; i < N ; i++){
		printf("x[%d] = %0.2f \n", i, x[i]);
	}
}

int main(){
	remove(archivo_out_c);
	remove(archivo_out_asm_1px);
	remove(archivo_out_asm_2px);
	remove(archivo_out_asm_opt);
	
	FILE *fc = fopen(archivo_out_c,"ab+"); 
	FILE *fa1 = fopen(archivo_out_asm_1px,"ab+");
	FILE *fa2 = fopen(archivo_out_asm_2px,"ab+");
	FILE *fao = fopen(archivo_out_asm_opt,"ab+");

	if(fc == NULL){
		printf("error");	
	}

	for(int i = SALTO_MEDICION; i <= SALTO_MEDICION*CANTIDADDIMENSIONES; i = i + SALTO_MEDICION){

		for(int iteracion = 0; iteracion < ITERACIONESDISTINTAS; iteracion++){
			int inner_size = i;
			int size = (inner_size + 2)*(inner_size + 2);
			solver = solver_create(inner_size, 0.05, 0, 0);

			float * x = (float *) malloc ( size*sizeof(float) );
			float * x0 = (float *) malloc ( size*sizeof(float) );

			llenarX(&x, size);
			llenarX(&x0, size);

			solver_set_initial_density(solver);
			solver_set_initial_velocity(solver);
			int total_medicion_c = 0;
			int total_medicion_asm_1px = 0;
			int total_medicion_asm_2px = 0;
			int total_medicion_asm_opt = 0;
			for(int j = 0; j < ITERACIONESIGUALES ; j++){
				clock_t begin_c = clock();
				solver_lin_solve(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_c = clock();
				total_medicion_c += (end_c - begin_c);

				clock_t begin_asm_1 = clock();
				solver_lin_solve_1pixel_por_lectura(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_1 = clock();
				total_medicion_asm_1px += (end_asm_1 - begin_asm_1);

				clock_t begin_asm_2 = clock();
				solver_lin_solve_2pixel_por_lectura(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_2 = clock();
				total_medicion_asm_2px += (end_asm_2 - begin_asm_2);

				clock_t begin_asm_opt = clock();
				solver_lin_solve_2pixel_optimo(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_opt = clock();
				total_medicion_asm_opt += (end_asm_opt - begin_asm_opt);
				
				fprintf(fc,"%i\n", total_medicion_c);

				fprintf(fa1,"%i\n", total_medicion_asm_1px);

				fprintf(fa2,"%i\n", total_medicion_asm_2px);

				fprintf(fao,"%i\n", total_medicion_asm_opt);
			}
		}
		printf("iteracion %i\n", i);
	}


	fclose(fc);
	fclose(fa1);	
	fclose(fa2);	
	fclose(fao);	

	return 0;

}






