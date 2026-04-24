---
name: Compile
description: Compile app
invokable: true
---

Ejecuta esto:

# Desde la raíz del proyecto (win7explorer/)
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release && cmake --build build --parallel 4