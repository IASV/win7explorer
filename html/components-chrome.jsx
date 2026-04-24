// Componentes del explorador de archivos
const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ============ CHROME DE VENTANA ============
function WindowChrome({ title, onClose, onMin, onMax }) {
  return (
    <div className="win-titlebar">
      <div className="win-title">{title}</div>
      <div className="win-chrome-btns">
        <button className="chrome-btn" onClick={onMin} aria-label="Minimizar">
          <svg width="10" height="10" viewBox="0 0 10 10"><rect x="1" y="7" width="8" height="1.2" fill="currentColor" /></svg>
        </button>
        <button className="chrome-btn" onClick={onMax} aria-label="Maximizar">
          <svg width="10" height="10" viewBox="0 0 10 10"><rect x="1.5" y="1.5" width="7" height="7" fill="none" stroke="currentColor" strokeWidth="1" /></svg>
        </button>
        <button className="chrome-btn chrome-close" onClick={onClose} aria-label="Cerrar">
          <svg width="10" height="10" viewBox="0 0 10 10"><path d="M1 1 L9 9 M9 1 L1 9" stroke="currentColor" strokeWidth="1.2" /></svg>
        </button>
      </div>
    </div>
  );
}

// ============ BARRA DE DIRECCIÓN + BÚSQUEDA ============
function AddressBar({ path, onNavigate, onBack, onForward, onUp, canBack, canForward, canUp, searchValue, onSearchChange, searchPlaceholder }) {
  return (
    <div className="address-row">
      <div className="nav-arrows">
        <button
          className={`nav-arrow ${canBack ? '' : 'disabled'}`}
          onClick={onBack}
          disabled={!canBack}
          aria-label="Atrás"
          title="Atrás"
        >
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M9 2 L4 7 L9 12" stroke="currentColor" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </button>
        <button
          className={`nav-arrow ${canForward ? '' : 'disabled'}`}
          onClick={onForward}
          disabled={!canForward}
          aria-label="Adelante"
          title="Adelante"
        >
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M5 2 L10 7 L5 12" stroke="currentColor" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </button>
        <button
          className={`nav-arrow up ${canUp ? '' : 'disabled'}`}
          onClick={onUp}
          disabled={!canUp}
          aria-label="Subir"
          title="Subir un nivel"
        >
          <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 9 L7 4 L12 9" stroke="currentColor" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>
        </button>
      </div>
      <div className="breadcrumb">
        {path.map((node, i) => (
          <React.Fragment key={node.id}>
            {i > 0 && (
              <span className="crumb-sep">
                <svg width="8" height="10" viewBox="0 0 8 10"><path d="M2 1 L6 5 L2 9" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinecap="round" /></svg>
              </span>
            )}
            <button
              className="crumb"
              onClick={() => onNavigate(node.id)}
            >
              {node.name}
            </button>
          </React.Fragment>
        ))}
        <div className="crumb-spacer" />
      </div>
      <div className="search-box">
        <input
          type="text"
          placeholder={searchPlaceholder || 'Buscar'}
          value={searchValue}
          onChange={(e) => onSearchChange(e.target.value)}
        />
        <svg className="search-icon" width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.6">
          <circle cx="6" cy="6" r="4" />
          <path d="M9 9 L12.5 12.5" strokeLinecap="round" />
        </svg>
      </div>
    </div>
  );
}

// ============ TOOLBAR DE COMANDOS ============
function CommandBar({ view, onViewChange, selectionCount, onCopy, onDelete, onNewFolder, previewOpen, onTogglePreview }) {
  return (
    <div className="command-bar">
      <button className="cmd-btn cmd-primary">
        <span>Organizar</span>
        <Chevron />
      </button>
      <div className="cmd-sep" />
      <button className="cmd-btn" disabled={selectionCount === 0}>
        Abrir
        <Chevron />
      </button>
      <button className="cmd-btn" disabled={selectionCount === 0} onClick={onCopy}>Compartir con</button>
      <button className="cmd-btn" disabled={selectionCount === 0}>Imprimir</button>
      <button className="cmd-btn" disabled={selectionCount === 0}>Correo</button>
      <button className="cmd-btn" disabled={selectionCount === 0} onClick={onDelete}>Eliminar</button>
      <button className="cmd-btn" onClick={onNewFolder}>Nueva carpeta</button>
      <div className="cmd-spacer" />
      <button className={`cmd-icon ${previewOpen ? 'active' : ''}`} onClick={onTogglePreview} title="Mostrar panel de vista previa">
        <svg width="18" height="14" viewBox="0 0 18 14" fill="none" stroke="currentColor" strokeWidth="1.2">
          <rect x="0.5" y="0.5" width="17" height="13" />
          <rect x="10" y="0.5" width="7.5" height="13" fill="currentColor" fillOpacity="0.18" />
        </svg>
      </button>
      <ViewSwitcher view={view} onChange={onViewChange} />
      <button className="cmd-icon" title="Ayuda">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4">
          <circle cx="8" cy="8" r="6.5" />
          <path d="M6 6 Q6 4 8 4 Q10 4 10 6 Q10 7.5 8 8 L8 9.5" strokeLinecap="round" />
          <circle cx="8" cy="12" r="0.6" fill="currentColor" />
        </svg>
      </button>
    </div>
  );
}

