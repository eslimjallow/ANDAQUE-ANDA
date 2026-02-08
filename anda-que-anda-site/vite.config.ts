import { resolve } from 'node:path'
import { defineConfig } from 'vite'

// Plain HTML multi-page site (no React).
export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        index: resolve(__dirname, 'index.html'),
        agenda: resolve(__dirname, 'agenda.html'),
        productions: resolve(__dirname, 'productions.html'),
        gallery: resolve(__dirname, 'gallery.html'),
        members: resolve(__dirname, 'members.html'),
        contact: resolve(__dirname, 'contact.html'),
      },
    },
  },
})
