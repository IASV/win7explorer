// FileSystem.qml - Modelo de datos del explorador
// Contiene el árbol de carpetas/archivos y helpers para iconos, navegación y operaciones.

import QtQuick

QtObject {
    id: fs

    readonly property string iconBase: "image://fileicons/"

    // Árbol raíz
    property var root: ({
        id: "root",
        name: "Equipo",
        type: "folder",
        children: [
            {
                id: "favorites", name: "Favoritos", type: "group", kind: "favorites",
                children: [
                    { id: "desktop", name: "Escritorio", type: "folder", kind: "desktop", children: [] },
                    { id: "downloads", name: "Descargas", type: "folder", kind: "downloads", children: [
                        { id: "dl1", name: "instalador-v2.1.exe", type: "file", ext: "exe", size: "24.3 MB", modified: "12/03/2026" },
                        { id: "dl2", name: "factura-marzo.pdf", type: "file", ext: "pdf", size: "312 KB", modified: "28/03/2026" },
                        { id: "dl3", name: "presupuesto.xlsx", type: "file", ext: "xlsx", size: "84 KB", modified: "15/04/2026" },
                        { id: "dl4", name: "foto-viaje.jpg", type: "file", ext: "jpg", size: "2.1 MB", modified: "02/04/2026", dim: "3840×2160" }
                    ]},
                    { id: "recent", name: "Sitios recientes", type: "folder", kind: "recent", children: [] }
                ]
            },
            {
                id: "libraries", name: "Bibliotecas", type: "group", kind: "libraries",
                children: [
                    { id: "lib-docs", name: "Documentos", type: "folder", kind: "lib-docs", children: [
                        { id: "d1", name: "Artículos", type: "folder", kind: "folder", children: [] },
                        { id: "d2", name: "Libros", type: "folder", kind: "folder", children: [] },
                        { id: "d3", name: "Proyectos", type: "folder", kind: "folder", children: [] },
                        { id: "d6", name: "carta-bienvenida.docx", type: "file", ext: "docx", size: "42 KB", modified: "05/04/2026" },
                        { id: "d7", name: "presupuesto-anual.xlsx", type: "file", ext: "xlsx", size: "96 KB", modified: "14/04/2026" },
                        { id: "d8", name: "plan-estratégico.pptx", type: "file", ext: "pptx", size: "3.4 MB", modified: "20/04/2026" },
                        { id: "d9", name: "contrato-2026.pdf", type: "file", ext: "pdf", size: "420 KB", modified: "03/03/2026" },
                        { id: "d10", name: "notas-personales.txt", type: "file", ext: "txt", size: "2 KB", modified: "23/04/2026" }
                    ]},
                    { id: "lib-music", name: "Música", type: "folder", kind: "lib-music", children: [
                        { id: "m3", name: "canción-relajante.mp3", type: "file", ext: "mp3", size: "4.2 MB", modified: "08/04/2026", duration: "3:42" },
                        { id: "m4", name: "podcast-episodio-12.mp3", type: "file", ext: "mp3", size: "32 MB", modified: "19/04/2026", duration: "45:10" }
                    ]},
                    { id: "lib-pics", name: "Imágenes", type: "folder", kind: "lib-pics", children: [
                        { id: "pi3", name: "atardecer-playa.jpg", type: "file", ext: "jpg", size: "3.8 MB", modified: "02/04/2026", dim: "4000×3000" },
                        { id: "pi4", name: "montaña-niebla.jpg", type: "file", ext: "jpg", size: "2.9 MB", modified: "14/04/2026", dim: "3840×2560" },
                        { id: "pi6", name: "logo-empresa.png", type: "file", ext: "png", size: "84 KB", modified: "05/04/2026", dim: "512×512" }
                    ]},
                    { id: "lib-video", name: "Vídeos", type: "folder", kind: "lib-video", children: [
                        { id: "v1", name: "presentación-producto.mp4", type: "file", ext: "mp4", size: "124 MB", modified: "16/04/2026", duration: "4:20" }
                    ]}
                ]
            },
            {
                id: "computer", name: "Equipo", type: "group", kind: "computer",
                children: [
                    { id: "disk-c", name: "Disco local (C:)", type: "drive", kind: "system", total: 78.9, free: 44.3, children: [
                        { id: "c1", name: "Programas", type: "folder", kind: "folder", children: [] },
                        { id: "c2", name: "Sistema", type: "folder", kind: "folder", children: [] },
                        { id: "c3", name: "Usuarios", type: "folder", kind: "folder", children: [] }
                    ]},
                    { id: "disk-d", name: "Disco local (D:)", type: "drive", kind: "disk", total: 69.9, free: 21.6, children: [] },
                    { id: "disk-e", name: "Unidad DVD (E:)", type: "drive", kind: "disc", children: [] }
                ]
            },
            {
                id: "network", name: "Red", type: "group", kind: "network",
                children: [
                    { id: "nw1", name: "SERVIDOR-01", type: "folder", kind: "pc", children: [] },
                    { id: "nw2", name: "IMPRESORA-HP", type: "folder", kind: "printer", children: [] }
                ]
            }
        ]
    })

    // Buscar nodo por id
    function findNode(id, node) {
        node = node || root
        if (node.id === id) return node
        if (!node.children) return null
        for (var i = 0; i < node.children.length; i++) {
            var r = findNode(id, node.children[i])
            if (r) return r
        }
        return null
    }

    // Path completo al nodo (array de nodos)
    function pathTo(id, node, acc) {
        node = node || root
        acc = acc || []
        if (node.id === id) return acc.concat([node])
        if (!node.children) return null
        for (var i = 0; i < node.children.length; i++) {
            var r = pathTo(id, node.children[i], acc.concat([node]))
            if (r) return r
        }
        return null
    }

    // Aplanar archivos descendientes (para búsqueda)
    function flattenFiles(node, acc) {
        acc = acc || []
        if (!node) return acc
        if (node.type === "file") acc.push(node)
        if (node.children) {
            for (var i = 0; i < node.children.length; i++) flattenFiles(node.children[i], acc)
        }
        return acc
    }

    // Eliminar nodos por id (muta root)
    function deleteItems(ids) {
        var setIds = {}
        for (var i = 0; i < ids.length; i++) setIds[ids[i]] = true
        function walk(n) {
            if (!n.children) return
            n.children = n.children.filter(function(c) { return !setIds[c.id] })
            n.children.forEach(walk)
        }
        walk(root)
        root = JSON.parse(JSON.stringify(root)) // forzar re-evaluación
    }

    // Añadir carpeta
    function addFolder(parentId, name) {
        var parent = findNode(parentId)
        if (!parent || !parent.children) return null
        var id = "new-" + Date.now()
        var today = new Date()
        var d = today.getDate() + "/" + (today.getMonth() + 1) + "/" + today.getFullYear()
        parent.children.push({
            id: id, name: name, type: "folder", kind: "folder", children: [], modified: d
        })
        root = JSON.parse(JSON.stringify(root))
        return id
    }

    // ---------- Iconos ----------
    function iconForFile(ext) {
        ext = (ext || "").toLowerCase()
        var map = {
            pdf: "document.png", doc: "document.png", docx: "document.png", txt: "document.png",
            rtf: "document.png", xls: "document.png", xlsx: "document.png", ppt: "document.png", pptx: "document.png",
            jpg: "picture.png", jpeg: "picture.png", png: "picture.png", gif: "picture.png",
            bmp: "picture.png", svg: "picture.png", ico: "picture.png",
            mp3: "music.png", wav: "music.png", wma: "music.png", flac: "music.png", ogg: "music.png",
            mp4: "video.png", mov: "video.png", avi: "video.png", mpg: "video.png", mkv: "video.png",
            eml: "mail.png", msg: "mail.png",
            exe: "shield.png", msi: "shield.png"
        }
        return iconBase + (map[ext] || "file-generic.png")
    }

    function iconForFolder(kind, empty) {
        if (kind === "lib-docs") return iconBase + "document.png"
        if (kind === "lib-music") return iconBase + "music.png"
        if (kind === "lib-pics") return iconBase + "picture.png"
        if (kind === "lib-video") return iconBase + "video.png"
        if (kind === "downloads") return iconBase + "folder-blue.png"
        if (kind === "desktop") return iconBase + "folder-closed.png"
        if (kind === "recent") return iconBase + "folder-search.png"
        if (kind === "pc") return iconBase + "window.png"
        if (kind === "printer") return iconBase + "printer.png"
        return empty ? iconBase + "folder-empty.png" : iconBase + "folder-closed.png"
    }

    function iconForDrive(kind, name) {
        name = name || ""
        if (kind === "disc") {
            if (/dvd-?rw/i.test(name)) return iconBase + "drive-dvdrw.png"
            if (/dvd-?rom/i.test(name)) return iconBase + "drive-dvdrom.png"
            if (/dvd/i.test(name)) return iconBase + "drive-dvd.png"
            return iconBase + "drive-cd.png"
        }
        if (kind === "removable") return iconBase + "drive-removable.png"
        if (kind === "system") return iconBase + "drive-system.png"
        return iconBase + "drive-local.png"
    }

    function iconForGroup(kind) {
        if (kind === "favorites") return iconBase + "folder-closed.png"
        if (kind === "libraries") return iconBase + "document.png"
        if (kind === "computer") return iconBase + "window.png"
        if (kind === "network") return iconBase + "network.png"
        return iconBase + "folder-closed.png"
    }

    function iconFor(item) {
        if (!item) return ""
        if (item.type === "drive") return iconForDrive(item.kind, item.name)
        if (item.type === "file") return iconForFile(item.ext)
        return iconForFolder(item.kind)
    }

    // Etiqueta de tipo
    function typeLabel(item) {
        if (!item) return ""
        if (item.type === "drive") return "Unidad local"
        if (item.type === "folder") return "Carpeta de archivos"
        if (item.type === "group") return "Grupo"
        var map = {
            pdf: "Documento PDF", docx: "Documento de Word", doc: "Documento de Word",
            xlsx: "Hoja de cálculo", xls: "Hoja de cálculo",
            pptx: "Presentación", ppt: "Presentación",
            txt: "Documento de texto",
            jpg: "Imagen JPEG", jpeg: "Imagen JPEG", png: "Imagen PNG",
            gif: "Imagen GIF", svg: "Gráfico vectorial",
            mp3: "Audio MP3", wav: "Audio WAV",
            mp4: "Vídeo MP4", mov: "Vídeo QuickTime", avi: "Vídeo AVI",
            exe: "Aplicación", dll: "Biblioteca", zip: "Archivo comprimido"
        }
        return map[item.ext] || ("Archivo " + (item.ext || "").toUpperCase())
    }
}
