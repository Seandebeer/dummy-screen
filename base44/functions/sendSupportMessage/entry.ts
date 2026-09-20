import { createClientFromRequest } from 'npm:@base44/sdk@0.8.44';

// Support: stores a message from an app user and emails it to the dev team
// (every admin of this app). Users can send; only admins can read the records.
export default async function(req) {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json().catch(() => ({}));
    const subject = String(body.subject || '').trim().slice(0, 120);
    const message = String(body.message || '').trim().slice(0, 4000);
    if (!message) return Response.json({ error: 'Message is empty' }, { status: 400 });

    // keep a record the dev team can review
    await base44.entities.SupportMessage.create({
      subject: subject || '(no subject)',
      message,
      from_name: user.full_name || '',
      from_email: user.email || '',
    });

    // notify every admin - registered app users are always reachable by email
    let emailed = 0;
    try {
      const users = await base44.asServiceRole.entities.User.list();
      const admins = (users || []).filter((u) => u.role === 'admin' && u.email).slice(0, 10);
      for (const admin of admins) {
        await base44.asServiceRole.integrations.Core.SendEmail({
          to: admin.email,
          subject: `PropSync support: ${subject || 'new message'}`,
          text: `From: ${user.full_name || ''} <${user.email}>\n\n${message}`,
        });
        emailed += 1;
      }
    } catch {}

    return Response.json({ ok: true, emailed });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
}