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

char *archivo_out_c  =  "tiempos_solver_lin_solve_c_o3out";
char *archivo_out_asm_1px  =  "tiempos_solver_lin_solve_asm_1px_o3.out";
char *archivo_out_asm_2px  =  "tiempos_solver_lin_solve_asm_2px_o3.out";
char *archivo_out_asm_opt  =  "tiempos_solver_lin_solve_asm_opt_o3.out";
int ITERACIONESDISTINTAS = 100;
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

	double promedio_c = 0;
	double promedio_asm_1 = 0;
	double promedio_asm_2 = 0;
	double promedio_asm_o = 0;

	for(int i = 400; i <= 400; i = i + 8){
		double total_iteracion_c = 0;
		double total_iteracion_asm_1px = 0;
		double total_iteracion_asm_2px = 0;
		double total_iteracion_asm_opt = 0;

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
				total_medicion_c += (double)(end_c - begin_c);


				clock_t begin_asm_1 = clock();
				solver_lin_solve_1pixel_por_lectura(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_1 = clock();
				total_medicion_asm_1px += (double)(end_asm_1 - begin_asm_1);

				clock_t begin_asm_2 = clock();
				solver_lin_solve_2pixel_por_lectura(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_2 = clock();
				total_medicion_asm_2px += (double)(end_asm_2 - begin_asm_2);

				clock_t begin_asm_opt = clock();
				solver_lin_solve_2pixel_optimo(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm_opt = clock();
				total_medicion_asm_opt += (double)(end_asm_opt - begin_asm_opt);
			}
			total_iteracion_c += total_medicion_c/(float)ITERACIONESIGUALES;
			total_iteracion_asm_1px += total_medicion_asm_1px/(float)ITERACIONESIGUALES;
			total_iteracion_asm_2px += total_medicion_asm_2px/(float)ITERACIONESIGUALES;
			total_iteracion_asm_opt += total_medicion_asm_opt/(float)ITERACIONESIGUALES;
		}


		total_iteracion_c = total_iteracion_c / (float)ITERACIONESDISTINTAS;
		total_iteracion_asm_1px = total_iteracion_asm_1px / (float)ITERACIONESDISTINTAS;
		total_iteracion_asm_2px = total_iteracion_asm_2px / (float)ITERACIONESDISTINTAS;
		total_iteracion_asm_opt = total_iteracion_asm_opt / (float)ITERACIONESDISTINTAS;

		promedio_c += total_iteracion_c;
		promedio_asm_1 += total_iteracion_asm_1px;
		promedio_asm_2 += total_iteracion_asm_2px;
		promedio_asm_o += total_iteracion_asm_opt;

		printf("iteracion c %d %f\n", i, total_iteracion_c);
		fprintf(fc,"%d %f\n", i, total_iteracion_c);

		printf("iteracion asm 1px %d %f\n", i, total_iteracion_asm_1px);
		fprintf(fa1,"%d %f\n", i, total_iteracion_asm_1px);

		printf("iteracion asm 2px %d %f\n", i, total_iteracion_asm_2px);
		fprintf(fa2,"%d %f\n", i, total_iteracion_asm_2px);

		printf("iteracion asm opt %d %f\n \n", i, total_iteracion_asm_opt);
		fprintf(fao,"%d %f\n", i, total_iteracion_asm_opt);
		
	}
	
	promedio_c = promedio_c / 1.0f ;
	printf("promedio c %f\n", promedio_c);
	fprintf(fc," %f\n", promedio_c);

	promedio_asm_1 = promedio_asm_1 / 1.0f ;
	printf("promedio asm 1px %f\n", promedio_asm_1);
	fprintf(fa1," %f\n", promedio_asm_1);

	promedio_asm_2 = promedio_asm_2 / 1.0f ;
	printf("promedio asm 2px %f\n", promedio_asm_2);
	fprintf(fa2," %f\n", promedio_asm_2);

	promedio_asm_o = promedio_asm_o / 1.0f ;
	printf("promedio asm opt %f\n", promedio_asm_o);
	fprintf(fao," %f\n", promedio_asm_o);

	fclose(fc);
	fclose(fa1);	
	fclose(fa2);	
	fclose(fao);	

	return 0;

}






