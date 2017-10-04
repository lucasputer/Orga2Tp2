#include "solver.h"

fluid_solver* solver;

void llenarX(float ** x, int N){
	int i = 0;
	for(i = 0 ; i < N ; i++){
		(*x)[i] = i + 1;
	}
}

void printMatriz(float * x, int N){
	int i = 0;
	int j = 0;
	float n = sqrt(N);
	int filas = (int)(n);
	int columnas = filas;
	for(i = 0 ; i < filas ; i++){
		for(j = 0 ; j < columnas ; j++) {
			printf("x[%d] = %0.2f\t", (j + i*filas), x[j + i*filas]);
		}
		printf("\n");
	}
}

int main(){

	//	N = 256; 	dt = 0.05;	diff = 0.0f;	visc = 0.0f;	force = 20.0f;	source = 600.0f;
	int size = 100;

	solver = solver_create(8, 0.05, 0, 0);

	

	float * p = (float *) malloc ( size*sizeof(float) );

	float * div = (float *) malloc ( size*sizeof(float) );

	float * p2 = (float *) malloc ( size*sizeof(float) );

	float * div2 = (float *) malloc ( size*sizeof(float) );

	llenarX(&p, size);
	llenarX(&div, size);
	llenarX(&p2, size);
	llenarX(&div2, size);
	
	//solver_lin_solve(solver, 1, x, x0, 300.0, 150.0);
	solver_set_initial_density(solver);
	solver_set_initial_velocity(solver);

	// printf("----- p original -----\n");
	// printMatriz(p, size);
	// printf("----- div original -----\n");
	// printMatriz(div,size);
	// printf("----- p2 original -----\n");
	// printMatriz(p2, size);
	// printf("----- div2 original -----\n");
	// printMatriz(div2,size);


	solver_project(solver, p, div);
	//solver_project2(solver, p2, div2);
	
	// solver_advect ( solver, 1, solver->u, u0, u0, v0);
	// printf("----- p mia -----\n");
	// printMatriz(p, size);
	// printf("----- p catedra -----\n");
	// printMatriz(p2, size);
	printf("----- u mia -----\n");
	printMatriz(solver->u, size);
	printf("----- v mia -----\n");
	printMatriz(solver->v, size);
	// printf("----- div catedra -----\n");
	// printMatriz(div2, size);

	// printMatriz(x2, size);

	// printMatriz(x0, size);
	// printMatriz(x02, size);



	return 0;

}

