// ============================================================
//  SUPABASE CONFIGURATION — shared by all 4 pages
//  Replace the two values below with YOUR project credentials:
//  Supabase → Settings → API
// ============================================================

// ── Lightweight REST helper (no library needed) ─────────────
const db = {
  headers: {
    "Content-Type": "application/json",
    apikey: SUPABASE_KEY,
    Authorization: "Bearer " + SUPABASE_KEY,
    Prefer: "return=representation",
  },
  async select(table, query = "") {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}${query}`, {
      headers: this.headers,
    });
    if (!r.ok) {
      const e = await r.text();
      throw new Error(e);
    }
    return r.json();
  },
  async insert(table, data) {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
      method: "POST",
      headers: this.headers,
      body: JSON.stringify(data),
    });
    if (!r.ok) {
      const e = await r.text();
      throw new Error(e);
    }
    return r.json();
  },
  async update(table, id, data) {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}`, {
      method: "PATCH",
      headers: this.headers,
      body: JSON.stringify(data),
    });
    if (!r.ok) {
      const e = await r.text();
      throw new Error(e);
    }
    return r.json();
  },
  async delete(table, id) {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}?id=eq.${id}`, {
      method: "DELETE",
      headers: this.headers,
    });
    if (!r.ok) {
      const e = await r.text();
      throw new Error(e);
    }
    return r.status;
  },
};
