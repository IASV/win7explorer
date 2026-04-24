// Sidebar de navegación
const { useState: useSState, useEffect: useSEffect, useRef: useSRef } = React;

function Sidebar({ tree, currentId, onNavigate, expanded, setExpanded }) {
  return (
    <div className="sidebar">
      {tree.children.map((group) => (
        <SidebarGroup
          key={group.id}
          group={group}
          currentId={currentId}
          onNavigate={onNavigate}
          expanded={expanded}
          setExpanded={setExpanded}
        />
      ))}
    </div>
  );
}

function SidebarGroup({ group, currentId, onNavigate, expanded, setExpanded }) {
  const isExpanded = expanded[group.id] !== false;
  const GroupIconComp = groupIcon(group.kind);
  return (
    <div className="sb-group">
      <button
        className="sb-group-header"
        onClick={() => setExpanded({ ...expanded, [group.id]: !isExpanded })}
      >
        <span className={`sb-chevron ${isExpanded ? 'open' : ''}`}>
          <svg width="8" height="8" viewBox="0 0 8 8"><path d="M2 1 L6 4 L2 7" stroke="currentColor" strokeWidth="1.4" fill="none" /></svg>
        </span>
        <span className="sb-group-icon"><GroupIconComp /></span>
        <span className="sb-group-label">{group.name}</span>
      </button>
      {isExpanded && (
        <div className="sb-group-items">
          {group.children.map((item) => (
            <SidebarItem
              key={item.id}
              item={item}
              level={0}
              currentId={currentId}
              onNavigate={onNavigate}
              expanded={expanded}
              setExpanded={setExpanded}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function SidebarItem({ item, level, currentId, onNavigate, expanded, setExpanded }) {
  const isCurrent = item.id === currentId;
  const hasChildren = item.children && item.children.length > 0;
  const isExp = !!expanded[item.id];
  return (
    <>
      <button
        className={`sb-item ${isCurrent ? 'current' : ''}`}
        style={{ paddingLeft: 12 + level * 14 }}
        onClick={() => onNavigate(item.id)}
        onDoubleClick={() => hasChildren && setExpanded({ ...expanded, [item.id]: !isExp })}
      >
        <span
          className={`sb-chevron ${isExp ? 'open' : ''} ${hasChildren ? '' : 'hidden'}`}
          onClick={(e) => { e.stopPropagation(); if (hasChildren) setExpanded({ ...expanded, [item.id]: !isExp }); }}
        >
          {hasChildren && <svg width="8" height="8" viewBox="0 0 8 8"><path d="M2 1 L6 4 L2 7" stroke="currentColor" strokeWidth="1.4" fill="none" /></svg>}
        </span>
        <span className="sb-item-icon">
          <ItemTinyIcon item={item} />
        </span>
        <span className="sb-item-label">{item.name}</span>
      </button>
      {isExp && hasChildren && item.children.filter(c => c.type !== 'file').map((child) => (
        <SidebarItem
          key={child.id}
          item={child}
          level={level + 1}
          currentId={currentId}
          onNavigate={onNavigate}
          expanded={expanded}
          setExpanded={setExpanded}
        />
      ))}
    </>
  );
}

function groupIcon(kind) {
  if (kind === 'favorites') return () => <StarIcon size={14} />;
  if (kind === 'libraries') return () => <BookshelfIcon size={15} />;
  if (kind === 'computer') return () => <ComputerIcon size={15} />;
  if (kind === 'network') return () => <NetworkIcon size={15} />;
  return () => <FolderIcon size={14} kind="folder" />;
}

function ItemTinyIcon({ item }) {
  if (item.type === 'drive') return <DriveIcon size={16} kind={item.kind} />;
  if (item.type === 'file') return <FileIcon size={14} ext={item.ext} />;
  return <FolderIcon size={16} kind={item.kind || 'folder'} />;
}

Object.assign(window, { Sidebar });
