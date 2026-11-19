# colmenares-post1-u6

Laboratorio del Post-contenido de la Unidad 6 (Instrucciones y Direccionamiento) de Arquitectura de Computadores, UFPS. Autor: David Camilo Colmenares Hernández.

El repositorio reúne dos programas .COM en NASM para DOSBox. `lab6_instrucciones.asm` recorre las categorías de instrucciones x86 (Parte 1) y `lab6_modos.asm` demuestra los modos de direccionamiento (Parte 2).

## Entorno

- DOSBox 0.74-3 con la carpeta del laboratorio montada como unidad D:.
- NASM 3.02 para DOS con CWSDPMI como servidor DPMI (`cwsdpmi -p` antes de ensamblar).
- DEBUG 2.51 (clon libre de DEBUG.COM, proyecto DOS-debug de Baron-von-Riedesel), porque DOSBox 0.74 no incluye DEBUG.

```
D:\> nasm -f bin lab6_i~1.asm -o instr.com
D:\> nasm -f bin lab6_m~1.asm -o modos.com
D:\> debug instr.com
```

DOS solo admite nombres 8.3, así que DOSBox muestra `lab6_instrucciones.asm` como `LAB6_I~1.ASM` y `lab6_modos.asm` como `LAB6_M~1.ASM`. Los ejecutables se generaron como `INSTR.COM` (173 bytes) y `MODOS.COM` (208 bytes) y se guardan en el repositorio con el nombre largo de su fuente; el contenido es idéntico.

## Estructura

```
colmenares-post1-u6/
├── lab6_instrucciones.asm / .com   Parte 1
├── lab6_modos.asm / .com           Parte 2
├── COMPILA.BAT                     ensamblado de ambos programas
├── dosbox_lab.conf                 configuración de DOSBox
├── capturas/                       evidencia de DEBUG en DOSBox
└── README.md
```

## Parte 1: Categorías de instrucciones

El programa salta sobre sus datos (`valor_a` = 45 en 0102h; `valor_b` = 12 en 0104h; `resultado` en 0106h; `mascara` = 0Fh en 0109h) y ejecuta cinco bloques. Termina con `INT 20h`.

| Bloque | Instrucciones | Registros y banderas observados |
|--------|---------------|---------------------------------|
| 1. Transferencia | MOV, LEA, XCHG, PUSH/POP | SI = 0102h tras `LEA si, [valor_a]`; AX = 002Dh tras `MOV ax, [si]`; AX vuelve a 002Dh tras el POP |
| 2. Aritmética | ADD, SUB, INC, DEC, MUL, DIV | ADD: AX = 0039h (57), NV PL NZ AC PE NC. SUB: AX = FFDFh (−33), NV NG NZ AC PO CY. MUL: AX = 0046h (70). DIV: AX = 020Eh (AH = 2, AL = 14) |
| 3. Lógica | AND, OR, XOR, TEST, SHL, SHR | AND: AL = 07h, NV PL NZ PO NC. OR: AL = F7h. XOR: AL = 55h. TEST AL,01h: NZ con AL intacto en B7h. SHL/SHR: AL = 20h y luego 10h |
| 4. Control de flujo | CMP, JG, JE, JMP, LOOP | CMP 45 − 12: NV PL NZ NA PE NC; JG salta y CX = 1. Bucle: AX = 000Fh (15) al salir de LOOP |
| 5. Rotación | SHL, ROL, SHR, ROR | BL = 02h, CL = 03h, DL = 40h, BH = C0h, cada uno con CY. `ROL al, 4` sobre A5h deja AL = 5Ah |

La resta del bloque 2 activa también CF porque 12 − 45 exige préstamo; la guía solo menciona SF. El `MUL bl` de 8 bits deja todo el producto en AX y no toca DX; el comentario de la guía que habla de DX corresponde a la versión de 16 bits.

### Variante factorial

El commit "Se agregó la variante factorial del bucle" añade después de la suma un segundo bucle con AX = 1, CX = 5 y BX = 1. Cada vuelta ejecuta `MUL bx` e `INC bx`, así que el producto acumulado es 1 × 2 × 3 × 4 × 5 = 120. Al salir, AX = 0078h y DX = 0000h porque el resultado cabe en 16 bits. La suma original se conserva para que el checkpoint de AX = 15 siga siendo verificable en el mismo programa.

### Decisión técnica 1: SHL/SHR frente a ROL/ROR

