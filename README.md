# Proyecto Final de Arquitectura de Computadores (CS3501)

Este repositorio contiene la implementación del proyecto final para el curso CS3501 - Arquitectura de Computadores. El objetivo es extender la funcionalidad de un microprocesador implementado en laboratorio.

### Miembros del Equipo
* Tamy Flores
* Nicolas Stigler

## Estructura del Proyecto

El proyecto se divide en tres entregas principales:

**P0**: Microprocesador Multiciclo con MUL\
**P1**: Instrucciones de Multiplicación y División Entera\
**P2**: Implementación de Unidad de Punto Flotante (FPU) y FPGA

## Lista de Tareas y Avance
### Entrega P0: Multiciclo con MUL (2 Puntos)
#### Hardware (Verilog):
- [x] Completar el Control Unit del MultiCycle processor.
- [x] Completar el módulo del datapath.
- [x] Implementar la instrucción MUL.
#### Pruebas (Testbenches):
- [x] Verificar que las instrucciones del Single Cycle Challenge funcionen correctamente.
- [x] Probar la nueva instrucción MUL.
#### Entregables:
- [x] Reporte corto en PDF describiendo la implementación, resultados y código.
- [x] Proyecto de Verilog con código comentado.
- [x] Comprimir todo en un archivo `PO.zip`.

### Entrega P1: Instrucciones Adicionales (3 Puntos)
#### Hardware (Verilog):
- [x] Implementar las instrucciones UMUL, SMUL y DIV.
#### Software (ASM):
- [ ] Crear un programa en assembly que utilice las nuevas instrucciones (UMUL, SMUL, DIV).
#### Pruebas (Testbenches):
- [ ] Crear un testbench en Verilog para verificar las nuevas instrucciones.
#### Entregables:
- [ ] Presentación de 10 minutos explicando el funcionamiento del microprocesador MultiCycle y la implementación de las nuevas instrucciones.
- [ ] Reporte corto describiendo la implementación.
- [ ] Diapositivas de la presentación (PPT).
- [ ] Proyecto de Verilog con código comentado.
- [ ] Comprimir todo en un archivo `P1.zip`.

### Entrega P2: Final (16 Puntos)
#### Hardware (Verilog):
- [ ] Implementar una Unidad de Punto Flotante (FPU) como un bloque separado del ALU.
- [ ] Implementar la instrucción ADD de punto flotante para precisión simple (32-bit) y media (16-bit).
- [ ] Implementar la instrucción MUL de punto flotante para precisión simple (32-bit) y media (16-bit).
- [ ] Manejar el desbordamiento (overflow) mediante la definición de un flag.
#### Software (ASM):
- [ ] Crear un programa en assembly que utilice las instrucciones de punto flotante.
#### Pruebas y Despliegue:
- [ ] Crear un testbench en Verilog para verificar las instrucciones de punto flotante.
- [ ] Implementar el microprocesador completo en la FPGA (Basys3).
#### Entregables:
- [ ] Presentación final de 15 minutos explicando el microprocesador, la implementación de las nuevas instrucciones y la implementación en la FPGA.
- [ ] Reporte final en PDF con la descripción completa, resultados y código.
- [ ] Diapositivas de la presentación (PPT).
- [ ] Proyecto de Verilog con código comentado.
- [ ] Comprimir todo en un archivo `P1.tar`.

## Entrega:
![timer](https://i.countdownmail.com/4aqwbt.gif)
