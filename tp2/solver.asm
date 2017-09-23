%define NULL 0

%define OFFSET_FLUID_SOLVER_N 0
%define OFFSET_FLUID_SOLVER_DT 4
%define OFFSET_FLUID_SOLVER_DIFF 8
%define OFFSET_FLUID_SOLVER_VISC 12
%define OFFSET_FLUID_SOLVER_U 20
%define OFFSET_FLUID_SOLVER_V 28
%define OFFSET_FLUID_SOLVER_U_PREV 36
%define OFFSET_FLUID_SOLVER_V_PREV 44
%define OFFSET_FLUID_SOLVER_DENS 52
%define OFFSET_FLUID_SOLVER_DENS_PREV 60
%define FLUID_SOLVER_SIZE 60

extern malloc
extern free
extern solver_set_bnd

; void solver_lin_solve ( fluid_solver* solver, uint32_t b, float * x, float * x0, float a, float c ){
; IX = ((i)+(solver->N+2)*(j))
; 	uint32_t i, j, k;
; 	for ( k=0 ; k<20 ; k++ ) {
; 		for ( i=1 ; i<=solver->N ; i++ ) {
;			 for ( j=1 ; j<=solver->N ; j++ ) {
; 				x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
; 			}
;		}
; 		solver_set_bnd ( solver, b, x );
; 	}
; }
global solver_lin_solve
solver_lin_solve:


ret

