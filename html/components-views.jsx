// Vistas del área de contenido (iconos grandes, medianos, lista, detalles, contenido)
const { useState: useVState } = React;

function ContentArea({
  node, path, items, view, selectedIds, onSelect, onDoubleClick, searchQuery,
  sortBy, sortDir, onSort, onContextMenu, onDrop, density,
}) {
  // Agrupar por tipo si es root del grupo (ej. "Equipo")
  const showGroups = node && node.type === 'group';

  if (items.length === 0 && searchQuery) {
    return (
      <div className="content-area empty">
        <div className="empty-msg">
          <div className="empty-title">Sin resultados para "{searchQuery}"</div>
          <div className="empty-sub">Prueba con otra búsqueda o navega a otra carpeta.</div>
        </div>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="content-area empty">
        <div className="empty-msg">
          <div className="empty-title">Esta carpeta está vacía</div>
          <div className="empty-sub">Arrastra archivos aquí o crea una nueva carpeta.</div>
        </div>
      </div>
    );
  }

  const commonProps = { items, selectedIds, onSelect, onDoubleClick, onContextMenu, density };

  return (
    <div
      className={`content-area view-${view}`}
      onContextMenu={(e) => { e.preventDefault(); onContextMenu(e, null); }}
      onDragOver={(e) => { e.preventDefault(); e.currentTarget.classList.add('drag-over'); }}
      onDragLeave={(e) => e.currentTarget.classList.remove('drag-over')}
      onDrop={(e) => { e.preventDefault(); e.currentTarget.classList.remove('drag-over'); onDrop && onDrop(e); }}
    >
      {showGroups ? (
        <GroupedView node={node} {...commonProps} view={view} />
      ) : view === 'details' ? (
        <DetailsView {...commonProps} sortBy={sortBy} sortDir={sortDir} onSort={onSort} />
      ) : view === 'list' ? (
        <ListView {...commonProps} />
      ) : view === 'content' ? (
        <ContentView {...commonProps} />
      ) : (
        <IconsView {...commonProps} size={view === 'large' ? 'large' : 'medium'} />
      )}
    </div>
  );
}

// ========== VISTA ICONOS (grandes/medianos) ==========
function IconsView({ items, selectedIds, onSelect, onDoubleClick, onContextMenu, size, density }) {
  const iconSize = size === 'large' ? 72 : 48;
  return (
    <div className={`icons-view size-${size}`}>
      {items.map((it) => (
        <ItemIcon
          key={it.id}
          item={it}
          selected={selectedIds.has(it.id)}
          onSelect={onSelect}
          onDoubleClick={onDoubleClick}
          onContextMenu={onContextMenu}
          iconSize={iconSize}
        />
      ))}
    </div>
  );
}

function ItemIcon({ item, selected, onSelect, onDoubleClick, onContextMenu, iconSize }) {
  return (
    <div
      className={`item-tile ${selected ? 'selected' : ''}`}
      onClick={(e) => onSelect(item.id, e)}
      onDoubleClick={() => onDoubleClick(item)}
      onContextMenu={(e) => { e.preventDefault(); e.stopPropagation(); onSelect(item.id, e); onContextMenu(e, item); }}
      draggable
      onDragStart={(e) => { e.dataTransfer.setData('text/plain', item.id); }}
      tabIndex={0}
    >
      <div className="item-icon-wrap" style={{ height: Math.round(iconSize * 1.1) }}>
        {renderBigIcon(item, iconSize)}
      </div>
      <div className="item-label">{item.name}</div>
    </div>
  );
}

function renderBigIcon(item, size) {
  if (item.type === 'drive') return <DriveIcon size={size} kind={item.kind} />;
  if (item.type === 'folder' || item.type === 'group') return <FolderIcon size={size} kind={item.kind || 'folder'} />;
  if (['jpg', 'jpeg', 'png', 'gif'].includes(item.ext)) return <ImageThumb name={item.name} size={Math.round(size * 1.3)} />;
  return <FileIcon size={size} ext={item.ext} />;
}

