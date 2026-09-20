import { createClientFromRequest } from 'npm:@base44/sdk@0.8.44';
import { secrets } from 'base44:runtime';

// GIF search / trending via the Tenor API - bounded input, returns only the
// gif + preview URLs the messaging app needs
export default async function(req) {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });
    const body = await req.json().catch(() => ({})) || {};
    const query = String(body.query || '').slice(0, 60).trim();
    const mode = body.mode === 'trending' || !query ? 'trending' : 'search';
    const apiKey = secrets.get('TENOR_API_KEY');
    if (!apiKey) {
      return Response.json({ error: 'TENOR_API_KEY is not set - add it in the app settings' }, { status: 503 });
    }
    const endpoint = mode === 'trending'
      ? `https://tenor.googleapis.com/v2/trending?key=${encodeURIComponent(apiKey)}&limit=24&media_filter=gif,tinygif&random=true`
      : `https://tenor.googleapis.com/v2/search?q=${encodeURIComponent(query)}&key=${encodeURIComponent(apiKey)}&limit=24&media_filter=gif,tinygif`;
    const response = await fetch(endpoint, { headers: { 'Content-Type': 'application/json' } });
    if (!response.ok) {
      return Response.json({ error: 'GIF search failed' }, { status: 502 });
    }
    const data = await response.json();
    const gifs = (data.results || [])
      .map((g) => ({
        url: g.media_formats?.gif?.url || g.media_formats?.tinygif?.url || '',
        preview: g.media_formats?.tinygif?.url || '',
      }))
      .filter((g) => g.url);
    return Response.json({ gifs });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
}