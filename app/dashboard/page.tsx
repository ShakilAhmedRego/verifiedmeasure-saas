'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabaseClient'
import { Lead } from '@/lib/types'
import { maskLead, formatCurrency, getScoreColor } from '@/lib/utils'
import { useCredits, useEntitledLeads } from '@/lib/hooks'
import { useToast } from '@/components/Toast'
import CommandPalette from '@/components/CommandPalette'

export default function DashboardPage() {
  const [leads, setLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [unlocking, setUnlocking] = useState(false)

  const router = useRouter()
  const { credits, refresh: refreshCredits } = useCredits()
  const { entitledIds, refresh: refreshEntitled } = useEntitledLeads()
  const { showToast } = useToast()

  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      router.push('/auth')
      return
    }
    loadLeads()
  }

  const loadLeads = async () => {
    setLoading(true)
    const { data } = await supabase
      .from('leads')
      .select('*')
      .order('intelligence_score', { ascending: false })

    if (data) {
      setLeads(data as Lead[])
    }
    setLoading(false)
  }

  const handleUnlock = async () => {
    if (selectedIds.size === 0) return

    const cost = selectedIds.size
    if (credits < cost) {
      showToast(`Insufficient credits. Need ${cost}, have ${credits}`, 'error')
      return
    }

    setUnlocking(true)
    try {
      const { data, error } = await supabase.rpc('unlock_leads_secure', {
        p_lead_ids: Array.from(selectedIds)
      })

      if (error) throw error

      showToast(`Unlocked ${data.unlocked} leads!`, 'success')
      setSelectedIds(new Set())
      refreshCredits()
      refreshEntitled()
      setTimeout(loadLeads, 500)
    } catch (error: any) {
      showToast(error.message, 'error')
    } finally {
      setUnlocking(false)
    }
  }

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push('/auth')
  }

  const filteredLeads = leads.filter(lead =>
    lead.company.toLowerCase().includes(searchTerm.toLowerCase()) ||
    lead.industry?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    lead.city?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const unentitledLeads = filteredLeads.filter(l => !entitledIds.has(l.id))

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <CommandPalette leads={leads} />

      <div className="bg-white border-b sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gradient">VerifiedMeasure</h1>
            <div className="flex items-center gap-6">
              <div className="text-right">
                <div className="text-sm text-gray-600">Credits</div>
                <div className="text-2xl font-bold text-blue-600">{credits}</div>
              </div>
              <button onClick={handleSignOut} className="btn-secondary">Sign Out</button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

        {/* Selection Bar */}
        {unentitledLeads.length > 0 && (
          <div className="card p-4 mb-6 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setSelectedIds(new Set(unentitledLeads.map(l => l.id)))}
                className="btn-secondary text-sm"
              >
                Select All ({unentitledLeads.length})
              </button>

              {selectedIds.size > 0 && (
                <button onClick={() => setSelectedIds(new Set())} className="text-sm text-gray-600">
                  Clear
                </button>
              )}

              <div className="text-sm text-gray-600">
                {selectedIds.size} selected • Cost: {selectedIds.size} credits
              </div>
            </div>

            {selectedIds.size > 0 && (
              <button
                onClick={handleUnlock}
                disabled={unlocking || credits < selectedIds.size}
                className="btn-primary animate-pulse-slow"
              >
                {unlocking
                  ? 'Unlocking...'
                  : `Unlock ${selectedIds.size} for ${selectedIds.size} credits`}
              </button>
            )}
          </div>
        )}

        {/* Lead Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredLeads.map(lead => {
            const isEntitled = entitledIds.has(lead.id)
            const maskedLead = maskLead(lead, isEntitled)
            const isSelected = selectedIds.has(lead.id)

            return (
              <div key={lead.id} className="card p-6 hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="font-bold text-lg">{maskedLead.company}</h3>
                    <p className="text-sm text-gray-600">{lead.industry || 'N/A'}</p>
                  </div>

                  {!isEntitled ? (
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={(e) => {
                        const newSet = new Set(selectedIds)
                        e.target.checked ? newSet.add(lead.id) : newSet.delete(lead.id)
                        setSelectedIds(newSet)
                      }}
                      className="h-5 w-5 rounded border-gray-300 text-blue-600"
                    />
                  ) : (
                    <div className="text-green-600">✓</div>
                  )}
                </div>

                <div className="flex justify-between text-sm mb-2">
                  <span>Score</span>
                  <span className={`font-bold ${getScoreColor(lead.intelligence_score)}`}>
                    {lead.intelligence_score}
                  </span>
                </div>

                <div className="flex justify-between text-sm mb-2">
                  <span>Revenue</span>
                  <span>{formatCurrency(lead.annual_revenue)}</span>
                </div>

                <div className="text-sm mt-3">
                  <div className="text-xs text-gray-500">Email</div>
                  <div>{maskedLead.email}</div>
                </div>

                <div className="text-sm mt-2">
                  <div className="text-xs text-gray-500">Phone</div>
                  <div>{maskedLead.phone}</div>
                </div>
              </div>
            )
          })}
        </div>

      </div>
    </div>
  )
}
