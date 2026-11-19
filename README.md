# colmenares-post1-u6

Laboratorio del Post-contenido de la Unidad 6 (Instrucciones y Direccionamiento) de Arquitectura de Computadores, UFPS. Autor: David Camilo Colmenares Hernández.

El repositorio reúne dos programas .COM en NASM para DOSBox. `lab6_instrucciones.asm` recorre las categorías de instrucciones x86 (Parte 1) y `lab6_modos.asm` demuestra los modos de direccionamiento (Parte 2).

## Entorno

- DOSBox 0.74-3 con la carpeta del laboratorio montada como C:.
- NASM 3.02 para DOS con CWSDPMI como servidor DPMI.
- DEBUG 2.51 (clon libre de DEBUG.COM, proyecto DOS-debug de Baron-von-Riedesel), porque DOSBox 0.74 no incluye DEBUG.

Compilación: `nasm -f bin lab6_instrucciones.asm -o lab6_instrucciones.com`.
