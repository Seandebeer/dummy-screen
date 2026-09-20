// A user's role on a project: owner (account holder), editor, viewer or none.
// Project visibility itself is enforced server-side by row-level security -
// this helper only labels the role for the UI.
export function myAccess(project, user) {
  if (!user) return "loading";
  if (user.role === "admin" || project.created_by_id === user.id) return "owner";
  const me = (user.email || "").toLowerCase();
  if ((project.editors || []).includes(me)) return "editor";
  if ((project.viewers || []).includes(me)) return "viewer";
  return "none";
}