SHL y SHR son las instrucciones correctas para aritmética. Desplazar un bit a la izquierda multiplica por 2 y desplazarlo a la derecha divide por 2 sin signo, como en el bloque 3 (8 → 20h → 10h); el bit que sale no forma parte del resultado numérico y basta con consultarlo en CF si hubo desbordamiento. ROL y ROR son las correctas cuando ningún bit puede perderse: el intercambio de nibbles del bloque 5, un cifrado por rotación o un checksum circular que debe ser reversible. Con AL = 81h, `SHL al, 1` saca el bit 7 del registro; el resultado es 02h y ese 1 sobrevive solo en CF hasta la siguiente instrucción que modifique banderas. `ROL al, 1` sobre el mismo valor devuelve 03h; el bit 7 reaparece como bit 0 y CF guarda una copia. SHL nunca puede intercambiar nibbles. Cada desplazamiento a la izquierda descarta los bits altos y rellena con ceros por la derecha; después de `SHL al, 4` el nibble alto A ya no existe en el registro y ningún OR posterior puede reconstruirlo sin una copia previa en otro registro. `ROL al, 4` hace el intercambio en una sola instrucción de 3 bytes (C0 C0 04). La diferencia de destino del bit saliente es exactamente el criterio de elección.

### Decisión técnica 2: LOOP frente a DEC/JNZ

LOOP es más compacta y más legible. Codifica en 2 bytes (E2 desplazamiento) lo que DEC/JNZ expresa con 3 bytes (49 para `DEC cx` y 75 desplazamiento para `JNZ`), y el lector entiende de inmediato que CX es el contador. Sin embargo el número de instrucciones del código fuente no indica cuántos ciclos tarda el procesador. Cada instrucción tiene su propio costo de decodificación y de ejecución; en los procesadores Intel modernos LOOP se implementa con varias micro-operaciones mientras que DEC y JNZ son simples y además pueden fusionarse en una sola micro-operación. Por eso una instrucción puede costar más que dos. En el bucle de 5 iteraciones del bloque 4 la diferencia no se percibe; son unos pocos ciclos en un programa que tarda microsegundos. La respuesta cambia si el bucle se ejecuta millones de veces dentro de un programa mayor. Allí la diferencia por iteración se multiplica por el número de vueltas y DEC/JNZ es la opción razonable para la ruta crítica. La decisión es mantener LOOP en este laboratorio por claridad y usar DEC/JNZ cuando el perfilado señale el bucle como crítico.

## Parte 2: Modos de direccionamiento

Los datos ocupan 0102h a 0135h: `array` en 0102h (0A00 1400 1E00 2800 3200 en little-endian); `nota1` en 010Ch (5500h); `nota2` en 010Eh (4900h); `promedio` en 0110h; `var_x` en 0112h; `tabla_hex` en 0114h y `matriz` en 0124h.

| Modo | Dirección efectiva | Instrucción NASM | Valor observado |
|------|--------------------|------------------|-----------------|
| Inmediato | No hay; el dato viaja en la instrucción | `MOV ax, 100` | AX = 0064h (B8 64 00) |
| Directo | Desplazamiento fijo | `MOV ax, [var_x]` | AX = FFFFh, leída de 0112h |
| Indirecto por registro | SI | `MOV ax, [si]` con SI = 010Ch | AX = 0055h (85) |
| Indexado | BX + SI | `MOV ax, [bx + si]` con BX = 0102h, SI = 4 | AX = 001Eh (30) |
| Base + desplazamiento | BX + 4 | `MOV dx, [bx + 4]` con BX = 010Ch | DX = 004Fh (79) |
| Indirecto con BP | SS:BP − 4 | `ADD ax, [bp - 4]` | AX = 015Dh (349) |
| Matriz 2D | BX + SI con SI = fila × 6 + columna × 2 | `MOV dx, [bx + si]` con SI = 000Ah | DX = 0006h |

Traza del modo indirecto:

| Instrucción | Registro modificado | Valor resultante |
|-------------|---------------------|------------------|
| `MOV si, nota1` | SI | 010Ch |
| `MOV ax, [si]` | AX | 0055h |
| `MOV si, nota2` | SI | 010Eh |
| `MOV bx, [si]` | BX | 0049h |
| `ADD ax, bx` | AX | 009Eh (158) |
| `SHR ax, 1` | AX | 004Fh (79) |
| `MOV [si], ax` con SI = 0110h | mem[0110h] | 4F 00 |

El bucle indexado deja AX = 0096h (150). El commit "feat: recorrido inverso del array" agrega un segundo bucle que arranca con SI = 8 y resta 2 en cada vuelta; también termina con AX = 0096h.

En el marco de pila SP baja 4 bytes con `SUB sp, 4`; el volcado de SS:BP−4 muestra FA 00 63 00 (250 y 99 en little-endian) y BP recupera su valor original tras `MOV sp, bp` y `POP bp`.

### Decisión técnica 3: modo directo frente a indexado para una posición fija