function Chevron() {
  return (
    <svg width="8" height="6" viewBox="0 0 8 6" style={{ marginLeft: 4, opacity: 0.6 }}>
      <path d="M1 1.5 L4 4.5 L7 1.5" stroke="currentColor" strokeWidth="1.3" fill="none" />
    </svg>
  );
}

function ViewSwitcher({ view, onChange }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  useEffect(() => {
    const h = (e) => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);
  const options = [
    { id: 'large', label: 'Iconos grandes' },
    { id: 'medium', label: 'Iconos medianos' },
    { id: 'list', label: 'Lista' },
    { id: 'details', label: 'Detalles' },
    { id: 'content', label: 'Contenido' },
  ];
  return (
    <div className="view-switcher" ref={ref}>
      <button className="cmd-icon" onClick={() => setOpen((v) => !v)} title="Cambiar vista">
        <ViewIcon view={view} />
      </button>
      <button className="cmd-icon chev" onClick={() => setOpen((v) => !v)}>
        <Chevron />
      </button>
      {open && (
        <div className="view-dropdown">
          {options.map((opt) => (
            <button
              key={opt.id}
              className={`view-opt ${view === opt.id ? 'active' : ''}`}
              onClick={() => { onChange(opt.id); setOpen(false); }}
            >
              <span className="view-opt-icon"><ViewIcon view={opt.id} /></span>
              <span>{opt.label}</span>
              {view === opt.id && <span className="view-check">✓</span>}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function ViewIcon({ view }) {
  if (view === 'large' || view === 'medium') {
    const s = view === 'large' ? 4.5 : 3.5;
    return (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <rect x="1" y="1" width={s} height={s} /><rect x={8 - s / 2} y="1" width={s} height={s} /><rect x={15 - s} y="1" width={s} height={s} />
        <rect x="1" y={8 - s / 2} width={s} height={s} /><rect x={8 - s / 2} y={8 - s / 2} width={s} height={s} /><rect x={15 - s} y={8 - s / 2} width={s} height={s} />
      </svg>
    );
  }
  if (view === 'list') {
    return (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <rect x="1" y="2" width="3" height="3" /><rect x="5" y="3" width="10" height="1" />
        <rect x="1" y="7" width="3" height="3" /><rect x="5" y="8" width="10" height="1" />
        <rect x="1" y="12" width="3" height="3" /><rect x="5" y="13" width="10" height="1" />
      </svg>
    );
  }
  if (view === 'details') {
    return (
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <rect x="1" y="2" width="2" height="2" /><rect x="4" y="2.5" width="11" height="1" />
        <rect x="1" y="6" width="2" height="2" /><rect x="4" y="6.5" width="11" height="1" />
        <rect x="1" y="10" width="2" height="2" /><rect x="4" y="10.5" width="11" height="1" />
        <rect x="1" y="14" width="2" height="1.2" /><rect x="4" y="14" width="11" height="1.2" />
      </svg>
    );
  }
  // content
  return (
    <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
      <rect x="1" y="2" width="4" height="4" /><rect x="6" y="2.5" width="9" height="1" /><rect x="6" y="4.5" width="7" height="1" />
      <rect x="1" y="8" width="4" height="4" /><rect x="6" y="8.5" width="9" height="1" /><rect x="6" y="10.5" width="7" height="1" />
    </svg>
  );
}

Object.assign(window, { WindowChrome, AddressBar, CommandBar, ViewSwitcher, ViewIcon, Chevron });
