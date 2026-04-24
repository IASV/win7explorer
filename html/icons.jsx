// Iconos — usamos los .ico reales que el usuario ha provisto.
// Mapeo semántico por tipo de carpeta / extensión / unidad.

const ICON_PATHS = {
  // carpetas
  folder: 'icons/folder-closed.ico',
  folderEmpty: 'icons/folder-empty.ico',
  folderSemi: 'icons/folder-semi.ico',
  folderBlue: 'icons/folder-blue.ico',
  folderBlueEmpty: 'icons/folder-blue-empty.ico',
  folderSearch: 'icons/folder-search.ico',

  // bibliotecas específicas
  libDocs: 'icons/document.ico',
  libMusic: 'icons/music.ico',
  libPics: 'icons/picture.ico',
  libVideo: 'icons/video.ico',

  // sistema
  computer: 'icons/window.ico',
  network: 'icons/network.ico',
  printer: 'icons/printer.ico',
  controlPanel: 'icons/control-panel.ico',
  shield: 'icons/shield.ico',
  games: 'icons/games.ico',
  search: 'icons/search.ico',

  // archivos
  fileGeneric: 'icons/file-generic.ico',
  document: 'icons/document.ico',
  picture: 'icons/picture.ico',
  music: 'icons/music.ico',
  video: 'icons/video.ico',
  mail: 'icons/mail.ico',

  // unidades
  driveLocal: 'icons/drive-local.ico',
  driveSystem: 'icons/drive-system.ico',
  driveEmpty: 'icons/drive-empty.ico',
  driveRemovable: 'icons/drive-removable.ico',
  driveFloppy: 'icons/drive-floppy.ico',
  driveFloppy2: 'icons/drive-floppy2.ico',
  driveCd: 'icons/drive-cd.ico',
  driveDvd: 'icons/drive-dvd.ico',
  driveDvdr: 'icons/drive-dvdr.ico',
  driveDvdram: 'icons/drive-dvdram.ico',
  driveDvdrom: 'icons/drive-dvdrom.ico',
  driveDvdrw: 'icons/drive-dvdrw.ico',
};

// Extensión -> ruta de icono
const EXT_ICON = {
  // documentos
  pdf: ICON_PATHS.document,
  doc: ICON_PATHS.document,
  docx: ICON_PATHS.document,
  txt: ICON_PATHS.document,
  rtf: ICON_PATHS.document,
  xls: ICON_PATHS.document,
  xlsx: ICON_PATHS.document,
  ppt: ICON_PATHS.document,
  pptx: ICON_PATHS.document,
  // imágenes
  jpg: ICON_PATHS.picture,
  jpeg: ICON_PATHS.picture,
  png: ICON_PATHS.picture,
  gif: ICON_PATHS.picture,
  bmp: ICON_PATHS.picture,
  svg: ICON_PATHS.picture,
  ico: ICON_PATHS.picture,
  // audio
  mp3: ICON_PATHS.music,
  wav: ICON_PATHS.music,
  wma: ICON_PATHS.music,
  flac: ICON_PATHS.music,
  ogg: ICON_PATHS.music,
  // video
  mp4: ICON_PATHS.video,
  mov: ICON_PATHS.video,
  avi: ICON_PATHS.video,
  mpg: ICON_PATHS.video,
  mkv: ICON_PATHS.video,
  // correo
  eml: ICON_PATHS.mail,
  msg: ICON_PATHS.mail,
  // ejecutables
  exe: ICON_PATHS.shield,
  msi: ICON_PATHS.shield,
};

function iconForFile(ext) {
  return EXT_ICON[(ext || '').toLowerCase()] || ICON_PATHS.fileGeneric;
}

function iconForFolder(kind, empty = false) {
  if (kind === 'lib-docs') return ICON_PATHS.libDocs;
  if (kind === 'lib-music') return ICON_PATHS.libMusic;
  if (kind === 'lib-pics') return ICON_PATHS.libPics;
  if (kind === 'lib-video') return ICON_PATHS.libVideo;
  if (kind === 'downloads') return ICON_PATHS.folderBlue;
  if (kind === 'desktop') return ICON_PATHS.folder;
  if (kind === 'recent') return ICON_PATHS.folderSearch;
  if (kind === 'pc') return ICON_PATHS.computer;
  if (kind === 'printer') return ICON_PATHS.printer;
  if (kind === 'favorites') return ICON_PATHS.folder;
  return empty ? ICON_PATHS.folderEmpty : ICON_PATHS.folder;
}

