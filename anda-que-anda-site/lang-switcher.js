;(function () {
  const LANGS = [
    { code: 'en', label: 'English' },
    { code: 'ar', label: 'Arabic' },
    { code: 'pt', label: 'Portuguese' },
    { code: 'zh-CN', label: 'Chinese' },
    { code: 'fr', label: 'French' },
  ]

  function injectStyles() {
    const style = document.createElement('style')
    style.textContent = `
      #aqa-lang-switcher {
        display: inline-flex;
        align-items: center;
        flex-shrink: 0;
      }
      #aqa-lang-switcher.aqa-lang-switcher--floating {
        position: fixed;
        right: 18px;
        top: 82px;
        z-index: 9999;
        padding: 9px 12px;
        border: 1px solid rgba(24, 128, 64, 0.2);
        border-radius: 14px;
        background: rgba(255, 255, 255, 0.98);
        box-shadow: 0 10px 24px rgba(17, 24, 39, 0.14);
        backdrop-filter: blur(8px);
      }
      #aqa-lang-switcher.aqa-lang-switcher--inline {
        position: relative;
        padding: 0;
        border: none;
        background: transparent;
        box-shadow: none;
        backdrop-filter: none;
      }
      #aqa-lang-host {
        display: inline-flex;
        align-items: center;
        flex-shrink: 0;
      }
      #aqa-lang-switcher select {
        border: 1px solid rgba(0, 0, 0, 0.12);
        border-radius: 999px;
        padding: 0 28px 0 10px;
        height: 2.5rem;
        min-height: 2.5rem;
        font-size: 12px;
        font-weight: 600;
        background: rgba(255, 255, 255, 0.7);
        color: #111827;
        outline: none;
        cursor: pointer;
        max-width: 9.5rem;
      }
      #aqa-lang-switcher.aqa-lang-switcher--inline select {
        border-color: rgba(0, 0, 0, 0.1);
        background: rgba(255, 255, 255, 0.7);
        backdrop-filter: blur(8px);
      }
      #aqa-lang-switcher select:focus {
        border-color: rgba(24, 128, 64, 0.55);
        box-shadow: 0 0 0 3px rgba(24, 128, 64, 0.15);
      }
      .goog-te-banner-frame.skiptranslate,
      .goog-logo-link,
      .goog-te-gadget span,
      #goog-gt-tt,
      .goog-te-balloon-frame {
        display: none !important;
      }
      body {
        top: 0 !important;
      }
      #google_translate_element {
        position: fixed;
        width: 1px;
        height: 1px;
        overflow: hidden;
        opacity: 0;
        pointer-events: none;
      }
      @media (max-width: 640px) {
        #aqa-lang-switcher.aqa-lang-switcher--floating {
          right: 10px;
          top: auto;
          bottom: 84px;
          padding: 8px 10px;
        }
      }
    `
    document.head.appendChild(style)
  }

  function getGoogSelect() {
    return document.querySelector('.goog-te-combo')
  }

  function applyLanguage(langCode) {
    const googSelect = getGoogSelect()
    if (!googSelect) return false
    googSelect.value = langCode
    googSelect.dispatchEvent(new Event('change'))
    return true
  }

  function createSwitcher() {
    const mountHost = document.getElementById('aqa-lang-host')
    const host = document.createElement('div')
    host.id = 'aqa-lang-switcher'
    host.classList.add('notranslate')
    host.setAttribute('translate', 'no')
    if (mountHost) {
      host.classList.add('aqa-lang-switcher--inline')
    } else {
      host.classList.add('aqa-lang-switcher--floating')
    }

    const select = document.createElement('select')
    select.id = 'aqa-lang-select'
    select.setAttribute('aria-label', 'Idioma')
    select.title = 'Idioma'
    select.classList.add('notranslate')
    select.setAttribute('translate', 'no')

    const base = document.createElement('option')
    base.value = 'es'
    base.textContent = 'Español'
    base.classList.add('notranslate')
    base.setAttribute('translate', 'no')
    select.appendChild(base)

    LANGS.forEach((lang) => {
      const option = document.createElement('option')
      option.value = lang.code
      option.textContent = lang.label
      option.classList.add('notranslate')
      option.setAttribute('translate', 'no')
      select.appendChild(option)
    })

    select.addEventListener('change', () => {
      const lang = select.value
      localStorage.setItem('aqa_lang', lang)
      applyLanguage(lang)
      document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr'
    })

    host.appendChild(select)
    if (mountHost) {
      mountHost.appendChild(host)
    } else {
      document.body.appendChild(host)
    }
  }

  window.googleTranslateElementInit = function () {
    new window.google.translate.TranslateElement(
      {
        pageLanguage: 'es',
        includedLanguages: 'en,ar,pt,zh-CN,fr',
        autoDisplay: false,
      },
      'google_translate_element'
    )

    const saved = localStorage.getItem('aqa_lang') || 'es'
    const uiSelect = document.getElementById('aqa-lang-select')
    if (uiSelect) uiSelect.value = saved
    document.documentElement.dir = saved === 'ar' ? 'rtl' : 'ltr'

    if (saved === 'es') return

    let tries = 0
    const timer = setInterval(() => {
      tries += 1
      if (applyLanguage(saved) || tries > 40) clearInterval(timer)
    }, 120)
  }

  function loadTranslateScript() {
    if (document.getElementById('aqa-google-translate-script')) return
    const script = document.createElement('script')
    script.id = 'aqa-google-translate-script'
    script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit'
    script.async = true
    document.body.appendChild(script)
  }

  function scheduleTranslateLoad() {
    const delayMs = 550
    const run = () => loadTranslateScript()
    if (document.readyState === 'complete') {
      setTimeout(run, delayMs)
    } else {
      window.addEventListener('load', () => setTimeout(run, delayMs), { once: true })
    }
  }

  function init() {
    injectStyles()
    const hidden = document.createElement('div')
    hidden.id = 'google_translate_element'
    document.body.appendChild(hidden)
    createSwitcher()

    scheduleTranslateLoad()
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init)
  } else {
    init()
  }
})()
