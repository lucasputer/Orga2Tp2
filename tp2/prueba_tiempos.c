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

char *archivo_out_asm  =  "tiempos_solver_lin_solve_asm.out";
char *archivo_out_c  =  "tiempos_solver_lin_solve_c.out";
int ITERACIONES = 10;




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
	remove(archivo_out_asm);
	FILE *fc = fopen(archivo_out_c,"ab+");
	FILE *fa = fopen(archivo_out_asm,"ab+");
	if(fc == NULL){
		printf("error");	
	}
	for(int i = 4; i <= 200; i = i + 4){
		double total_iteracion_c = 0;
		double total_iteracion_asm = 0;
		for(int iteracion = 0; iteracion < ITERACIONES; iteracion++){
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
			int total_medicion_asm = 0;
			for(int j = 0; j < 10 ; j++){
				clock_t begin_c = clock();
				solver_lin_solve(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_c = clock();
				total_medicion_c += (double)(end_c - begin_c);


				clock_t begin_asm = clock();
				solver_lin_solve_1pixel_por_lectura(solver, 1, x, x0, 30.0, 15.0);
				clock_t end_asm = clock();
				total_medicion_asm += (double)(end_asm - begin_asm);
			}
			total_iteracion_c += total_medicion_c/10.0f;				
			total_iteracion_asm += total_medicion_asm/10.0f;				
			//printf("iteracion %d\n", iteracion);
		}

		//int pFile;

		total_iteracion_c = total_iteracion_c / ITERACIONES;
		total_iteracion_asm = total_iteracion_asm / ITERACIONES;
		//printf("%d %f\n", i, total_iteracion);
		//pFile = open(archivo_out, O_RDWR|O_CREAT|O_APPEND, 0600);
		//if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
		//printf("%d %f\n", i, total_iteracion);
		//fflush(stdout);
		//close( pFile );

		printf("iteracion c %d %f\n", i, total_iteracion_c);
		fprintf(fc,"%d %f\n", i, total_iteracion_c);
		printf("iteracion asm %d %f\n", i, total_iteracion_asm);
		fprintf(fa,"%d %f\n", i, total_iteracion_asm);
		
	}
	
	fclose(fc);
	fclose(fa);	

	return 0;

}






