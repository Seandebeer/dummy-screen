// list-ordering helpers shared by the Home panels

// manual order first (ascending), items without one keep newest-first at the end
export function bySortOrder(a, b) {
  const sa = a.sort_order ?? Number.MAX_SAFE_INTEGER;
  const sb = b.sort_order ?? Number.MAX_SAFE_INTEGER;
  if (sa !== sb) return sa - sb;
  return new Date(b.created_date) - new Date(a.created_date);
}

export function arrayMove(arr, from, to) {
  const next = arr.slice();
  const [item] = next.splice(from, 1);
  next.splice(to, 0, item);
  return next;
}