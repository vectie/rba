import { defineConfig } from 'vite'
import rabbita from '@rabbita/vite'
import { join, sep } from 'path'
import { cpSync } from 'fs'

function skipBuildCache(source) {
  const parts = source.split(sep)
  return !parts.includes('_build') && !parts.includes('.mooncakes')
}

function siteBase() {
  const value = process.env.VITE_BASE || '/'
  if (value === '/') return '/'
  const withLeadingSlash = value.startsWith('/') ? value : `/${value}`
  return withLeadingSlash.endsWith('/') ? withLeadingSlash : `${withLeadingSlash}/`
}

export default defineConfig({
  base: siteBase(),
  publicDir: 'public',
  plugins: [
    rabbita(),
    {
      name: 'copy-static-assets',
      closeBundle() {
        const distDir = join(process.cwd(), 'dist')
        cpSync(
          join(process.cwd(), '../../doc'),
          join(distDir, 'doc'),
          { recursive: true, filter: skipBuildCache },
        )
      },
    },
  ],
  server: {
    host: true,
    fs: { allow: ['../..'] },
  },
})
