;(function () {
  var LANGS = [
    { code: 'es', label: 'ES' },
    { code: 'en', label: 'EN' },
    { code: 'fr', label: 'FR' },
    { code: 'pt', label: 'PT' },
    { code: 'it', label: 'IT' },
    { code: 'ar', label: 'AR' },
  ]

  function createContainer() {
    if (document.getElementById('aqa-lang-switcher')) return

    var style = document.createElement('style')
    style.textContent =
      '#aqa-lang-switcher{background:#fff;border:1px solid rgba(0,0,0,.15);border-radius:9999px;padding:6px 10px;display:inline-flex;align-items:center;gap:8px;font-family:Montserrat,system-ui,sans-serif;margin-left:8px}#aqa-lang-switcher label{font-size:12px;color:#111827;font-weight:600}#aqa-lang-select{border:none;background:transparent;color:#111827;font-size:12px;font-weight:700;outline:none;cursor:pointer}@media (max-width:640px){#aqa-lang-switcher{padding:5px 8px}#aqa-lang-switcher label{display:none}}'
    document.head.appendChild(style)

    var wrap = document.createElement('div')
    wrap.id = 'aqa-lang-switcher'
    wrap.setAttribute('translate', 'no')
    wrap.className = 'notranslate'

    var label = document.createElement('label')
    label.setAttribute('for', 'aqa-lang-select')
    label.textContent = 'Idioma'

    var select = document.createElement('select')
    select.id = 'aqa-lang-select'
    LANGS.forEach(function (lang) {
      var option = document.createElement('option')
      option.value = lang.code
      option.textContent = lang.label
      select.appendChild(option)
    })

    select.addEventListener('change', function () {
      setLanguage(select.value)
    })

    wrap.appendChild(label)
    wrap.appendChild(select)

    var headerActions =
      document.querySelector('header .mx-auto > div:last-child') ||
      document.querySelector('header .mx-auto .flex.items-center.gap-2') ||
      document.querySelector('header .mx-auto')

    if (headerActions) {
      headerActions.appendChild(wrap)
    } else {
      document.body.appendChild(wrap)
    }
  }

  function suppressGoogleUI() {
    var googleUiStyle = document.createElement('style')
    googleUiStyle.textContent =
      '.goog-te-banner-frame.skiptranslate,.goog-te-balloon-frame,.VIpgJd-ZVi9od-ORHb-OEVmcd,.VIpgJd-ZVi9od-l4eHX-hSRGPd{display:none !important;}body{top:0 !important;}.goog-logo-link,.goog-te-gadget span,.goog-te-gadget-simple img,.goog-te-gadget-icon{display:none !important;}#google_translate_element{display:none !important;}'
    document.head.appendChild(googleUiStyle)

    var normalizeBody = function () {
      if (document.body) {
        document.body.style.top = '0px'
      }
      var banner = document.querySelector('.goog-te-banner-frame.skiptranslate')
      if (banner) banner.style.display = 'none'
      var balloon = document.querySelector('.goog-te-balloon-frame')
      if (balloon) balloon.style.display = 'none'
      var newBanner = document.querySelector('.VIpgJd-ZVi9od-ORHb-OEVmcd')
      if (newBanner) newBanner.style.display = 'none'
    }

    normalizeBody()
    setInterval(normalizeBody, 600)
  }

  function setCookie(lang) {
    var value = lang === 'es' ? '/es/es' : '/auto/' + lang
    document.cookie = 'googtrans=' + value + ';path=/'
    document.cookie = 'googtrans=' + value + ';path=/;domain=' + window.location.hostname
  }

  function applyGoogleLanguage(lang) {
    var combo = document.querySelector('select.goog-te-combo')
    if (!combo) return false
    var hasOption = combo.querySelector('option[value="' + lang + '"]')
    if (hasOption) {
      combo.value = lang
    } else if (lang === 'es') {
      combo.selectedIndex = 0
    } else {
      return false
    }
    combo.dispatchEvent(new Event('change'))
    return true
  }

  function setLanguage(lang) {
    var selected = lang || 'es'
    localStorage.setItem('aqa-lang', selected)

    if (selected === 'es') {
      document.cookie = 'googtrans=;path=/;expires=Thu, 01 Jan 1970 00:00:00 GMT'
      document.cookie =
        'googtrans=;path=/;domain=' +
        window.location.hostname +
        ';expires=Thu, 01 Jan 1970 00:00:00 GMT'
      // Ensure visitors return to original Spanish immediately.
      window.location.reload()
      return
    }

    setCookie(selected)
    if (!applyGoogleLanguage(selected)) {
      window.location.reload()
    }
  }

  function initialLanguage() {
    return localStorage.getItem('aqa-lang') || 'es'
  }

  window.googleTranslateElementInit = function () {
    var hidden = document.createElement('div')
    hidden.id = 'google_translate_element'
    hidden.style.display = 'none'
    document.body.appendChild(hidden)

    new window.google.translate.TranslateElement(
      {
        pageLanguage: 'es',
        includedLanguages: 'en,fr,pt,it,ar',
        autoDisplay: false,
      },
      'google_translate_element'
    )

    var lang = initialLanguage()
    var uiSelect = document.getElementById('aqa-lang-select')
    if (uiSelect) uiSelect.value = lang
    setCookie(lang)

    var tries = 0
    var timer = setInterval(function () {
      tries += 1
      if (applyGoogleLanguage(lang) || tries > 30) {
        clearInterval(timer)
      }
    }, 200)
  }

  function init() {
    createContainer()
    suppressGoogleUI()
    var script = document.createElement('script')
    script.src =
      'https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit'
    script.async = true
    document.body.appendChild(script)
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init)
  } else {
    init()
  }
})()