matriz[1][2] tiene una posición conocida al ensamblar: 0124h + 1 × 6 + 2 × 2 = 012Eh. El modo directo la resuelve con una sola instrucción, `MOV dx, [matriz + 10]`, cuya dirección efectiva viaja en el código y no requiere cálculo en tiempo de ejecución. El bloque indexado del paso 7 paga antes de leer el dato un MUL, dos SHL, un ADD y tres MOV adicionales; además MUL es una de las instrucciones más lentas del 8086 y destruye DX. Para un elemento fijo ese trabajo es puro costo. El indexado se vuelve indispensable cuando la fila o la columna solo se conocen en tiempo de ejecución, por ejemplo dentro de un bucle que recorre la matriz o cuando el índice proviene de una entrada del usuario. Recorrer las 9 posiciones con 9 etiquetas directas sería impráctico: el código crecería con el tamaño de la matriz, cualquier cambio de dimensiones obligaría a reescribirlo y no podría expresarse como bucle. Un solo bucle indexado que avance SI de 2 en 2 recorre los 18 bytes con el mismo código para cualquier tamaño. La regla es usar el directo para lo fijo y el indexado para lo que depende de una variable.

### Decisión técnica 4: BP frente a BX/SI

La arquitectura x86 asigna a BP el segmento de pila SS por defecto y a BX, SI y DI el segmento de datos DS. La convención existe porque BP se diseñó como puntero de marco: parámetros y variables locales viven en la pila y deben alcanzarse con desplazamientos fijos desde BP aunque SP cambie. BX/SI/DI recorren estructuras en el segmento de datos. En el .COM de este laboratorio CS = DS = ES = SS, así que `[bp - 2]` y `[bx - 2]` apuntan al mismo segmento y el resultado observable es idéntico. En un .EXE con segmentos separados DS ≠ SS. Si el código asumiera que `[bp + 4]` lee el mismo segmento que `[bx + 4]`, leería la pila en lugar de los datos o escribiría sobre ella; el error no produce ninguna excepción en modo real y aparece como datos corruptos o un retorno a una dirección basura. Para forzar a BP a usar DS se escribe un prefijo de sobrescritura de segmento, `mov ax, [ds:bp + 2]`, que NASM codifica con el byte 3Eh. Tiene sentido cuando BP se usa como puntero general a una estructura de datos en DS, por ejemplo en una rutina que se quedó sin registros base libres. La regla es reservar BP para el marco de pila y declarar el segmento explícitamente cuando se use para otra cosa.

## Desviaciones respecto a la guía

| Punto de la guía | Lo observado en DEBUG | Tratamiento |
|------------------|-----------------------|-------------|
| Bloque 2: la resta 12 − 45 solo activa SF | `SUB` deja AX = FFDFh con NG y también CY, porque la resta exige préstamo | Se documentan ambas banderas en la tabla de la Parte 1 |
| Bloque 2: el comentario de `MUL bl` dice que DX recibe la parte alta | `MUL` de 8 bits deja el producto completo en AX (0046h) y DX no cambia | Se conserva el código; el comentario corresponde a la versión de 16 bits |
| Comandos de ensamblado con nombres largos | DOS solo admite nombres 8.3; DOSBox muestra `LAB6_I~1.ASM` y `LAB6_M~1.ASM` | `COMPILA.BAT` usa los nombres cortos y los .COM se suben con el nombre largo de su fuente |
| DEBUG disponible en DOSBox | DOSBox 0.74-3 no incluye DEBUG.COM | Se usa DEBUG 2.51 del proyecto DOS-debug con la misma sintaxis de comandos |
| Checkpoint 3: modificar el bucle de suma reemplazando ADD por MUL | Reemplazarlo eliminaba la evidencia de AX = 15 del checkpoint 2 | El factorial se agrega como segundo bucle y la suma se conserva |

## Capturas

| Captura | Contenido |
|---------|-----------|
| `capturas/p1-cp1-compilacion.png` | Ensamblado sin errores de lab6_instrucciones.asm |
| `capturas/p1-cp2-flags.png` | Traza en DEBUG de ADD, SUB, AND, TEST y CMP con sus banderas |
| `capturas/p1-cp2-ax15.png` | AX = 000F al terminar el bucle de suma |
| `capturas/p1-cp3-factorial.png` | AX = 0078 al terminar la variante factorial |
| `capturas/p1-cp4-rotacion.png` | BL = 02, CL = 03, DL = 40, BH = C0 y AL = 5A |
| `capturas/p2-cp1-dump.png` | `D DS:100` con el arreglo y las notas |
| `capturas/p2-cp2-indirecto.png` | Traza del modo indirecto |
| `capturas/p2-cp3-indexado.png` | AX = 0096 en los bucles directo e inverso |
| `capturas/p2-cp4-marco-bp.png` | SP, BP y volcado de SS:BP−4 |
| `capturas/p2-cp5-matriz.png` | Volcado de la matriz y DX = 0006 |
| `capturas/p2-cp5-si.png` | SI = 000A antes de leer matriz[1][2] |

## Referencias

- NASM Development Team. (s.f.). *NASM — The Netwide Assembler: documentación*. https://www.nasm.us/doc/
- Cloutier, F. (s.f.). *x86 and amd64 instruction reference*. https://www.felixcloutier.com/x86/
- Fog, A. (2026). *Instruction tables* y *The microarchitecture of Intel, AMD and VIA CPUs*. https://www.agner.org/optimize/