// ========== VISTA LISTA ==========
function ListView({ items, selectedIds, onSelect, onDoubleClick, onContextMenu }) {
  return (
    <div className="list-view">
      {items.map((it) => (
        <div
          key={it.id}
          className={`list-row ${selectedIds.has(it.id) ? 'selected' : ''}`}
          onClick={(e) => onSelect(it.id, e)}
          onDoubleClick={() => onDoubleClick(it)}
          onContextMenu={(e) => { e.preventDefault(); e.stopPropagation(); onSelect(it.id, e); onContextMenu(e, it); }}
          draggable
          onDragStart={(e) => { e.dataTransfer.setData('text/plain', it.id); }}
        >
          <span className="row-icon">{renderSmallIcon(it)}</span>
          <span className="row-name">{it.name}</span>
        </div>
      ))}
    </div>
  );
}

// ========== VISTA DETALLES ==========
function DetailsView({ items, selectedIds, onSelect, onDoubleClick, onContextMenu, sortBy, sortDir, onSort }) {
  const cols = [
    { id: 'name', label: 'Nombre', width: '2fr' },
    { id: 'modified', label: 'Fecha de modificación', width: '1.3fr' },
    { id: 'type', label: 'Tipo', width: '1fr' },
    { id: 'size', label: 'Tamaño', width: '0.8fr' },
  ];
  return (
    <div className="details-view">
      <div className="details-header" style={{ gridTemplateColumns: cols.map((c) => c.width).join(' ') }}>
        {cols.map((c) => (
          <button key={c.id} className={`col-header ${sortBy === c.id ? 'active' : ''}`} onClick={() => onSort(c.id)}>
            <span>{c.label}</span>
            {sortBy === c.id && (
              <span className="sort-arrow">
                <svg width="8" height="6" viewBox="0 0 8 6">
                  {sortDir === 'asc'
                    ? <path d="M1 5 L4 1 L7 5" stroke="currentColor" strokeWidth="1.3" fill="none" />
                    : <path d="M1 1 L4 5 L7 1" stroke="currentColor" strokeWidth="1.3" fill="none" />}
                </svg>
              </span>
            )}
          </button>
        ))}
      </div>
      <div className="details-body">
        {items.map((it) => (
          <div
            key={it.id}
            className={`details-row ${selectedIds.has(it.id) ? 'selected' : ''}`}
            style={{ gridTemplateColumns: cols.map((c) => c.width).join(' ') }}
            onClick={(e) => onSelect(it.id, e)}
            onDoubleClick={() => onDoubleClick(it)}
            onContextMenu={(e) => { e.preventDefault(); e.stopPropagation(); onSelect(it.id, e); onContextMenu(e, it); }}
            draggable
            onDragStart={(e) => { e.dataTransfer.setData('text/plain', it.id); }}
          >
            <div className="cell name-cell">
              <span className="row-icon">{renderSmallIcon(it)}</span>
              <span>{it.name}</span>
            </div>
            <div className="cell">{it.modified || '—'}</div>
            <div className="cell">{typeLabel(it)}</div>
            <div className="cell">{it.size || (it.type === 'folder' ? '' : '—')}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ========== VISTA CONTENIDO ==========
function ContentView({ items, selectedIds, onSelect, onDoubleClick, onContextMenu }) {
  return (
    <div className="content-view">
      {items.map((it) => (
        <div
          key={it.id}
          className={`content-row ${selectedIds.has(it.id) ? 'selected' : ''}`}
          onClick={(e) => onSelect(it.id, e)}
          onDoubleClick={() => onDoubleClick(it)}
          onContextMenu={(e) => { e.preventDefault(); e.stopPropagation(); onSelect(it.id, e); onContextMenu(e, it); }}
          draggable
          onDragStart={(e) => { e.dataTransfer.setData('text/plain', it.id); }}
        >
          <div className="content-icon">{renderBigIcon(it, 44)}</div>
          <div className="content-meta">
            <div className="content-name">{it.name}</div>
            <div className="content-sub">
              <span>{typeLabel(it)}</span>
              {it.size && <><span className="dot">·</span><span>{it.size}</span></>}
              {it.modified && <><span className="dot">·</span><span>Modificado: {it.modified}</span></>}
              {it.duration && <><span className="dot">·</span><span>Duración: {it.duration}</span></>}
              {it.dim && <><span className="dot">·</span><span>{it.dim}</span></>}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

// ========== VISTA AGRUPADA (para "Equipo") ==========
function GroupedView({ node, items, selectedIds, onSelect, onDoubleClick, onContextMenu, view }) {
  // Detectar grupos (Discos duros, Dispositivos, Red)
  const drives = items.filter((i) => i.type === 'drive' && i.kind === 'disk');
  const removable = items.filter((i) => i.type === 'drive' && i.kind === 'disc');
  const pcs = items.filter((i) => i.kind === 'pc' || i.kind === 'printer');
  const folders = items.filter((i) => i.type === 'folder');

  const renderGroup = (title, subset) => subset.length > 0 && (
    <div className="ca-group">
      <div className="ca-group-title">
        {title} <span className="ca-group-count">({subset.length})</span>
      </div>
      <div className="ca-group-items">
        {subset.map((it) => (
          <DriveTile
            key={it.id}
            item={it}
            selected={selectedIds.has(it.id)}
            onSelect={onSelect}
            onDoubleClick={onDoubleClick}
            onContextMenu={onContextMenu}
          />
        ))}
      </div>
    </div>
  );

  return (
    <div className="grouped-view">
      {renderGroup('Unidades de disco duro', drives)}
      {renderGroup('Dispositivos con almacenamiento extraíble', removable)}
      {renderGroup('Ubicaciones de red', pcs)}
      {folders.length > 0 && (
        <div className="ca-group">
          <div className="ca-group-title">Carpetas <span className="ca-group-count">({folders.length})</span></div>
          <div className="ca-group-items">
            {folders.map((it) => (
              <ItemIcon key={it.id} item={it} selected={selectedIds.has(it.id)} onSelect={onSelect} onDoubleClick={onDoubleClick} onContextMenu={onContextMenu} iconSize={48} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function DriveTile({ item, selected, onSelect, onDoubleClick, onContextMenu }) {
  const pct = item.total ? Math.round(((item.total - item.free) / item.total) * 100) : null;
  return (
    <div
      className={`drive-tile ${selected ? 'selected' : ''}`}
      onClick={(e) => onSelect(item.id, e)}
      onDoubleClick={() => onDoubleClick(item)}
      onContextMenu={(e) => { e.preventDefault(); e.stopPropagation(); onSelect(item.id, e); onContextMenu(e, item); }}
    >
      <div className="drive-icon"><DriveIcon size={52} kind={item.kind} /></div>
      <div className="drive-meta">
        <div className="drive-name">{item.name}</div>
        {pct !== null && (
          <>
            <div className="drive-bar">
              <div className="drive-bar-fill" style={{ width: `${pct}%` }} />
            </div>
            <div className="drive-sub">{item.free} GB libres de {item.total} GB</div>
          </>
        )}
      </div>
    </div>
  );
}

function renderSmallIcon(item) {
  if (item.type === 'drive') return <DriveIcon size={16} kind={item.kind} />;
  if (item.type === 'folder' || item.type === 'group') return <FolderIcon size={16} kind={item.kind || 'folder'} />;
  return <FileIcon size={14} ext={item.ext} />;
}

function typeLabel(item) {
  if (item.type === 'drive') return 'Unidad local';
  if (item.type === 'folder') return 'Carpeta de archivos';
  if (item.type === 'group') return 'Grupo';
  const map = {
    pdf: 'Documento PDF', docx: 'Documento de Word', doc: 'Documento de Word',
    xlsx: 'Hoja de cálculo', xls: 'Hoja de cálculo',
    pptx: 'Presentación', ppt: 'Presentación',
    txt: 'Documento de texto',
    jpg: 'Imagen JPEG', jpeg: 'Imagen JPEG', png: 'Imagen PNG', gif: 'Imagen GIF', svg: 'Gráfico vectorial',
    mp3: 'Audio MP3', wav: 'Audio WAV', mp4: 'Vídeo MP4', mov: 'Vídeo QuickTime', avi: 'Vídeo AVI',
    exe: 'Aplicación', dll: 'Biblioteca', zip: 'Archivo comprimido',
  };
  return map[item.ext] || `Archivo ${(item.ext || '').toUpperCase()}`;
}

Object.assign(window, { ContentArea, typeLabel, renderSmallIcon, renderBigIcon });
