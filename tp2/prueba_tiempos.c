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

char *archivo_out  =  "tiempos_solver_lin_solve_1pixel.out";
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
	remove(archivo_out);
	FILE *f = fopen(archivo_out,"ab+");
	if(f == NULL){
		printf("error");	
	}
	for(int i = 4; i <= 200; i = i + 4){
		double total_iteracion = 0;
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

			clock_t begin = clock();
			solver_lin_solve(solver, 1, x, x0, 30.0, 15.0);
			clock_t end = clock();
			total_iteracion += (double)(end - begin);
			//printf("iteracion %d\n", iteracion);
		}

		//int pFile;

		total_iteracion = total_iteracion / ITERACIONES;
		//printf("%d %f\n", i, total_iteracion);
		//pFile = open(archivo_out, O_RDWR|O_CREAT|O_APPEND, 0600);
		//if (-1 == dup2(pFile, 1)) { perror("cannot redirect stdout"); return 255; }
		//printf("%d %f\n", i, total_iteracion);
		//fflush(stdout);
		//close( pFile );

		printf("iteracion %d %f\n", i, total_iteracion);
		fprintf(f,"%d %f\n", i, total_iteracion);
		
	}
	
	fclose(f);

	return 0;

}



