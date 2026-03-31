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
        position: fixed;
        right: 18px;
        top: 82px;
        z-index: 9999;
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 9px 12px;
        border: 1px solid rgba(225, 29, 72, 0.2);
        border-radius: 14px;
        background: rgba(255, 255, 255, 0.98);
        box-shadow: 0 10px 24px rgba(17, 24, 39, 0.14);
        backdrop-filter: blur(8px);
        font-family: Montserrat, sans-serif;
        color: #111827;
      }
      #aqa-lang-switcher .aqa-lang-label {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.02em;
      }
      #aqa-lang-switcher .aqa-lang-label::before {
        content: "🌐";
        font-size: 13px;
      }
      #aqa-lang-switcher select {
        border: 1px solid rgba(0, 0, 0, 0.2);
        border-radius: 10px;
        padding: 6px 30px 6px 10px;
        font-size: 12px;
        font-weight: 600;
        background: #fff;
        color: #111827;
        outline: none;
        cursor: pointer;
      }
      #aqa-lang-switcher select:focus {
        border-color: rgba(225, 29, 72, 0.55);
        box-shadow: 0 0 0 3px rgba(225, 29, 72, 0.15);
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
        #aqa-lang-switcher {
          right: 10px;
          top: auto;
          bottom: 84px;
          padding: 8px 10px;
          gap: 8px;
        }
        #aqa-lang-switcher .aqa-lang-label {
          font-size: 11px;
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
    const host = document.createElement('div')
    host.id = 'aqa-lang-switcher'
    host.classList.add('notranslate')
    host.setAttribute('translate', 'no')

    const label = document.createElement('span')
    label.className = 'aqa-lang-label'
    label.textContent = 'Language'
    label.classList.add('notranslate')
    label.setAttribute('translate', 'no')

    const select = document.createElement('select')
    select.id = 'aqa-lang-select'
    select.classList.add('notranslate')
    select.setAttribute('translate', 'no')

    const base = document.createElement('option')
    base.value = 'es'
    base.textContent = 'Spanish'
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

    host.appendChild(label)
    host.appendChild(select)
    document.body.appendChild(host)
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

    let tries = 0
    const timer = setInterval(() => {
      tries += 1
      if (applyLanguage(saved) || tries > 20) clearInterval(timer)
    }, 250)
    document.documentElement.dir = saved === 'ar' ? 'rtl' : 'ltr'
  }

  function init() {
    injectStyles()
    const hidden = document.createElement('div')
    hidden.id = 'google_translate_element'
    document.body.appendChild(hidden)
    createSwitcher()

    const script = document.createElement('script')
    script.src = 'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit'
    script.async = true
    document.body.appendChild(script)
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init)
  } else {
    init()
  }
})()
