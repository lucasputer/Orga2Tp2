#include "solver.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
fluid_solver* solver;

char *archivo_out  =  "salida.caso.tiempos.simd.dat";
int ITERACIONES = 10;

void llenarX(float ** x, int N){
	int i = 0;
	for(i = 0 ; i < N ; i++){
		(*x)[i] = i + 1;
	}
}

void printMatriz(float * x, int N){
	int i = 0;
	for(i = 0 ; i < N ; i++){
		printf("x[%d] = %0.2f \n", i, x[i]);
	}
}

int main(){
	remove(archivo_out);
	//	N = 256; 	dt = 0.05;	diff = 0.0f;	visc = 0.0f;	force = 20.0f;	source = 600.0f;
	for(int i = 4; i <= 4; i = i + 4){
		double total_iteracion;
		for(int iteracion = 0; iteracion < ITERACIONES; i++){
			int inner_size = i;
			int size = (inner_size + 2)*(inner_size + 2);
			solver = solver_create(inner_size, 0.05, 0, 0);

			float * p = (float *) malloc ( size*sizeof(float) );
			float * div = (float *) malloc ( size*sizeof(float) );

			llenarX(&p, size);
			llenarX(&div, size);

			solver_set_initial_density(solver);
			solver_set_initial_velocity(solver);


			clock_t begin = clock();
			solver_project(solver, p, div);
			clock_t end = clock();
			total_iteracion += (double)(end - begin);
		}

		int pFile;

		total_iteracion = total_iteracion / ITERACIONES;
		pFile = open(archivo_out, O_RDWR|O_CREAT|O_APPEND, 0600);
		if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
		printf("%d %f\n", i, total_iteracion);
		fflush(stdout);
		close( pFile );
		printf("%d %f\n", i, total_iteracion);
	}
	

	return 0;

}
