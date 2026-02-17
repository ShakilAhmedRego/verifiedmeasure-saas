import type { Metadata } from 'next'
import { ToastProvider } from '@/components/Toast'
import '@/styles/globals.css'

export const metadata: Metadata = {
  title: 'VerifiedMeasure - SaaS Intelligence Platform',
  description: 'Enterprise sales intelligence for SaaS companies',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <ToastProvider>
          {children}
        </ToastProvider>
      </body>
    </html>
  )
}
