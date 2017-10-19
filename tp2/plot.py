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

optimizacion = "0"

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

mediciones_c = procesarTiempos("output/tiempos_solver_lin_solve_c_o"+optimizacion+".out")
mediciones_1px = procesarTiempos("output/tiempos_solver_lin_solve_asm_1px_o"+optimizacion+".out")
mediciones_2px = procesarTiempos("output/tiempos_solver_lin_solve_asm_2px_o"+optimizacion+".out")
mediciones_opt = procesarTiempos("output/tiempos_solver_lin_solve_asm_opt_o"+optimizacion+".out")

'''
print(mediciones_c)
print(mediciones_1px)
print(mediciones_2px)
print(mediciones_opt)
'''

eje_x = [(i+1)*salto_medicion for i in range(0, tamanios)]

#plt.clf()
df = pd.DataFrame({'Dimensiones': eje_x, '1px': mediciones_1px, '2px': mediciones_2px, 'vertical': mediciones_opt, 'C': mediciones_c})
df.plot(x='Dimensiones')
plt.ylabel('Tiempo (microsegundos)')
plt.title("Mediciones de tiempo de solver_lin_solve con O"+optimizacion+".")
plt.show()









'''
guardarTiempos("output/tiempos_procesados_lin_c_o"+optimizacion+".out", eje_x, mediciones_c)
guardarTiempos("output/tiempos_procesados_lin_asm_1px_o"+optimizacion+".out", eje_x, mediciones_1px)
guardarTiempos("output/tiempos_procesados_lin_asm_2px_o"+optimizacion+".out", eje_x, mediciones_2px)
guardarTiempos("output/tiempos_procesados_lin_asm_opt_o"+optimizacion+".out", eje_x, mediciones_opt)

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


