// App principal del explorador de archivos
const { useState, useEffect, useRef, useMemo, useCallback } = React;

const DEFAULT_TWEAKS = /*EDITMODE-BEGIN*/{
  "theme": "glass",
  "density": "comfortable",
  "accentHue": 230,
  "radius": 6,
  "fontFamily": "segoe",
  "showPreview": true,
  "showSidebar": true
}/*EDITMODE-END*/;

function ExplorerApp() {
  const [tweaks, setTweak] = useTweaks(DEFAULT_TWEAKS);

  // Historia de navegación (array de ids; historyIndex apunta al actual)
  const [history, setHistory] = useState(['libraries']);
  const [historyIndex, setHistoryIndex] = useState(0);
  const currentId = history[historyIndex];

  const [expanded, setExpanded] = useState({
    favorites: true, libraries: true, computer: true, network: false,
    'lib-docs': false,
  });

  const [view, setView] = useState('large');
  const [selectedIds, setSelectedIds] = useState(new Set());
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('name');
  const [sortDir, setSortDir] = useState('asc');
  const [contextMenu, setContextMenu] = useState(null);
  const [fsData, setFsData] = useState(FS_DATA);
  const [toast, setToast] = useState(null);

  // Aplicar tema y tweaks al root
  useEffect(() => {
    const root = document.documentElement;
    root.setAttribute('data-theme', tweaks.theme);
    root.style.setProperty('--density', tweaks.density === 'compact' ? 0.82 : 1);
    root.style.setProperty('--radius', `${tweaks.radius}px`);
    root.style.setProperty('--radius-sm', `${Math.max(2, tweaks.radius - 3)}px`);
    const accent = `oklch(0.55 0.12 ${tweaks.accentHue})`;
    const accentSoft = `oklch(0.92 0.04 ${tweaks.accentHue})`;
    root.style.setProperty('--accent', accent);
    root.style.setProperty('--accent-soft', accentSoft);
    const fonts = {
      segoe: '"Segoe UI", system-ui, -apple-system, sans-serif',
      system: 'system-ui, -apple-system, sans-serif',
      inter: '"Inter", system-ui, sans-serif',
      helvetica: '"Helvetica Neue", Helvetica, Arial, sans-serif',
      georgia: 'Georgia, "Times New Roman", serif',
      mono: 'ui-monospace, "JetBrains Mono", "Consolas", monospace',
    };
    root.style.setProperty('--ff-ui', fonts[tweaks.fontFamily] || fonts.segoe);
  }, [tweaks]);

  const currentResult = findNode(fsData, currentId);
  const currentNode = currentResult?.node;
  const pathToCurrent = currentResult?.path || [];

  // Items a mostrar
  const rawItems = useMemo(() => {
    if (!currentNode) return [];
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return flattenFiles(currentNode).filter((f) => f.name.toLowerCase().includes(q));
    }
    return currentNode.children || [];
  }, [currentNode, searchQuery]);

  const items = useMemo(() => {
    const arr = [...rawItems];
    arr.sort((a, b) => {
      if (a.type !== b.type) {
        if (a.type === 'folder' && b.type !== 'folder') return -1;
        if (b.type === 'folder' && a.type !== 'folder') return 1;
      }
      let av, bv;
      if (sortBy === 'name') { av = a.name.toLowerCase(); bv = b.name.toLowerCase(); }
      else if (sortBy === 'modified') { av = a.modified || ''; bv = b.modified || ''; }
      else if (sortBy === 'type') { av = a.ext || (a.type === 'folder' ? 'zzz' : ''); bv = b.ext || (b.type === 'folder' ? 'zzz' : ''); }
      else if (sortBy === 'size') { av = parseSize(a.size); bv = parseSize(b.size); }
      if (av < bv) return sortDir === 'asc' ? -1 : 1;
      if (av > bv) return sortDir === 'asc' ? 1 : -1;
      return 0;
    });
    return arr;
  }, [rawItems, sortBy, sortDir]);

  const navigate = useCallback((id) => {
    if (id === currentId) return;
    const newHistory = history.slice(0, historyIndex + 1);
    newHistory.push(id);
    setHistory(newHistory);
    setHistoryIndex(newHistory.length - 1);
    setSelectedIds(new Set());
    setSearchQuery('');
  }, [currentId, history, historyIndex]);

  const goBack = useCallback(() => {
    if (historyIndex > 0) {
      setHistoryIndex(historyIndex - 1);
      setSelectedIds(new Set());
      setSearchQuery('');
    }
  }, [historyIndex]);

  const goForward = useCallback(() => {
    if (historyIndex < history.length - 1) {
      setHistoryIndex(historyIndex + 1);
      setSelectedIds(new Set());
      setSearchQuery('');
    }
  }, [historyIndex, history.length]);

  const goUp = useCallback(() => {
    if (pathToCurrent.length > 1) {
      const parent = pathToCurrent[pathToCurrent.length - 2];
      navigate(parent.id);
    }
  }, [pathToCurrent, navigate]);

  const showToast = (msg) => {
    setToast(msg);
    setTimeout(() => setToast(null), 1800);
  };

  const handleDoubleClick = useCallback((item) => {
    if (item.type === 'folder' || item.type === 'group' || item.type === 'drive') {
      navigate(item.id);
    } else {
      showToast(`Abriendo "${item.name}"...`);
    }
  }, [navigate]);

  const handleSelect = useCallback((id, e) => {
    if (e && (e.ctrlKey || e.metaKey)) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        if (next.has(id)) next.delete(id); else next.add(id);
        return next;
      });
    } else if (e && e.shiftKey && selectedIds.size > 0) {
      const ids = items.map((i) => i.id);
      const last = [...selectedIds].pop();
      const ia = ids.indexOf(last);
      const ib = ids.indexOf(id);
      const [a, b] = ia < ib ? [ia, ib] : [ib, ia];
      setSelectedIds(new Set(ids.slice(a, b + 1)));
    } else {
      setSelectedIds(new Set([id]));
    }
  }, [items, selectedIds]);

  const handleSort = useCallback((col) => {
    if (sortBy === col) setSortDir((d) => d === 'asc' ? 'desc' : 'asc');
    else { setSortBy(col); setSortDir('asc'); }
  }, [sortBy]);

  const handleDelete = useCallback(() => {
    if (selectedIds.size === 0) return;
    setFsData((prev) => deleteIds(structuredClone(prev), selectedIds));
    showToast(`Eliminado${selectedIds.size > 1 ? 's' : ''} ${selectedIds.size} elemento${selectedIds.size > 1 ? 's' : ''}`);
    setSelectedIds(new Set());
  }, [selectedIds]);

  const handleCopy = useCallback(() => {
    if (selectedIds.size === 0) return;
    showToast(`Copiado${selectedIds.size > 1 ? 's' : ''} al portapapeles`);
  }, [selectedIds]);

  const handleNewFolder = useCallback(() => {
    const newId = `new-${Date.now()}`;
    setFsData((prev) => {
      const clone = structuredClone(prev);
      const result = findNode(clone, currentId);
      if (result && result.node.children) {
        result.node.children.push({
          id: newId,
          name: 'Nueva carpeta',
          type: 'folder',
          kind: 'folder',
          children: [],
          modified: new Date().toLocaleDateString('es-ES'),
        });
      }
      return clone;
    });
    setTimeout(() => setSelectedIds(new Set([newId])), 50);
    showToast('Carpeta creada');
  }, [currentId]);

  const handleRename = (item) => {
    const newName = prompt('Nuevo nombre:', item.name);
    if (!newName) return;
    setFsData((prev) => {
      const clone = structuredClone(prev);
      const res = findNode(clone, item.id);
      if (res) res.node.name = newName;
      return clone;
    });
  };

  const handleContextMenu = (e, target) => {
    e.preventDefault();
    setContextMenu({ x: e.clientX, y: e.clientY, target });
  };

  useEffect(() => {
    const onKey = (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      if (e.key === 'Delete' && selectedIds.size > 0) { handleDelete(); }
      if (e.key === 'Backspace' && pathToCurrent.length > 1) { goUp(); e.preventDefault(); }
      if ((e.ctrlKey || e.metaKey) && e.key === 'a') { setSelectedIds(new Set(items.map(i => i.id))); e.preventDefault(); }
      if (e.key === 'F5') { showToast('Actualizando...'); e.preventDefault(); }
      if (e.altKey && e.key === 'ArrowLeft') { goBack(); e.preventDefault(); }
      if (e.altKey && e.key === 'ArrowRight') { goForward(); e.preventDefault(); }
      if (e.altKey && e.key === 'ArrowUp') { goUp(); e.preventDefault(); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [selectedIds, pathToCurrent, items, handleDelete, goBack, goForward, goUp]);

  const selectedItems = items.filter((i) => selectedIds.has(i.id));
  const previewItem = selectedItems.length === 1 ? selectedItems[0] : null;

  const title = currentNode ? `${currentNode.name}` : 'Explorador';
  const searchPlaceholder = currentNode ? `Buscar en ${currentNode.name}` : 'Buscar';

  return (
    <>
      <div className="desktop-bg" />
      <div className="win-window">
        <WindowChrome
          title={title}
          onClose={() => showToast('Ventana cerrada (demo)')}
          onMin={() => showToast('Minimizada (demo)')}
          onMax={() => showToast('Maximizada (demo)')}
        />
        <AddressBar
          path={pathToCurrent}
          onNavigate={navigate}
          onBack={goBack}
          onForward={goForward}
          onUp={goUp}
          canBack={historyIndex > 0}
          canForward={historyIndex < history.length - 1}
          canUp={pathToCurrent.length > 1}
          searchValue={searchQuery}
          onSearchChange={setSearchQuery}
          searchPlaceholder={searchPlaceholder}
        />
        <CommandBar
          view={view}
          onViewChange={setView}
          selectionCount={selectedIds.size}
          onCopy={handleCopy}
          onDelete={handleDelete}
          onNewFolder={handleNewFolder}
          previewOpen={tweaks.showPreview}
          onTogglePreview={() => setTweak('showPreview', !tweaks.showPreview)}
        />
        <div className="win-body">
          {tweaks.showSidebar && (
            <Sidebar
              tree={fsData}
              currentId={currentId}
              onNavigate={navigate}
              expanded={expanded}
              setExpanded={setExpanded}
            />
          )}
          <div className="win-main">
            <ContentArea
              node={currentNode}
              path={pathToCurrent}
              items={items}
              view={view}
              selectedIds={selectedIds}
              onSelect={handleSelect}
              onDoubleClick={handleDoubleClick}
              searchQuery={searchQuery}
              sortBy={sortBy}
              sortDir={sortDir}
              onSort={handleSort}
              onContextMenu={handleContextMenu}
              onDrop={() => showToast('Archivos soltados aquí (demo)')}
              density={tweaks.density}
            />
          </div>
          {tweaks.showPreview && <PreviewPanel item={previewItem} />}
        </div>
        <StatusBar items={items} selectedItems={selectedItems} currentNode={currentNode} />
      </div>

      {contextMenu && (
        <ContextMenu
          x={contextMenu.x}
          y={contextMenu.y}
          target={contextMenu.target}
          onClose={() => setContextMenu(null)}
          onDelete={handleDelete}
          onCopy={handleCopy}
          onRename={handleRename}
          onOpen={handleDoubleClick}
        />
      )}

      {toast && <div className="toast">{toast}</div>}

      <TweaksUI tweaks={tweaks} setTweak={setTweak} />
    </>
  );
}

function parseSize(s) {
  if (!s) return -1;
  const m = String(s).match(/([\d.]+)\s*(KB|MB|GB|B)/i);
  if (!m) return 0;
  const v = parseFloat(m[1]);
  const unit = m[2].toUpperCase();
  const mul = unit === 'GB' ? 1e9 : unit === 'MB' ? 1e6 : unit === 'KB' ? 1e3 : 1;
  return v * mul;
}

function deleteIds(root, ids) {
  if (!root.children) return root;
  root.children = root.children.filter((c) => !ids.has(c.id));
  root.children.forEach((c) => deleteIds(c, ids));
  return root;
}

function TweaksUI({ tweaks, setTweak }) {
  return (
    <TweaksPanel title="Tweaks">
      <TweakSection label="Tema">
        <TweakSelect
          label="Apariencia"
          value={tweaks.theme}
          onChange={(v) => setTweak('theme', v)}
          options={[
            { value: 'glass', label: 'Glass' },
            { value: 'flat', label: 'Flat Light' },
            { value: 'dark', label: 'Dark Pro' },
            { value: 'warm', label: 'Warm Paper' },
            { value: 'neon', label: 'Neon Terminal' },
          ]}
        />
      </TweakSection>
      <TweakSection label="Layout">
        <TweakRadio
          label="Densidad"
          value={tweaks.density}
          onChange={(v) => setTweak('density', v)}
          options={['comfortable', 'compact']}
        />
        <TweakToggle label="Barra lateral" value={tweaks.showSidebar} onChange={(v) => setTweak('showSidebar', v)} />
        <TweakToggle label="Vista previa" value={tweaks.showPreview} onChange={(v) => setTweak('showPreview', v)} />
      </TweakSection>
      <TweakSection label="Estilo">
        <TweakSlider label="Matiz de acento" min={0} max={360} step={5} value={tweaks.accentHue} unit="°" onChange={(v) => setTweak('accentHue', v)} />
        <TweakSlider label="Radio esquinas" min={0} max={16} step={1} value={tweaks.radius} unit="px" onChange={(v) => setTweak('radius', v)} />
        <TweakSelect
          label="Tipografía"
          value={tweaks.fontFamily}
          onChange={(v) => setTweak('fontFamily', v)}
          options={[
            { value: 'segoe', label: 'Segoe UI' },
            { value: 'system', label: 'Sistema' },
            { value: 'inter', label: 'Inter' },
            { value: 'helvetica', label: 'Helvetica' },
            { value: 'georgia', label: 'Georgia' },
            { value: 'mono', label: 'Monospace' },
          ]}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

window.ExplorerApp = ExplorerApp;
