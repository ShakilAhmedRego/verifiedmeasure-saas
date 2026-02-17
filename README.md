# VerifiedMeasure SaaS Intelligence Platform

🚀 **Enterprise-Grade Sales Intelligence Platform** for SaaS Companies

## ✨ Features

### 🎨 Premium UI/UX
- **Glassmorphism Design** with animated gradients
- **Dark Mode** with localStorage persistence
- **Command Palette** (⌘K / Ctrl+K) for power users
- **Toast Notifications** for all actions
- **Responsive Design** - Mobile to Desktop
- **Loading Skeletons** and smooth animations

### 🔐 Security & Access Control
- **Preview Model** - All users see all leads (masked)
- **RPC-Only Unlocking** - Zero client bypass
- **Credit System** - Ledger-based balance tracking
- **Row Level Security** on all tables
- **Audit Logging** for all critical actions
- **Feature Flags** for gradual rollouts

### 📊 Intelligence Features
- **Lead Scoring** (0-100) with visual indicators
- **Signal Timeline** - Track company events
- **Tech Stack Detection**
- **Funding Stage** & amount tracking
- **Workflow Management** (7 stages)
- **Activity Feed** - Personal activity timeline

### 🎯 Power Features
- **Advanced Filters** - Score, revenue, employee count
- **Search** - Full-text across all fields
- **Bulk Selection** - Select all unentitled leads
- **Batch Unlock** with credit checking
- **Export** - Entitled leads to CSV
- **Saved Views** - Save filter configurations
- **Lead Notes** - Add private notes to any lead

### 📈 Analytics
- **KPI Cards** - Unlocked, Score, Conversion
- **Workflow Breakdown** - Pipeline visualization
- **Intelligence Distribution** - Score analytics
- **Activity Trends** - User engagement metrics

## 🚀 Quick Start

### 1. Clone & Install

```bash
git clone <your-repo>
cd verifiedmeasure-saas-intelligence
npm install
```

### 2. Environment Variables

Create `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Database Setup

1. Go to your Supabase project
2. Open SQL Editor
3. Copy contents of `supabase/DATABASE_SETUP.sql`
4. Run it **once**

### 4. Create First User

```bash
# Sign up via the app at /auth
# Or use Supabase Dashboard > Authentication > Add User
```

### 5. Promote to Admin (Optional)

```sql
update public.user_profiles
set role = 'admin'
where email = 'your@email.com';
```

### 6. Grant Initial Credits

```sql
insert into public.credit_ledger(user_id, amount, reason)
select id, 100, 'Initial credits'
from public.user_profiles
where email = 'your@email.com';
```

### 7. Run Development Server

```bash
npm run dev
```

Visit `http://localhost:3000`

## 📁 Project Structure

```
/app
  /auth           # Sign in / Sign up
  /dashboard      # Main intelligence dashboard
  /portfolio      # Entitled leads view
  /admin          # Admin console

/components
  Toast.tsx       # Notification system
  CommandPalette.tsx  # ⌘K search
  Sidebar.tsx     # Navigation
  TopNav.tsx      # Header with credits
  LeadCard.tsx    # Company cards
  DetailDrawer.tsx    # Lead details
  Filters.tsx     # Advanced filtering

/lib
  supabaseClient.ts   # Supabase setup
  types.ts        # TypeScript interfaces
  utils.ts        # Helper functions
  hooks.ts        # Custom React hooks

/supabase
  DATABASE_SETUP.sql  # Complete schema
```

## 🎯 Core Concepts

### Preview Model

**All authenticated users can view all leads** - This creates discovery.

- Sensitive fields (company, email, phone, decision maker) are **masked**
- Meta fields (industry, location, score, tech stack) are **visible**
- Users can select and unlock leads they want

### Credit System

Credits are tracked via a **ledger** system:

```sql
-- Balance = SUM of all credit_ledger entries
select sum(amount) from credit_ledger where user_id = 'xxx';
```

- Unlocking 1 lead = -1 credit
- Admins can grant credits
- All transactions logged in audit_log

### RPC Security

**NO direct UPDATE/INSERT on sensitive tables**

All mutations go through RPC functions:

- `unlock_leads_secure(lead_ids)` - Unlock with credit check
- `admin_grant_credits(user_id, amount, reason)` - Admin only
- `set_workflow_secure(lead_id, workflow)` - Update stage
- `add_lead_note_secure(lead_id, note)` - Add note
- `create_entitled_export_job(lead_ids)` - Export CSV

## 🎨 UI Components

### Command Palette (⌘K)

Global search and navigation:

```typescript
// Press ⌘K anywhere
// Search companies, industries, locations
// Quick navigation to pages
```

### Dark Mode

Toggle in TopNav:

```typescript
// Uses localStorage
// Persists across sessions
// Automatic class switching
```

### Toast Notifications

```typescript
import { useToast } from '@/components/Toast'

const { showToast } = useToast()

showToast('Lead unlocked!', 'success')
showToast('Insufficient credits', 'error')
```

## 📊 Sample Data

### Insert Test Leads

```sql
insert into public.leads(
  company, email, phone, website,
  industry, employee_count, annual_revenue,
  city, state, country,
  intelligence_score, tech_stack, funding_stage,
  decision_maker_name, decision_maker_title,
  workflow
)
values
(
  'Acme SaaS Inc',
  'contact@acmesaas.com',
  '(555) 123-4567',
  'https://acmesaas.com',
  'Enterprise Software',
  250,
  15000000,
  'San Francisco',
  'CA',
  'USA',
  85,
  array['React', 'PostgreSQL', 'AWS'],
  'Series B',
  'Jane Smith',
  'VP of Sales',
  'new'
),
(
  'CloudTech Solutions',
  'hello@cloudtech.io',
  '(555) 987-6543',
  'https://cloudtech.io',
  'Cloud Infrastructure',
  500,
  50000000,
  'Austin',
  'TX',
  'USA',
  92,
  array['Kubernetes', 'Python', 'GCP'],
  'Series C',
  'John Doe',
  'CRO',
  'qualified'
);
```

### Insert Signals (Intelligence Timeline)

```sql
insert into public.lead_signals(
  lead_id, signal_type, severity, title, detail, source
)
select
  id,
  'funding',
  3,
  'Series B Funding Announced',
  'Raised $25M led by Sequoia Capital',
  'Crunchbase'
from public.leads
where company = 'Acme SaaS Inc';
```

## 🔧 Configuration

### Feature Flags

Toggle features via admin:

```sql
-- Enable/disable features
update public.feature_flags
set enabled = true
where key = 'detail_drawer';
```

Or via Admin UI:

```typescript
// Admin console has feature flag management
```

### Workflow Stages

Customize in `DATABASE_SETUP.sql`:

```sql
create type public.workflow_status as enum (
  'new',
  'contacted',
  'qualified',
  'proposal',
  'negotiation',
  'closed_won',
  'closed_lost'
);
```

## 🚀 Deployment

### Vercel (Recommended)

1. Push to GitHub
2. Import to Vercel
3. Add environment variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
4. Deploy!

### Build Locally

```bash
npm run build
npm start
```

## 🎯 Usage Scenarios

### Sales Team Member

1. Sign in → Dashboard
2. See all available leads (masked)
3. Use filters to find target companies
4. Select interesting leads
5. Unlock with credits
6. View full details
7. Add to workflow
8. Track in portfolio
9. Export to CSV

### Admin

1. Sign in → Admin Console
2. Grant credits to team
3. View audit logs
4. Manage feature flags
5. Monitor usage analytics

### Power User

1. Press ⌘K to search
2. Use saved views
3. Bulk select + unlock
4. Add notes to leads
5. Track signals
6. Export entitled leads

## 🔒 Security Notes

- ✅ RLS enabled on ALL tables
- ✅ RPC functions with SECURITY DEFINER
- ✅ No service role key needed
- ✅ Auth validation in all RPCs
- ✅ Audit logging for sensitive actions
- ✅ Credit balance = SUM(ledger) - no direct manipulation

## 📝 License

Proprietary - VerifiedMeasure Enterprise

## 🆘 Support

For issues:
1. Check database setup was run correctly
2. Verify environment variables
3. Check browser console for errors
4. Review Supabase logs

---

**Built with:** Next.js 14 • TypeScript • Tailwind CSS • Supabase
