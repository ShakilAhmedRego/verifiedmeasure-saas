export type WorkflowStatus =
  | 'new'
  | 'contacted'
  | 'qualified'
  | 'proposal'
  | 'negotiation'
  | 'closed_won'
  | 'closed_lost'

export type UserRole = 'user' | 'admin' | 'super_admin'

export interface Lead {
  id: string
  company: string
  email: string
  phone: string | null
  
  website: string | null
  industry: string | null
  employee_count: number | null
  annual_revenue: number | null
  founded_year: number | null
  
  city: string | null
  state: string | null
  country: string
  
  intelligence_score: number
  tech_stack: string[] | null
  funding_stage: string | null
  last_funding_amount: number | null
  
  decision_maker_name: string | null
  decision_maker_title: string | null
  decision_maker_linkedin: string | null
  
  workflow: WorkflowStatus
  meta: any
  created_at: string
  updated_at: string
}

export interface UserProfile {
  id: string
  email: string
  full_name: string | null
  company: string | null
  role: UserRole
  avatar_url: string | null
  created_at: string
  updated_at: string
}

export interface LeadAccess {
  id: string
  user_id: string
  lead_id: string
  created_at: string
}

export interface CreditLedger {
  id: string
  user_id: string
  amount: number
  reason: string
  lead_id: string | null
  admin_id: string | null
  meta: any
  created_at: string
}

export interface LeadNote {
  id: string
  user_id: string
  lead_id: string
  note: string
  created_at: string
  updated_at: string
}

export interface LeadSignal {
  id: string
  lead_id: string
  signal_type: string
  severity: number
  title: string
  detail: string | null
  source: string | null
  meta: any
  occurred_at: string
  created_at: string
}

export interface ActivityFeed {
  id: string
  user_id: string
  action: string
  lead_id: string | null
  ref_type: string | null
  ref_id: string | null
  meta: any
  created_at: string
}

export interface SavedView {
  id: string
  user_id: string
  name: string
  description: string | null
  filters: any
  sort: any
  columns: any
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface ExportJob {
  id: string
  user_id: string
  status: string
  kind: string
  requested_lead_ids: string[]
  exported_lead_count: number
  error: string | null
  meta: any
  created_at: string
  updated_at: string
}

export interface FeatureFlag {
  key: string
  enabled: boolean
  description: string | null
  created_at: string
  updated_at: string
}
