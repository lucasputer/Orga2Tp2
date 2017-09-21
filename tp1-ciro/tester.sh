#!/bin/bash
clear

echo " "
echo "**Compilando"

make tester
if [ $? -ne 0 ]; then
  echo "  **Error de compilacion"
  exit 1
fi

echo " "
echo "**Corriendo Valgrind"

valgrind --show-reachable=yes --leak-check=full --error-exitcode=1 ./tester
if [ $? -ne 0 ]; then
  echo "  **Error de memoria"
  exit 1
fi

echo " "
echo "**Corriendo diferencias con la catedra"

DIFFER="diff -d"
ERRORDIFF=0

$DIFFER salida.caso.mgr.txt Catedra.salida.caso.mgr.txt > /dev/null
if [ $? -ne 0 ]; then
  echo "  **Discrepancia en el caso MGR: salida.caso.mgr.txt vs Catedra.salida.caso.mgr.txt"
  ERRORDIFF=1
fi

$DIFFER salida.caso.obdd.chico.txt Catedra.salida.caso.obdd.chico.txt > /dev/null
if [ $? -ne 0 ]; then
  echo "  **Discrepancia en el caso RED CHICA: salida.caso.obdd.chico.txt vs Catedra.salida.caso.obdd.chico.txt"
  ERRORDIFF=1
fi

$DIFFER salida.caso.obdd.grande.txt Catedra.salida.caso.obdd.grande.txt > /dev/null
if [ $? -ne 0 ]; then
  echo "  **Discrepancia en el caso OBDD GRANDE: salida.caso.obdd.grande.txt vs Catedra.salida.caso.obdd.grande.txt"
  ERRORDIFF=1
fi

echo " "
if [ $ERRORDIFF -eq 0 ]; then
  echo "**Todos los tests pasan"
fi
echo " "
