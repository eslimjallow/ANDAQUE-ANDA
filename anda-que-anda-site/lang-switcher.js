;(function () {
  const LANGS = [
    { code: 'en', label: 'English' },
    { code: 'ar', label: 'العربية' },
    { code: 'pt', label: 'Português' },
    { code: 'zh-CN', label: '中文' },
    { code: 'fr', label: 'Français' },
  ]

  const PAGE_LANG = 'es'

  function canUseTranslateCookie() {
    return location.protocol === 'http:' || location.protocol === 'https:'
  }

  function rootCookieDomain() {
    const h = location.hostname
    if (!h || h === 'localhost') return ''
    if (/^\d+\.\d+\.\d+\.\d+$/.test(h)) return ''
    const parts = h.split('.')
    if (parts.length < 2) return ''
    return '.' + parts.slice(-2).join('.')
  }

  function getGoogtransRaw() {
    const m = document.cookie.match(/(?:^|;\s*)googtrans=([^;]*)/)
    if (!m) return ''
    try {
      return decodeURIComponent(m[1].trim())
    } catch {
      return m[1].trim()
    }
  }

  function hasActiveGoogtrans() {
    const v = getGoogtransRaw()
    if (!v) return false
    const parts = v.split('/').filter(Boolean)
    return parts.length >= 2 && parts[0] !== parts[1]
  }

  function targetLangFromGoogtrans() {
    const v = getGoogtransRaw()
    if (!v) return null
    const parts = v.split('/').filter(Boolean)
    if (parts.length < 2) return null
    return parts[parts.length - 1] || null
  }

  function mapCookieTargetToSelectValue(target) {
    if (!target) return null
    if (target === PAGE_LANG) return 'es'
    const exact = LANGS.find((l) => l.code === target)
    if (exact) return exact.code
    const lc = target.toLowerCase()
    if (lc === 'zh-cn' || lc === 'zh_cn' || lc === 'zh') return 'zh-CN'
    const fuzzy = LANGS.find((l) => l.code.toLowerCase() === lc)
    return fuzzy ? fuzzy.code : null
  }

  function setGoogtransCookie(from, to) {
    const value = '/' + from + '/' + to
    const maxAge = 60 * 60 * 24 * 400
    const chunk = 'googtrans=' + encodeURIComponent(value) + ';path=/;SameSite=Lax;max-age=' + maxAge
    document.cookie = chunk
    const root = rootCookieDomain()
    if (root) document.cookie = chunk + ';domain=' + root
  }

  function clearGoogtransCookies() {
    const expired = 'Thu, 01 Jan 1970 00:00:01 GMT'
    const pairs = [
      'googtrans=;path=/;expires=' + expired,
      'googtrans=;path=/;expires=' + expired + ';domain=' + location.hostname,
    ]
    const root = rootCookieDomain()
    if (root) pairs.push('googtrans=;path=/;expires=' + expired + ';domain=' + root)
    pairs.forEach((c) => {
      document.cookie = c
    })
  }

  /** If localStorage asks for translation but cookie missing, set cookie and reload once. */
  function syncCookieWithSavedLang() {
    if (!canUseTranslateCookie()) return false
    const saved = localStorage.getItem('aqa_lang') || 'es'
    if (saved === 'es') return false
    if (hasActiveGoogtrans()) return false
    setGoogtransCookie(PAGE_LANG, saved)
    location.reload()
    return true
  }

  function injectStyles() {
    const style = document.createElement('style')
    style.id = 'aqa-lang-switcher-styles'
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
        max-width: 10.5rem;
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
      .goog-te-banner-frame,
      iframe.goog-te-banner-frame,
      .goog-te-banner-frame.skiptranslate,
      iframe.goog-te-menu-frame,
      .goog-te-menu-frame,
      .goog-logo-link,
      .goog-te-gadget-icon,
      #goog-gt-tt,
      .goog-te-balloon-frame,
      .goog-tooltip,
      div[id^='goog-gt-'],
      .goog-te-ftab {
        display: none !important;
        visibility: hidden !important;
        height: 0 !important;
        max-height: 0 !important;
        width: 0 !important;
        overflow: hidden !important;
        pointer-events: none !important;
        opacity: 0 !important;
        border: 0 !important;
        clip: rect(0,0,0,0) !important;
        position: fixed !important;
        top: -9999px !important;
        left: -9999px !important;
      }
      html {
        margin-top: 0 !important;
        padding-top: 0 !important;
      }
      body {
        top: 0 !important;
        margin-top: 0 !important;
        padding-top: 0 !important;
        position: static !important;
      }
      #google_translate_element {
        position: fixed !important;
        left: 0 !important;
        bottom: 0 !important;
        width: 220px !important;
        height: 40px !important;
        opacity: 0.02 !important;
        pointer-events: none !important;
        z-index: 2147483000 !important;
        overflow: visible !important;
      }
      #google_translate_element .goog-te-gadget > span {
        display: none !important;
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

  function markChromeNotTranslatable() {
    document.querySelectorAll('a[href*="wa.me"]').forEach((el) => {
      el.classList.add('notranslate')
      el.setAttribute('translate', 'no')
    })
  }

  function stripGoogleBannerOnly() {
    document.querySelectorAll('iframe.goog-te-banner-frame, iframe.goog-te-menu-frame').forEach((el) => {
      try {
        el.remove()
      } catch (e) {}
    })
    document.querySelectorAll('div.goog-te-banner-frame, div.goog-te-menu-frame').forEach((el) => {
      try {
        el.remove()
      } catch (e) {}
    })
  }

  function resetTranslateLayoutShift() {
    if (document.body) {
      document.body.style.setProperty('top', '0', 'important')
      document.body.style.setProperty('margin-top', '0', 'important')
      document.body.style.setProperty('padding-top', '0', 'important')
    }
    if (document.documentElement) {
      document.documentElement.style.setProperty('margin-top', '0', 'important')
      document.documentElement.style.setProperty('padding-top', '0', 'important')
    }
  }

  function suppressGoogleTranslateBanner() {
    const apply = () => {
      stripGoogleBannerOnly()
      resetTranslateLayoutShift()
    }
    apply()
    if (window.__aqaGtBannerObserver) return
    let debounce = null
    const schedule = () => {
      if (debounce != null) clearTimeout(debounce)
      debounce = setTimeout(() => {
        debounce = null
        apply()
      }, 120)
    }
    const mo = new MutationObserver(() => schedule())
    if (document.body) {
      mo.observe(document.body, { childList: true, subtree: false })
    }
    window.__aqaGtBannerObserver = mo
  }

  function getGoogSelect() {
    return document.querySelector('#google_translate_element .goog-te-combo') || document.querySelector('.goog-te-combo')
  }

  function fireSelectChange(googSelect) {
    try {
      const ev = document.createEvent('HTMLEvents')
      ev.initEvent('change', true, false)
      googSelect.dispatchEvent(ev)
    } catch (e) {
      googSelect.dispatchEvent(new Event('change', { bubbles: true }))
    }
    googSelect.dispatchEvent(new Event('input', { bubbles: true }))
  }

  function applyLanguage(langCode) {
    const googSelect = getGoogSelect()
    if (!googSelect) return false
    const opts = Array.from(googSelect.options)
    let internal = langCode === 'es' ? '' : langCode
    let opt = opts.find((o) => o.value === internal)
    if (!opt && langCode === 'es') {
      internal = 'es'
      opt = opts.find((o) => o.value === internal)
    }
    if (!opt && langCode !== 'es') {
      const lc = langCode.toLowerCase()
      opt = opts.find((o) => o.value.toLowerCase() === lc)
      if (!opt && langCode === 'zh-CN') {
        opt = opts.find((o) => /zh/i.test(o.value))
      }
      if (opt) internal = opt.value
    }
    if (!opt) return false
    try {
      const desc = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, 'value')
      if (desc && desc.set) desc.set.call(googSelect, internal)
      else googSelect.value = internal
    } catch (e) {
      googSelect.value = internal
    }
    fireSelectChange(googSelect)
    return true
  }

  function syncDocumentLang(langCode) {
    document.documentElement.lang = langCode === 'es' ? 'es' : langCode
    document.documentElement.dir = langCode === 'ar' ? 'rtl' : 'ltr'
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

    let saved = localStorage.getItem('aqa_lang') || 'es'
    const cookieUi = mapCookieTargetToSelectValue(targetLangFromGoogtrans())
    if (cookieUi) {
      saved = cookieUi
      localStorage.setItem('aqa_lang', saved)
    }
    select.value = saved
    syncDocumentLang(saved)

    select.addEventListener('change', () => {
      const lang = select.value
      localStorage.setItem('aqa_lang', lang)
      syncDocumentLang(lang)
      if (canUseTranslateCookie()) {
        if (lang === 'es') clearGoogtransCookies()
        else setGoogtransCookie(PAGE_LANG, lang)
        location.reload()
        return
      }
      applyLanguage(lang)
      stripGoogleBannerOnly()
      resetTranslateLayoutShift()
      requestAnimationFrame(() => {
        stripGoogleBannerOnly()
        resetTranslateLayoutShift()
      })
      ;[200, 600, 1500].forEach((ms) =>
        setTimeout(() => {
          stripGoogleBannerOnly()
          resetTranslateLayoutShift()
        }, ms)
      )
    })

    host.appendChild(select)
    if (mountHost) {
      mountHost.appendChild(host)
    } else {
      document.body.appendChild(host)
    }
  }

  window.googleTranslateElementInit = function () {
    const TE = window.google.translate.TranslateElement
    new TE(
      {
        pageLanguage: PAGE_LANG,
        includedLanguages: 'en,ar,pt,zh-CN,fr',
        autoDisplay: false,
      },
      'google_translate_element'
    )
    suppressGoogleTranslateBanner()

    let antiBarTicks = 0
    const antiBar = setInterval(() => {
      stripGoogleBannerOnly()
      resetTranslateLayoutShift()
      antiBarTicks += 1
      if (antiBarTicks > 45) clearInterval(antiBar)
    }, 150)

    const saved = localStorage.getItem('aqa_lang') || 'es'
    const uiSelect = document.getElementById('aqa-lang-select')
    if (uiSelect) uiSelect.value = saved
    syncDocumentLang(saved)

    if (canUseTranslateCookie()) return

    if (saved === 'es') return

    let tries = 0
    const timer = setInterval(() => {
      tries += 1
      if (applyLanguage(saved) || tries > 60) clearInterval(timer)
    }, 100)
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
    if (syncCookieWithSavedLang()) return
    injectStyles()
    markChromeNotTranslatable()
    suppressGoogleTranslateBanner()
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
