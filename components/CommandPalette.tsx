'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { Lead } from '@/lib/types'

interface CommandPaletteProps {
  leads: Lead[]
  onSelectLead?: (lead: Lead) => void
}

export default function CommandPalette({ leads, onSelectLead }: CommandPaletteProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [search, setSearch] = useState('')
  const router = useRouter()
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault()
        setIsOpen(prev => !prev)
      }
      if (e.key === 'Escape') {
        setIsOpen(false)
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus()
    }
  }, [isOpen])

  const filteredLeads = leads.filter(lead =>
    lead.company.toLowerCase().includes(search.toLowerCase()) ||
    lead.industry?.toLowerCase().includes(search.toLowerCase()) ||
    lead.city?.toLowerCase().includes(search.toLowerCase())
  ).slice(0, 5)

  const handleSelect = (lead: Lead) => {
    setIsOpen(false)
    setSearch('')
    if (onSelectLead) {
      onSelectLead(lead)
    }
  }

  const commands = [
    { label: 'Dashboard', action: () => router.push('/dashboard') },
    { label: 'Portfolio', action: () => router.push('/portfolio') },
    { label: 'Admin', action: () => router.push('/admin') },
  ]

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 bg-black bg-opacity-50 animate-fade-in">
      <div className="w-full max-w-2xl bg-white rounded-xl shadow-2xl overflow-hidden animate-slide-down">
        <div className="p-4 border-b">
          <input
            ref={inputRef}
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search companies, industries, locations..."
            className="w-full px-4 py-3 text-lg border-0 focus:outline-none focus:ring-0"
          />
        </div>

        <div className="max-h-96 overflow-y-auto">
          {search === '' && (
            <div className="p-2">
              <div className="px-4 py-2 text-xs font-semibold text-gray-400 uppercase">Quick Actions</div>
              {commands.map((cmd, i) => (
                <button
                  key={i}
                  onClick={() => {
                    cmd.action()
                    setIsOpen(false)
                  }}
                  className="w-full px-4 py-3 text-left hover:bg-gray-100 transition-colors"
                >
                  {cmd.label}
                </button>
              ))}
            </div>
          )}

          {search !== '' && (
            <div className="p-2">
              <div className="px-4 py-2 text-xs font-semibold text-gray-400 uppercase">
                Leads ({filteredLeads.length})
              </div>
              {filteredLeads.map(lead => (
                <button
                  key={lead.id}
                  onClick={() => handleSelect(lead)}
                  className="w-full px-4 py-3 text-left hover:bg-gray-100 transition-colors flex items-center justify-between"
                >
                  <div>
                    <div className="font-medium">{lead.company}</div>
                    <div className="text-sm text-gray-600">
                      {lead.industry} • {lead.city}, {lead.state}
                    </div>
                  </div>
                  <div className="text-sm font-semibold text-blue-600">
                    Score: {lead.intelligence_score}
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="px-4 py-3 bg-gray-50 border-t text-xs text-gray-500">
          Press <kbd className="px-2 py-1 bg-white border rounded">⌘K</kbd> or <kbd className="px-2 py-1 bg-white border rounded">Ctrl+K</kbd> to toggle • <kbd className="px-2 py-1 bg-white border rounded">ESC</kbd> to close
        </div>
      </div>
    </div>
  )
}
