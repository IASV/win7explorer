// Panel de vista previa, barra de estado, menú contextual

function PreviewPanel({ item }) {
  if (!item) {
    return (
      <div className="preview-panel empty">
        <div className="preview-empty-icon">
          <svg width="48" height="48" viewBox="0 0 48 48" fill="none" stroke="currentColor" strokeWidth="1.2" opacity="0.4">
            <rect x="8" y="6" width="32" height="36" rx="2" />
            <path d="M16 16 L32 16 M16 22 L32 22 M16 28 L26 28" />
          </svg>
        </div>
        <div className="preview-empty-label">Selecciona un archivo<br/>para previsualizar</div>
      </div>
    );
  }
  return (
    <div className="preview-panel">
      <div className="preview-hero">
        {renderPreview(item)}
      </div>
      <div className="preview-meta">
        <div className="preview-name" title={item.name}>{item.name}</div>
        <div className="preview-type">{typeLabel(item)}</div>
      </div>
    </div>
  );
}

function renderPreview(item) {
  if (item.type === 'folder' || item.type === 'group') {
    return <div className="preview-folder"><FolderIcon size={120} kind={item.kind || 'folder'} /></div>;
  }
  if (item.type === 'drive') {
    return <div className="preview-folder"><DriveIcon size={120} kind={item.kind} /></div>;
  }
  if (['jpg', 'jpeg', 'png', 'gif'].includes(item.ext)) {
    return <ImageThumb name={item.name} size={220} />;
  }
  if (['mp3', 'wav'].includes(item.ext)) {
    return (
      <div className="preview-audio">
        <div className="audio-wave">
          {Array.from({ length: 28 }).map((_, i) => {
            const h = 10 + Math.abs(Math.sin((i + item.name.length) * 0.6)) * 40;
            return <div key={i} className="audio-bar" style={{ height: `${h}px` }} />;
          })}
        </div>
        <div className="audio-duration">{item.duration || '0:00'}</div>
      </div>
    );
  }
  if (['mp4', 'mov', 'avi'].includes(item.ext)) {
    return (
      <div className="preview-video">
        <ImageThumb name={item.name} size={220} />
        <div className="play-overlay">
          <svg width="40" height="40" viewBox="0 0 40 40">
            <circle cx="20" cy="20" r="18" fill="rgba(0,0,0,0.55)" />
            <path d="M15 12 L28 20 L15 28 Z" fill="white" />
          </svg>
        </div>
      </div>
    );
  }
  // Documento: preview estilo hoja
  return (
    <div className="preview-doc">
      <div className="doc-page">
        <div className="doc-line w-60" />
        <div className="doc-line w-90" />
        <div className="doc-line w-75" />
        <div className="doc-line w-85" />
        <div className="doc-line w-50" />
        <div className="doc-gap" />
        <div className="doc-line w-80" />
        <div className="doc-line w-65" />
        <div className="doc-line w-90" />
      </div>
      <FileIcon size={36} ext={item.ext} />
    </div>
  );
}

function StatusBar({ items, selectedItems, currentNode }) {
  const sel = selectedItems.length;
  if (sel === 0) {
    const folders = items.filter((i) => i.type === 'folder').length;
    const files = items.filter((i) => i.type === 'file').length;
    return (
      <div className="status-bar">
        <div className="status-left">
          {folders + files > 0 ? `${items.length} elemento${items.length === 1 ? '' : 's'}` : 'Carpeta vacía'}
        </div>
      </div>
    );
  }
  const single = sel === 1 ? selectedItems[0] : null;
  return (
    <div className="status-bar detailed">
      {single ? (
        <>
          <div className="status-icon">
            {single.type === 'file' ? <FileIcon size={36} ext={single.ext} /> :
             single.type === 'drive' ? <DriveIcon size={36} kind={single.kind} /> :
             <FolderIcon size={36} kind={single.kind || 'folder'} />}
          </div>
          <div className="status-props">
            <div className="status-name">{single.name}</div>
            <div className="status-meta">
              <StatusProp label="Tipo" value={typeLabel(single)} />
              {single.modified && <StatusProp label="Modificado" value={single.modified} />}
              {single.size && <StatusProp label="Tamaño" value={single.size} />}
              {single.dim && <StatusProp label="Dimensiones" value={single.dim} />}
              {single.duration && <StatusProp label="Duración" value={single.duration} />}
            </div>
          </div>
        </>
      ) : (
        <div className="status-left">
          {sel} elementos seleccionados
          {selectedItems.some(s => s.size) && (
            <span className="status-sep">·</span>
          )}
        </div>
      )}
    </div>
  );
}

function StatusProp({ label, value }) {
  return (
    <span className="status-prop">
      <span className="status-prop-label">{label}:</span>
      <span className="status-prop-value">{value}</span>
    </span>
  );
}

function ContextMenu({ x, y, target, onClose, onDelete, onCopy, onRename, onOpen }) {
  const ref = useRef(null);
  useEffect(() => {
    const h = (e) => { if (ref.current && !ref.current.contains(e.target)) onClose(); };
    const esc = (e) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('mousedown', h);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', h); document.removeEventListener('keydown', esc); };
  }, [onClose]);
  const items = target
    ? [
        { id: 'open', label: 'Abrir', action: () => { onOpen(target); onClose(); }, bold: true },
        { id: 'open-new', label: 'Abrir en ventana nueva' },
        null,
        { id: 'cut', label: 'Cortar', shortcut: 'Ctrl+X' },
        { id: 'copy', label: 'Copiar', shortcut: 'Ctrl+C', action: () => { onCopy(); onClose(); } },
        null,
        { id: 'create-shortcut', label: 'Crear acceso directo' },
        { id: 'delete', label: 'Eliminar', shortcut: 'Supr', action: () => { onDelete(); onClose(); } },
        { id: 'rename', label: 'Cambiar nombre', action: () => { onRename(target); onClose(); } },
        null,
        { id: 'props', label: 'Propiedades' },
      ]
    : [
        { id: 'view', label: 'Ver', hasArrow: true },
        { id: 'sort', label: 'Ordenar por', hasArrow: true },
        { id: 'group', label: 'Agrupar por', hasArrow: true },
        null,
        { id: 'refresh', label: 'Actualizar' },
        null,
        { id: 'paste', label: 'Pegar', shortcut: 'Ctrl+V' },
        null,
        { id: 'new', label: 'Nuevo', hasArrow: true },
        null,
        { id: 'props', label: 'Propiedades' },
      ];
  return (
    <div
      ref={ref}
      className="context-menu"
      style={{ left: x, top: y }}
    >
      {items.map((it, i) => it === null ? (
        <div key={`sep-${i}`} className="ctx-sep" />
      ) : (
        <button
          key={it.id}
          className={`ctx-item ${it.bold ? 'bold' : ''}`}
          onClick={() => it.action ? it.action() : onClose()}
        >
          <span className="ctx-label">{it.label}</span>
          {it.shortcut && <span className="ctx-shortcut">{it.shortcut}</span>}
          {it.hasArrow && <span className="ctx-arrow">▸</span>}
        </button>
      ))}
    </div>
  );
}

Object.assign(window, { PreviewPanel, StatusBar, ContextMenu });
