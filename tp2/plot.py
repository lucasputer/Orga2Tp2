import pandas as pd
import numpy as np
import random
import matplotlib.pyplot as plt
import seaborn as sns; sns.set_style("darkgrid")
import csv
from scipy import stats


tamanios = 25
salto_medicion = 32
distintos = 10
iguales = 50 

optimizacion = "3"

def procesarTiempos(direccion):
	with open(direccion, 'r') as my_file:
	    reader = csv.reader(my_file, delimiter='\n')
	    my_list = list(reader)

	    tiempos = []
	    for numero in my_list:
	    	tiempos.append(int(numero[0]) )

	    mediciones = []
	    for tam in range(0,tamanios):
	    	list_distintos = []
	    	for dist in range(0, distintos):
	    		list_iguales = []
	    		for igu in range(0,iguales):
	    			list_iguales.append(tiempos[tam*distintos*iguales + dist*iguales + igu])
	    		list_distintos.append(min(list_iguales))
	     	mediciones.append(np.median(list_distintos))

	return mediciones


def guardarTiempos(direccion, ejex, ejey):
	with open(direccion, 'w') as my_file:
		for i in range(len(ejex)):
			my_file.write(str(ejex[i]) + ' ' + str(ejey[i]) + '\n')

mediciones_o0 = procesarTiempos("output/solver_lin_solve_c_o0.out")
mediciones_o1 = procesarTiempos("output/solver_lin_solve_c_o1.out")
mediciones_o2 = procesarTiempos("output/solver_lin_solve_c_o2.out")
mediciones_o3 = procesarTiempos("output/solver_lin_solve_c_o3.out")
'''
print(mediciones_o0)
print(mediciones_o1)
print(mediciones_o2)
print(mediciones_o3)
'''

eje_x = [(i+1)*salto_medicion for i in range(0, tamanios)]

#plt.clf()
#df = pd.DataFrame({'Dimensiones': eje_x[0:13], '1px': mediciones_o1[0:13], '2px': mediciones_o2[0:13], 'vertical': mediciones_o3[0:13], 'C': mediciones_o0[0:13]})
o0 = pd.DataFrame({'x': eje_x[0:13], 'y': mediciones_o0[0:13]})
o1 = pd.DataFrame({'x': eje_x[0:13], 'y': mediciones_o1[0:13]})
o2 = pd.DataFrame({'x': eje_x[0:13], 'y': mediciones_o2[0:13]})
o3 = pd.DataFrame({'x': eje_x[0:13], 'y': mediciones_o3[0:13]})
	

sns.tsplot(time=o0['x'], data=o0['y'], interpolate=True, color="green" , marker='x').set_ylabel('Tiempo (Nanosegundos)')
sns.tsplot(time=o1['x'], data=o1['y'], interpolate=True, color="blue").set_xlabel('Dimension')
sns.tsplot(time=o2['x'], data=o2['y'], interpolate=True, color="yellow").set_xlabel('Dimension')
sns.tsplot(time=o3['x'], data=o3['y'], interpolate=True, color="red").set_xlabel('Dimension')	

plt.title("Solver_lin_solve con distintas optimizaciones de c")

plt.show()









'''
guardarTiempos("output/tiempos_procesados_lin_c_o"+optimizacion+".out", eje_x, mediciones_o0)
guardarTiempos("output/tiempos_procesados_lin_asm_1px_o"+optimizacion+".out", eje_x, mediciones_o1)
guardarTiempos("output/tiempos_procesados_lin_asm_2px_o"+optimizacion+".out", eje_x, mediciones_o2)
guardarTiempos("output/tiempos_procesados_lin_asm_opt_o"+optimizacion+".out", eje_x, mediciones_o3)

c = pd.read_csv("output/tiempos_procesados_lin_c_o"+optimizacion+".out", sep=' ')
simd1 = pd.read_csv("output/tiempos_procesados_lin_asm_1px_o"+optimizacion+".out", sep=' ')
simd2 = pd.read_csv("output/tiempos_procesados_lin_asm_2px_o"+optimizacion+".out", sep=' ')
simdo = pd.read_csv("output/tiempos_procesados_lin_asm_opt_o"+optimizacion+".out", sep=' ')

g = sns.lmplot(x="Dimension", y="Tiempo", data=c)
#.set_ylabel('Tiempo (Nanosegundos)')

sns.lmplot(time=simd1['x'], data=simd1['tiempo'], interpolate=True, color="yellow").set_xlabel('Dimension')
sns.lmplot(time=simd2['x'], data=simd2['tiempo'], interpolate=True, color="blue")
sns.lmplot(time=simdo['x'], data=simdo['tiempo'], interpolate=True, color="red")
'''
# sns.show()


