import { useState, useEffect } from 'react'
import { supabase } from '@/lib/supabaseClient'
import { Lead, UserProfile, FeatureFlag } from '@/lib/types'

export function useUser() {
  const [user, setUser] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchUser = async () => {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      
      if (authUser) {
        const { data } = await supabase
          .from('user_profiles')
          .select('*')
          .eq('id', authUser.id)
          .single()
        
        setUser(data)
      }
      
      setLoading(false)
    }

    fetchUser()
  }, [])

  return { user, loading }
}

export function useCredits() {
  const [credits, setCredits] = useState(0)
  const [loading, setLoading] = useState(true)

  const fetchCredits = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (user) {
      const { data } = await supabase.rpc('get_credit_balance', {
        p_user_id: user.id
      })
      
      setCredits(data || 0)
    }
    
    setLoading(false)
  }

  useEffect(() => {
    fetchCredits()
  }, [])

  const refresh = () => fetchCredits()

  return { credits, loading, refresh }
}

export function useEntitledLeads() {
  const [entitledIds, setEntitledIds] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)

  const fetchEntitled = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    
    if (user) {
      const { data } = await supabase
        .from('lead_access')
        .select('lead_id')
        .eq('user_id', user.id)
      
      if (data) {
        setEntitledIds(new Set(data.map(item => item.lead_id)))
      }
    }
    
    setLoading(false)
  }

  useEffect(() => {
    fetchEntitled()
  }, [])

  const refresh = () => fetchEntitled()

  return { entitledIds, loading, refresh }
}

export function useFeatureFlags() {
  const [flags, setFlags] = useState<Record<string, boolean>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchFlags = async () => {
      const { data } = await supabase
        .from('feature_flags')
        .select('key, enabled')
      
      if (data) {
        const flagMap: Record<string, boolean> = {}
        data.forEach(flag => {
          flagMap[flag.key] = flag.enabled
        })
        setFlags(flagMap)
      }
      
      setLoading(false)
    }

    fetchFlags()
  }, [])

  const isEnabled = (key: string) => flags[key] === true

  return { flags, isEnabled, loading }
}

export function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') {
      return initialValue
    }
    
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      return initialValue
    }
  })

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value
      setStoredValue(valueToStore)
      
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore))
      }
    } catch (error) {
      console.error(error)
    }
  }

  return [storedValue, setValue] as const
}

export function useDarkMode() {
  const [isDark, setIsDark] = useLocalStorage('darkMode', false)

  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }, [isDark])

  return [isDark, setIsDark] as const
}
