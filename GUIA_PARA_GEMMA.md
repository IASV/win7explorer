# Guía paso a paso para Gemma 4 e4b

## Objetivo final

Tu objetivo es dejar funcionando una aplicación de escritorio en Linux que imite visual y funcionalmente al Explorador de Windows 7.

No debes inventar el diseño.
La guía visual ya existe en la carpeta `html/`.
La app real debe implementarse en **Qt6 QML + C++**, no en web.

## Qué es este proyecto

Este proyecto busca crear un explorador de archivos para Linux con apariencia y comportamiento similares al Explorador de Windows 7.

Hay dos partes importantes:

1. `html/`
   Contiene un preview visual en web.
   Esa carpeta es la referencia visual de cómo debe verse la interfaz final.

2. `qml/`, `src/`, `resources/`, `CMakeLists.txt`
   Aquí está la aplicación real en Qt/QML/C++.
   Ya existe bastante trabajo avanzado: ventana, backend, navegación, operaciones de archivos, paneles y componentes.

## Regla visual obligatoria

Ya existe un prototipo visual del explorador en HTML:

[`html/Explorador.html`](html/Explorador.html)

Ese archivo no es opcional ni solo una inspiración vaga.
Debe usarse como **guía visual obligatoria** de cómo debe verse el explorador final.

Eso significa:

1. la distribución visual general debe seguir ese prototipo
2. los paneles, barras, jerarquías y proporciones deben parecerse a ese prototipo
3. los colores, espaciados y estilo Win7 deben alinearse con ese prototipo
4. la implementación final debe hacerse en QML/C++, pero el resultado visual debe acercarse obligatoriamente a `html/Explorador.html`

Si hay dudas sobre cómo debe verse una parte de la interfaz, la referencia principal es `html/Explorador.html`.

## Estado actual real

Según el proyecto y las pruebas actuales:

1. La app compila.
2. La ventana se abre.
3. La UI real no se muestra correctamente.
4. Cuando se reemplaza temporalmente el contenido por un texto de prueba o mensaje de bienvenida, sí se muestra.

Eso significa que el problema principal no es la creación de la ventana.
El problema está en la carga/renderizado de la UI QML, en imports, tema, bindings, layout o algún componente que rompe la interfaz.

## Archivos que debes leer primero

Lee estos archivos en este orden:

1. `README.md`
   Para entender el propósito, tecnologías y estructura.

2. `PROJECT_ROADMAP.md`
   Para saber qué ya se implementó y no rehacer trabajo.

3. `COMO_USAR.md`
   Para ver cómo se compila, ejecuta y cuál es el estado funcional esperado.

4. `html/Explorador.html`
   Es la referencia visual obligatoria de cómo debe quedar el explorador.

5. `html/styles.css`
   Para revisar colores, tamaños, espaciados y look & feel que deben replicarse en QML.

6. `qml/main.qml`
   Es el centro de la UI real.

7. `src/main.cpp`
   Aquí se inicializa Qt, el backend y la carga de QML.

8. `CMakeLists.txt`
   Para revisar cómo se registra el módulo QML.

## Archivos clave del problema

Debes prestar especial atención a estos archivos:

- `qml/main.qml`
- `qml/components/NavigationBar.qml`
- `qml/components/CommandBar.qml`
- `qml/components/NavigationPanel.qml`
- `qml/components/ContentArea.qml`
- `qml/components/DetailsPanel.qml`
- `qml/components/PreviewPanel.qml`
- `qml/components/StatusBar.qml`
- `qml/styles/Win7Theme.js`
- `qml/styles/Win7Theme.qml`
- `src/main.cpp`

## Sospecha técnica principal

Hay una señal clara de posible conflicto:

1. `qml/main.qml` importa `styles/Win7Theme.js` como `Win7Theme`.
2. `src/main.cpp` también expone un contexto llamado `Win7Theme`.
3. `CMakeLists.txt` además registra `qml/styles/Win7Theme.qml` como singleton QML.

