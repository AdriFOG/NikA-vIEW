# Nikaido Explorer v0.10.4 — auditoría de Vault, carpetas, miniaturas y filtro global

Cambios hechos por inspección del código. **No se compiló con Xcode en este entorno**; la validación real es el workflow de GitHub Actions (build + cero warnings) y una prueba en un iPhone.

## Bug 1 — Seguridad al abrir archivos de la bóveda
- Nueva barrera por archivo (`NikaidoFileAuth`, `protectedOpen` en `PrivateVaultView`): antes de abrir una imagen/video, un ZIP o galería `.sec`, exportar una copia descifrada o guardarla en el Explorador, se pide Face ID. Si Face ID no está disponible, falla o el usuario elige la contraseña, se pide la contraseña de la bóveda.
- Cancelar o fallar nunca ejecuta la acción (`.cancelled` no hace nada; el resto exige contraseña).
- `PrivateVaultSession.verifyPassword` valida la contraseña derivando la clave y comparándola en tiempo constante con la que ya está en memoria. No se guarda ni se muestra ninguna contraseña.
- Las miniaturas de la cuadrícula ya no se descifran ni se muestran hasta que el usuario las revela (menú ⋯ → "Mostrar miniaturas", pide identidad). Se ocultan al bloquear, al pasar a segundo plano o al desactivar la protección.
- Ajuste en el menú de la bóveda: "Pedir identidad al abrir archivos" (activado por defecto; apagarlo también pide identidad).
- Sin cambios de formato: los archivos existentes siguen siendo compatibles. La caché de miniaturas ya estaba cifrada y los temporales ya se borraban al bloquear.

## Bug 2 — Carpetas locales de "En mi iPhone"
- Si el permiso del selector no llega, se intenta una segunda vía (ida y vuelta por un bookmark) antes de rechazar la carpeta.
- Mensajes de error comprensibles (`ExplorerErrorText`): permisos (513/257, EPERM/EACCES), archivo inexistente, disco lleno, solo lectura.
- El mensaje de rechazo explica que iOS no permite carpetas del sistema ni de otras apps.
- Limitación: iOS solo da acceso a lo que el usuario elige en Archivos. No pude probar esto en un iPhone real.

## Bug 3 — Carpetas agregadas en la raíz
- Cada ubicación muestra su origen (iCloud Drive, En mi iPhone, Otro proveedor, Nikaido Explorer) con su ícono.
- Una misma carpeta no se duplica aunque iOS cambie la ruta (se compara también la identidad real del archivo).
- Las referencias caducadas, movidas o con permiso revocado ya no desaparecen: aparecen en "No disponibles" con el motivo, con "Reintentar acceso" y "Quitar". Volver a añadir la carpeta reemplaza la referencia vieja.

## Bug 4 — Miniaturas de video encimadas
- Causa: la imagen escalada para llenar se dibujaba dentro del `ZStack` que definía el tamaño, así que su tamaño interno desbordaba la celda. Ahora el tamaño lo fija un `Color.clear` con proporción fija y la imagen se dibuja encima y se recorta (Bóveda y Explorador).

## Bug 5 — Filtro global
- Menú ⋯ → "Todos los archivos": filtros Todos / Fotos / Videos / Texto (TXT, MD, RTF y los demás formatos de texto del proyecto), búsqueda por nombre, miniatura, origen y ruta.
- Escaneo en segundo plano con resultados progresivos, sin duplicados, sin seguir enlaces simbólicos, con tope de 25 000 archivos y aviso de carpetas que no se pudieron leer.
- Abrir un archivo (editor o vista previa) y "Mostrar en su carpeta". Si el archivo ya no existe se quita de la lista y se avisa.
- La bóveda NO se indexa. La caché es solo en memoria (90 s), nada se escribe en disco.

## Bug 6 — Otros
- Se quitó un `first!` en la papelera (ahora tiene alternativa).
- Mensajes de error del Explorador unificados.

## Pendiente / a probar en un iPhone
1. Face ID y la contraseña alternativa al abrir un archivo de la bóveda (incluido cancelar).
2. Añadir una carpeta de "En mi iPhone" y una de iCloud; reiniciar la app y comprobar que siguen.
3. Videos verticales, horizontales y cuadrados en la cuadrícula de la bóveda.
4. Filtro global con varias carpetas, y borrar un archivo desde Archivos para ver el aviso.
