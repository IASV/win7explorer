// Sistema de archivos ficticio para el prototipo
// Cada nodo: { id, name, type: 'folder'|'file', ext?, size?, modified?, children?, kind? }

const FS_DATA = {
  id: 'root',
  name: 'Equipo',
  type: 'folder',
  children: [
    {
      id: 'favorites',
      name: 'Favoritos',
      type: 'group',
      kind: 'favorites',
      children: [
        { id: 'desktop', name: 'Escritorio', type: 'folder', kind: 'desktop', children: [] },
        { id: 'downloads', name: 'Descargas', type: 'folder', kind: 'downloads', children: [
          { id: 'dl1', name: 'instalador-v2.1.exe', type: 'file', ext: 'exe', size: '24.3 MB', modified: '12/03/2026' },
          { id: 'dl2', name: 'factura-marzo.pdf', type: 'file', ext: 'pdf', size: '312 KB', modified: '28/03/2026' },
          { id: 'dl3', name: 'presupuesto.xlsx', type: 'file', ext: 'xlsx', size: '84 KB', modified: '15/04/2026' },
          { id: 'dl4', name: 'foto-viaje.jpg', type: 'file', ext: 'jpg', size: '2.1 MB', modified: '02/04/2026', dim: '3840×2160' },
        ]},
        { id: 'recent', name: 'Sitios recientes', type: 'folder', kind: 'recent', children: [] },
      ],
    },
    {
      id: 'libraries',
      name: 'Bibliotecas',
      type: 'group',
      kind: 'libraries',
      children: [
        {
          id: 'lib-docs',
          name: 'Documentos',
          type: 'folder',
          kind: 'lib-docs',
          children: [
            { id: 'd1', name: 'Artículos', type: 'folder', kind: 'folder', children: [
              { id: 'a1', name: 'investigación-ux.docx', type: 'file', ext: 'docx', size: '54 KB', modified: '10/04/2026' },
              { id: 'a2', name: 'notas-reunión.txt', type: 'file', ext: 'txt', size: '4 KB', modified: '22/04/2026' },
            ]},
            { id: 'd2', name: 'Libros', type: 'folder', kind: 'folder', children: [
              { id: 'b1', name: 'manual-usuario.pdf', type: 'file', ext: 'pdf', size: '1.2 MB', modified: '01/02/2026' },
            ]},
            { id: 'd3', name: 'Proyectos', type: 'folder', kind: 'folder', children: [
              { id: 'p1', name: 'propuesta-cliente.docx', type: 'file', ext: 'docx', size: '128 KB', modified: '18/04/2026' },
              { id: 'p2', name: 'cronograma.xlsx', type: 'file', ext: 'xlsx', size: '56 KB', modified: '20/04/2026' },
            ]},
            { id: 'd4', name: 'Facturas', type: 'folder', kind: 'folder', children: [] },
            { id: 'd5', name: 'Impuestos', type: 'folder', kind: 'folder', children: [] },
            { id: 'd6', name: 'carta-bienvenida.docx', type: 'file', ext: 'docx', size: '42 KB', modified: '05/04/2026' },
            { id: 'd7', name: 'presupuesto-anual.xlsx', type: 'file', ext: 'xlsx', size: '96 KB', modified: '14/04/2026' },
            { id: 'd8', name: 'plan-estratégico.pptx', type: 'file', ext: 'pptx', size: '3.4 MB', modified: '20/04/2026' },
            { id: 'd9', name: 'contrato-2026.pdf', type: 'file', ext: 'pdf', size: '420 KB', modified: '03/03/2026' },
            { id: 'd10', name: 'notas-personales.txt', type: 'file', ext: 'txt', size: '2 KB', modified: '23/04/2026' },
          ],
        },
        {
          id: 'lib-music',
          name: 'Música',
          type: 'folder',
          kind: 'lib-music',
          children: [
            { id: 'm1', name: 'Álbumes', type: 'folder', kind: 'folder', children: [] },
            { id: 'm2', name: 'Artistas', type: 'folder', kind: 'folder', children: [] },
            { id: 'm3', name: 'canción-relajante.mp3', type: 'file', ext: 'mp3', size: '4.2 MB', modified: '08/04/2026', duration: '3:42' },
            { id: 'm4', name: 'podcast-episodio-12.mp3', type: 'file', ext: 'mp3', size: '32 MB', modified: '19/04/2026', duration: '45:10' },
            { id: 'm5', name: 'pista-ambient.wav', type: 'file', ext: 'wav', size: '58 MB', modified: '11/04/2026', duration: '5:30' },
          ],
        },
        {
          id: 'lib-pics',
          name: 'Imágenes',
          type: 'folder',
          kind: 'lib-pics',
          children: [
            { id: 'pi1', name: 'Vacaciones 2026', type: 'folder', kind: 'folder', children: [] },
            { id: 'pi2', name: 'Capturas', type: 'folder', kind: 'folder', children: [] },
            { id: 'pi3', name: 'atardecer-playa.jpg', type: 'file', ext: 'jpg', size: '3.8 MB', modified: '02/04/2026', dim: '4000×3000' },
            { id: 'pi4', name: 'montaña-niebla.jpg', type: 'file', ext: 'jpg', size: '2.9 MB', modified: '14/04/2026', dim: '3840×2560' },
            { id: 'pi5', name: 'retrato-familia.png', type: 'file', ext: 'png', size: '5.2 MB', modified: '21/04/2026', dim: '3000×4000' },
            { id: 'pi6', name: 'logo-empresa.png', type: 'file', ext: 'png', size: '84 KB', modified: '05/04/2026', dim: '512×512' },
            { id: 'pi7', name: 'diagrama.svg', type: 'file', ext: 'svg', size: '12 KB', modified: '12/04/2026' },
          ],
        },
        {
          id: 'lib-video',
          name: 'Vídeos',
          type: 'folder',
          kind: 'lib-video',
          children: [
            { id: 'v1', name: 'presentación-producto.mp4', type: 'file', ext: 'mp4', size: '124 MB', modified: '16/04/2026', duration: '4:20' },
            { id: 'v2', name: 'tutorial-intro.mov', type: 'file', ext: 'mov', size: '312 MB', modified: '09/04/2026', duration: '12:45' },
          ],
        },
      ],
    },
    {
      id: 'computer',
      name: 'Equipo',
      type: 'group',
      kind: 'computer',
      children: [
        { id: 'disk-c', name: 'Disco local (C:)', type: 'drive', kind: 'disk', total: 78.9, free: 44.3, children: [
          { id: 'c1', name: 'Programas', type: 'folder', kind: 'folder', children: [] },
          { id: 'c2', name: 'Sistema', type: 'folder', kind: 'folder', children: [] },
          { id: 'c3', name: 'Usuarios', type: 'folder', kind: 'folder', children: [] },
        ]},
        { id: 'disk-d', name: 'Disco local (D:)', type: 'drive', kind: 'disk', total: 69.9, free: 21.6, children: [
          { id: 'dd1', name: 'Backup', type: 'folder', kind: 'folder', children: [] },
          { id: 'dd2', name: 'Media', type: 'folder', kind: 'folder', children: [] },
        ]},
        { id: 'disk-e', name: 'Unidad DVD (E:)', type: 'drive', kind: 'disc', children: [] },
      ],
    },
    {
      id: 'network',
      name: 'Red',
      type: 'group',
      kind: 'network',
      children: [
        { id: 'nw1', name: 'SERVIDOR-01', type: 'folder', kind: 'pc', children: [] },
        { id: 'nw2', name: 'IMPRESORA-HP', type: 'folder', kind: 'printer', children: [] },
      ],
    },
  ],
};

// Utilidad: encontrar nodo por id, devuelve también el path
function findNode(root, id, path = []) {
  if (root.id === id) return { node: root, path: [...path, root] };
  if (!root.children) return null;
  for (const child of root.children) {
    const found = findNode(child, id, [...path, root]);
    if (found) return found;
  }
  return null;
}

// Utilidad: listar todos los descendientes archivo (para búsqueda)
function flattenFiles(node, acc = []) {
  if (!node) return acc;
  if (node.type === 'file') acc.push(node);
  if (node.children) node.children.forEach((c) => flattenFiles(c, acc));
  return acc;
}

function humanPath(pathArr) {
  return pathArr.map((n) => n.name).join(' › ');
}

window.FS_DATA = FS_DATA;
window.findNode = findNode;
window.flattenFiles = flattenFiles;
window.humanPath = humanPath;