Eso significa que existen **tres fuentes diferentes** para el mismo tema visual.

Eso puede causar:

- colisiones de nombre
- bindings rotos
- imports ambiguos
- diferencias entre propiedades esperadas y propiedades reales

## Regla importante antes de cambiar cosas

No rehagas todo desde cero.
No conviertas la app Qt en una app web.
No borres componentes avanzados solo porque no funcionan ahora.

Tu trabajo debe ser:

1. aislar el fallo real
2. arreglar lo mínimo necesario para que la UI vuelva a mostrarse
3. mantener la arquitectura existente
4. usar el preview HTML solo como guía visual

## Estrategia obligatoria de trabajo

Sigue exactamente esta secuencia.

### Paso 1. Confirmar el punto de fallo

Haz esto primero:

1. Compila el proyecto.
2. Ejecuta la app.
3. Confirma que abre la ventana pero no renderiza la UI esperada.
4. No asumas que el problema está en C++ todavía.

Comandos esperados:

```bash
cmake -B build -S .
cmake --build build --parallel 4
./build/win7explorer
```

## Paso 2. Verificar que QML básico sí funciona

Edita temporalmente `qml/main.qml` para dejar solo una prueba mínima:

- `ApplicationWindow`
- un `Rectangle`
- un `Text` centrado con un mensaje de prueba

Si eso se muestra, entonces:

- la ventana funciona
- la carga base de QML funciona
- el fallo está dentro de los componentes reales o sus imports/bindings

No te quedes ahí.
Ese paso solo sirve para aislar.

## Paso 3. Restaurar la UI por partes

Después de confirmar que el texto de prueba aparece, vuelve a integrar la UI gradualmente.

Hazlo en este orden:

1. `StatusBar`
2. `NavigationBar`
3. `CommandBar`
4. `ContentArea`
5. `NavigationPanel`
6. `DetailsPanel`
7. `PreviewPanel`

Después de agregar cada componente:

1. compila
2. ejecuta
3. verifica si la ventana sigue mostrando contenido

En el momento en que vuelva a aparecer la pantalla vacía o falle el render, habrás identificado el componente problemático.

## Paso 4. Revisar imports y tema visual

Cuando identifiques el problema, revisa primero el sistema de tema.

Debes unificar `Win7Theme`.

Elige **una sola fuente de verdad** entre estas opciones:

1. usar `Win7Theme.js`
2. usar `Win7Theme.qml` singleton
3. usar el `QQmlPropertyMap` expuesto desde `src/main.cpp`

La recomendación es:

- conservar una sola forma
- eliminar la duplicidad
- actualizar imports y referencias para que todos los componentes usen el mismo origen

No mezcles las tres opciones al mismo tiempo.

## Paso 5. Revisar layouts y tamaños

Si la app no está vacía pero los elementos no se ven, revisa:

1. `Layout.fillWidth`
2. `Layout.fillHeight`
3. `Layout.preferredWidth`
4. `Layout.preferredHeight`
5. `visible`
6. `clip`
7. colores de fondo iguales al fondo de la ventana
8. paneles con ancho o alto en `0`

En `qml/main.qml` ya existen paneles que se ocultan con ancho/alto cero.
Verifica que no estén quedando colapsados por bindings incorrectos.

## Paso 6. Revisar `ContentArea.qml` con prioridad alta

`ContentArea.qml` es sospechoso porque:

1. depende de `fileSystemBackend.currentFiles`
2. usa filtrado de búsqueda
3. contiene lógica de selección, menús y diálogos
4. maneja gran parte del contenido visible principal

Debes revisar especialmente:

- bindings que asumen datos siempre válidos
- delegates de `Repeater`, `ListView` o `GridView`
- accesos a propiedades inexistentes
- menús o diálogos mal anclados
- código JS dentro de QML que pueda lanzar errores

Si `ContentArea` rompe la UI, reduce temporalmente su contenido hasta encontrar el bloque exacto que falla.

## Paso 7. Revisar el backend solo si el fallo sigue