function iconForDrive(kind, name = '') {
  if (kind === 'disc') {
    if (/dvd-?rw/i.test(name)) return ICON_PATHS.driveDvdrw;
    if (/dvd-?rom/i.test(name)) return ICON_PATHS.driveDvdrom;
    if (/dvd-?r/i.test(name)) return ICON_PATHS.driveDvdr;
    if (/dvd-?ram/i.test(name)) return ICON_PATHS.driveDvdram;
    if (/dvd/i.test(name)) return ICON_PATHS.driveDvd;
    return ICON_PATHS.driveCd;
  }
  if (kind === 'removable') return ICON_PATHS.driveRemovable;
  if (kind === 'system') return ICON_PATHS.driveSystem;
  return ICON_PATHS.driveLocal;
}

function iconForGroup(kind) {
  if (kind === 'favorites') return ICON_PATHS.folder;
  if (kind === 'libraries') return ICON_PATHS.libDocs;
  if (kind === 'computer') return ICON_PATHS.computer;
  if (kind === 'network') return ICON_PATHS.network;
  return ICON_PATHS.folder;
}

// Componente de imagen con tamaño cuadrado
function Ico({ src, size = 16, className = '', style = {} }) {
  return (
    <img
      src={src}
      width={size}
      height={size}
      className={`ico ${className}`}
      style={{ display: 'block', objectFit: 'contain', ...style }}
      draggable={false}
      alt=""
    />
  );
}

// Wrappers para compatibilidad con el resto del código
function FolderIcon({ size = 48, kind = 'folder', empty = false }) {
  return <Ico src={iconForFolder(kind, empty)} size={size} />;
}
function FileIcon({ size = 48, ext = 'txt' }) {
  return <Ico src={iconForFile(ext)} size={size} />;
}
function DriveIcon({ size = 48, kind = 'disk', name = '' }) {
  return <Ico src={iconForDrive(kind, name)} size={size} />;
}
function ComputerIcon({ size = 20 }) { return <Ico src={ICON_PATHS.computer} size={size} />; }
function NetworkIcon({ size = 20 }) { return <Ico src={ICON_PATHS.network} size={size} />; }
function StarIcon({ size = 16 }) {
  // Estrella de favoritos — SVG simple (no es una réplica, es un glifo universal)
  return (
    <svg width={size} height={size} viewBox="0 0 24 24">
      <path
        d="M12 2 L15 9 L22 9.5 L17 14.5 L18.5 22 L12 18 L5.5 22 L7 14.5 L2 9.5 L9 9 Z"
        fill="#f6b93b"
        stroke="#c98417"
        strokeWidth="1"
        strokeLinejoin="round"
      />
    </svg>
  );
}
function BookshelfIcon({ size = 20 }) {
  return <Ico src={ICON_PATHS.libDocs} size={size} />;
}

// Miniatura de imagen — placeholder con gradiente determinístico
function ImageThumb({ name, size = 96 }) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) & 0xffff;
  const hue1 = h % 360;
  const hue2 = (hue1 + 60) % 360;
  return (
    <div
      style={{
        width: size,
        height: Math.round(size * 0.75),
        borderRadius: 2,
        background: `linear-gradient(135deg, oklch(0.72 0.14 ${hue1}), oklch(0.48 0.16 ${hue2}))`,
        position: 'relative',
        overflow: 'hidden',
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.3)',
      }}
    >
      <div style={{
        position: 'absolute', inset: 0,
        background: `radial-gradient(ellipse at 30% 30%, oklch(0.88 0.15 ${hue1} / 0.7), transparent 55%)`,
      }} />
    </div>
  );
}

Object.assign(window, {
  FolderIcon, FileIcon, DriveIcon, ComputerIcon, NetworkIcon, StarIcon, BookshelfIcon, ImageThumb,
  Ico, ICON_PATHS, iconForFile, iconForFolder, iconForDrive, iconForGroup,
});
