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
	for(i = 0 ; i < N ; i++){
		printf("x[%d] = %0.2f \n", i, x[i]);
	}
}

int main(){

	//	N = 256; 	dt = 0.05;	diff = 0.0f;	visc = 0.0f;	force = 20.0f;	source = 600.0f;
	int size = 36;

	solver = solver_create(4, 0.05, 0, 0);

	

	float * x = (float *) malloc ( size*sizeof(float) );

	float * x0 = (float *) malloc ( size*sizeof(float) );

	llenarX(&x, size);
	llenarX(&x0, size);
	
	solver_lin_solve(solver, 1, x, x0, 300.0, 150.0);

	printMatriz(x, size);

	return 0;

}