Si el problema no está en el layout ni en el tema, entonces revisa:

- `src/main.cpp`
- `src/filesystembackend.h`
- `src/filesystembackend.cpp`

Comprueba:

1. que `fileSystemBackend` sí se expone al contexto QML
2. que `currentFiles`, `currentPath`, `pathSegments` y `selectedFileInfo` existan y sean válidos
3. que el backend cargue un directorio inicial
4. que no haya listas vacías por un error de inicialización

Importante:
una lista vacía no debería dejar la ventana totalmente rota.
Si la ventana queda completamente vacía, suele ser más probable un problema de QML/import/layout que de datos.

## Paso 8. No romper lo ya avanzado

El roadmap indica que ya existe implementación para:

- navegación real del sistema de archivos
- copiar, mover, renombrar, eliminar
- crear carpetas
- menú contextual
- árbol de carpetas
- vista previa
- búsqueda
- iconos del sistema

Por eso no debes eliminar esas funciones.
Si una parte falla, corrígela, pero conserva la arquitectura.

## Paso 9. Usar el HTML solo como referencia visual

La carpeta `html/` no es para portarla literalmente a producción web.
Pero sí es la base visual obligatoria del proyecto.

Debes usar `html/Explorador.html` como referencia principal de:

- estructura visual
- espaciado
- jerarquía
- estilo Win7
- paneles
- barras
- iconografía esperada

Si dudas sobre cómo debe verse algo, consulta `html/Explorador.html` y `html/styles.css`.
Pero la implementación final debe quedar en QML.

## Paso 10. Criterio de éxito mínimo

No consideres el trabajo terminado hasta cumplir esto:

1. La app abre la ventana.
2. La interfaz principal se ve.
3. Se muestra contenido dentro de la ventana, no solo una ventana vacía.
4. Se ven al menos:
   - barra de navegación
   - barra de comandos
   - panel lateral
   - área central de contenido
   - barra de estado
5. La app compila sin romper el proyecto.

## Criterio de éxito ideal

Si además de arreglar la pantalla vacía logras que funcione correctamente, mejor.

Idealmente debería quedar operativo:

1. cargar directorio inicial
2. listar archivos
3. seleccionar un archivo
4. navegar entre carpetas
5. ver la UI con estilo cercano a Windows 7

## Forma correcta de trabajar

Trabaja con cambios pequeños y verificables.

Haz esto:

1. cambia una sola cosa importante
2. compila
3. ejecuta
4. observa
5. sigue

No hagas una reescritura masiva sin verificar antes.

## Qué NO debes hacer

No hagas esto:

1. no borrar el proyecto QML para rehacerlo desde cero
2. no migrar la app a otra tecnología
3. no ignorar el preview HTML
4. no asumir que el backend está mal sin probar QML mínimo
5. no dejar coexistiendo tres sistemas distintos de tema si eso sigue causando conflicto

## Tarea concreta que debes resolver ahora

Tu primera misión no es “terminar todo el explorador”.

Tu primera misión es esta:

**hacer que la app deje de mostrar una ventana vacía y vuelva a renderizar la interfaz principal real**

Después de eso, recién continúas con ajustes visuales o funcionales.

## Resumen operativo final

Orden de trabajo obligatorio:

1. leer `README.md`
2. leer `PROJECT_ROADMAP.md`
3. leer `COMO_USAR.md`
4. revisar `html/` como guía visual
5. revisar `qml/main.qml`, `src/main.cpp`, `CMakeLists.txt`
6. probar QML mínimo con texto
7. restaurar componentes uno por uno
8. identificar el componente o import que rompe la UI
9. unificar `Win7Theme`
10. corregir el problema sin destruir lo ya implementado
11. compilar y ejecutar otra vez
12. verificar que la interfaz real se vea

## Si te bloqueas

Si te atoras, empieza por esta hipótesis:

**el problema está en la combinación de imports QML + tema duplicado + un componente complejo que rompe el render**

Esa es la pista más fuerte del estado actual del proyecto.
