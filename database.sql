-- ============================================================
--  IT Helpdesk Ticketing System — Supabase Database Setup
-- ============================================================

-- 1. DROP existing tables (safe re-run)
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS departments;

-- ============================================================
-- 2. CREATE departments table
-- ============================================================
CREATE TABLE departments (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL UNIQUE,
    floor        INTEGER       NOT NULL CHECK (floor BETWEEN 1 AND 10),
    contact_email VARCHAR(150) NOT NULL,
    manager_name  VARCHAR(100),
    created_at   TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE departments IS 'Company departments that can submit IT helpdesk tickets';

-- ============================================================
-- 3. CREATE tickets table (Foreign Key → departments)
-- ============================================================
CREATE TABLE tickets (
    id           SERIAL PRIMARY KEY,
    title        VARCHAR(200)  NOT NULL,
    description  TEXT          NOT NULL,
    priority     VARCHAR(10)   NOT NULL CHECK (priority IN ('Low', 'Medium', 'High')),
    status       VARCHAR(15)   NOT NULL DEFAULT 'Open'
                               CHECK (status IN ('Open', 'In-Progress', 'Resolved')),
    department_id INTEGER      NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
    submitter_name VARCHAR(100),
    created_at   TIMESTAMPTZ   DEFAULT NOW(),
    updated_at   TIMESTAMPTZ   DEFAULT NOW()
);

COMMENT ON TABLE tickets IS 'IT support tickets submitted by employees, linked to a department';

-- ============================================================
-- 4. INDEXES for performance
-- ============================================================
CREATE INDEX idx_tickets_status       ON tickets(status);
CREATE INDEX idx_tickets_priority     ON tickets(priority);
CREATE INDEX idx_tickets_department   ON tickets(department_id);
CREATE INDEX idx_tickets_created      ON tickets(created_at DESC);

-- ============================================================
-- 5. AUTO-UPDATE updated_at trigger
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tickets_updated_at
    BEFORE UPDATE ON tickets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 6. SEED DATA — Departments
-- ============================================================
INSERT INTO departments (name, floor, contact_email, manager_name) VALUES
    ('Human Resources',     2, 'hr@company.ie',          'Sarah O''Brien'),
    ('Finance',             3, 'finance@company.ie',     'Liam Murphy'),
    ('Information Technology', 4, 'it@company.ie',       'Conor Walsh'),
    ('Marketing',           1, 'marketing@company.ie',   'Emma Doyle'),
    ('Operations',          5, 'operations@company.ie',  'Patrick Flynn'),
    ('Legal',               6, 'legal@company.ie',       'Niamh Kelly'),
    ('Customer Support',    1, 'support@company.ie',     'James Ryan'),
    ('Research & Development', 7, 'rnd@company.ie',      'Aoife Byrne');

-- ============================================================
-- 7. SEED DATA — Tickets
-- ============================================================
INSERT INTO tickets (title, description, priority, status, department_id, submitter_name) VALUES
    ('Cannot connect to VPN',           'VPN client throws error 800 on Windows 11. Tried reinstalling — same issue.',              'High',   'Open',        3, 'Tom Brennan'),
    ('Printer not responding',          'Shared printer on floor 2 offline. Other users affected. Shows offline in print queue.',   'Medium', 'In-Progress', 1, 'Mary Collins'),
    ('Forgot Windows password',         'Locked out after too many attempts. Need password reset.',                                 'High',   'Open',        2, 'David Lynch'),
    ('Email signature not displaying',  'Outlook signature disappears after every update. Affects all @company.ie accounts.',       'Low',    'Open',        4, 'Claire Sheridan'),
    ('Laptop running extremely slow',   'MacBook Pro takes 10+ minutes to boot. Only 2 apps open. SSD might be failing.',           'High',   'In-Progress', 5, 'Kevin O''Sullivan'),
    ('Cannot access shared drive',      'No access to \\server\finance folder since Monday. Permissions issue.',                    'High',   'Resolved',    2, 'Sinéad Farrell'),
    ('Teams audio not working',         'Microphone not detected in Microsoft Teams. Works fine in other apps.',                    'Medium', 'Open',        7, 'Brian Nolan'),
    ('Software licence expired',        'Adobe Creative Cloud showing licence expired. Need renewal or alternative.',               'Medium', 'Resolved',    4, 'Orla Hennessy'),
    ('Monitor flickering',              'Second monitor flickers every 30 seconds. Cable replaced — still happening.',              'Low',    'Open',        6, 'Declan Dunne'),
    ('New employee setup required',     'Onboarding 3 new staff next Monday. Need accounts, email, and hardware.',                  'High',   'In-Progress', 1, 'Sarah O''Brien'),
    ('Website login broken',            'Company intranet returns 403 after recent AD changes.',                                    'High',   'Open',        8, 'Fiona McCarthy'),
    ('Keyboard shortcuts stopped',      'Ctrl+C / Ctrl+V not working in Excel only. Windows shortcuts fine.',                       'Low',    'Resolved',    3, 'Alan Power'),
    ('Zoom background not saving',      'Custom Zoom virtual background resets after every meeting.',                               'Low',    'Open',        7, 'Ruth Gallagher'),
    ('Server room temperature alert',   'HVAC sensor reading 28°C — threshold is 24°C. Physical inspection needed.',                'High',   'In-Progress', 3, 'Conor Walsh'),
    ('Data backup failure',             'Nightly backup job failed 3 nights in a row. Alert in monitoring dashboard.',              'High',   'Open',        8, 'Aoife Byrne');

-- ============================================================
-- 8. ROW LEVEL SECURITY (Supabase — allow anon reads, auth writes)
-- ============================================================
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets     ENABLE ROW LEVEL SECURITY;

-- Allow anyone to READ (your app uses anon key for SELECT)
CREATE POLICY "Public read departments" ON departments FOR SELECT USING (true);
CREATE POLICY "Public read tickets"     ON tickets     FOR SELECT USING (true);

-- Allow anyone to INSERT tickets (employees submit tickets without login)
CREATE POLICY "Public insert tickets"   ON tickets     FOR INSERT WITH CHECK (true);

-- Allow anyone to UPDATE ticket status (IT staff update from dashboard)
CREATE POLICY "Public update tickets"   ON tickets     FOR UPDATE USING (true);

-- Allow anyone to DELETE tickets (IT staff delete spam)
CREATE POLICY "Public delete tickets"   ON tickets     FOR DELETE USING (true);

-- Departments are managed by admin only — restrict INSERT/UPDATE/DELETE
-- (For this project, seed data is enough — no public department creation)

-- ============================================================
-- 9. VERIFY — Run to confirm setup
-- ============================================================
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'tickets', COUNT(*) FROM tickets;

-- ============================================================
-- 10. CREATE 3rd TABLE: faqs (Dynamic Knowledge Base)
-- ============================================================
CREATE TABLE faqs (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    icon VARCHAR(50) NOT NULL,
    question VARCHAR(255) NOT NULL,
    answer TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE faqs IS 'Dynamic FAQs for the Helpdesk Knowledge Base';
INSERT INTO faqs (category, icon, question, answer) VALUES
('network', 'wifi-off', 'How do I connect to the company Wi-Fi?', '<p>Select <strong>CorpNet-Secure</strong> in your Wi-Fi settings and enter your company login credentials.</p><ul><li>Windows: Settings → Network & Internet → Wi-Fi</li><li>Mac: Menu bar Wi-Fi → CorpNet-Secure</li><li>If you see a certificate warning, click <strong>Trust</strong></li></ul>'),
('network', 'shield', 'How do I set up or reconnect to the VPN?', '<p>We use <strong>Cisco AnyConnect</strong>. Download it from <code>software.company.internal</code>, sign in with your company email.</p><ul><li>Approve the MFA prompt on your registered phone</li><li>Error 442 after Windows update? Update the AnyConnect client</li></ul>'),
('accounts', 'key-round', 'How do I reset my password?', '<p>Go to <code>password.company.internal</code> → "Forgot Password". A reset link is sent via SMS.</p><ul><li>Min 12 characters, 1 uppercase, 1 number, 1 symbol</li><li>Cannot reuse last 5 passwords</li><li>Locked out? Call IT at ext. <strong>4357</strong></li></ul>'),
('accounts', 'user-plus', 'How do I request access to a shared folder?', '<p>Your manager must approve access requests. They can email <code>it-access@company.com</code> with your employee ID and required permissions. Standard turnaround: 1 business day.</p>'),
('hardware', 'printer', 'How do I connect to the office printer?', '<p>Settings → Printers & Scanners → Add a printer → search <code>HP-Office-Floor{your_floor}</code>. Driver installs automatically.</p><ul><li>Printer offline? Check power and network cable</li><li>Toner low? Submit a ticket — replaced within 4 hours</li></ul>'),
('hardware', 'monitor', 'My monitor is flickering or won''t turn on', '<ul><li>Check all display cables are firmly seated</li><li>Restart the computer completely</li><li>Try a different port (HDMI → DisplayPort)</li><li>Update graphics drivers via Device Manager → Display Adapters</li><li>Hardware fault? Submit a High priority ticket with your asset tag</li></ul>'),
('software', 'mail', 'Outlook is not syncing my emails', '<p>Run the built-in Office repair tool:</p><ul><li>Close Outlook → Control Panel → Programs → Office → Quick Repair</li><li>Restart and reopen Outlook</li><li>If the issue persists, submit a Medium priority ticket</li></ul>'),
('software', 'download', 'How do I install approved software?', '<p>Use <strong>Company Portal</strong> (Windows) or <strong>Self Service</strong> (Mac) — no admin rights needed. New software requests take 3–5 business days to approve.</p>');

-- Включаем RLS
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read faqs" ON faqs FOR SELECT USING (true);
