;(function () {
  /** @type {Array<{iso:string,title:string,dateLabel:string,time?:string,venue:string,address:string,mapQuery:string,note?:string}>} */
  window.AQA_EVENTS = [
    {
      iso: '2026-05-07T19:30:00+01:00',
      title: 'Las Caras del Amor',
      dateLabel: 'Jue, 7 May 2026',
      time: '19:30',
      venue: 'Bar Tenesor',
      address: 'Las Palmas de Gran Canaria',
      mapQuery: 'Bar+Tenesor,+Las+Palmas',
    },
    {
      iso: '2026-05-14T18:30:00+01:00',
      title: 'Las Caras del Amor',
      dateLabel: 'Jue, 14 May 2026',
      time: '18:30',
      venue: 'IES La Isleta',
      address: 'Calle Juan Rejón 58, Las Palmas',
      mapQuery: 'IES+La+Isleta,+Calle+Juan+Rej%C3%B3n+58,+Las+Palmas',
    },
    {
      iso: '2026-05-22T17:30:00+01:00',
      title: 'Las Caras del Amor',
      dateLabel: 'Jue, 22 May 2026',
      time: '17:30',
      venue: 'Hospital Insular',
      address: '5ª planta medular',
      mapQuery: 'Hospital+Insular,+Las+Palmas+de+Gran+Canaria',
    },
    {
      iso: '2026-05-26T17:30:00+01:00',
      title: 'La Librería de las Almas',
      dateLabel: 'Mar, 26 May 2026',
      time: '17:30',
      venue: 'Hospital Polivalente',
      address: 'Anexo Juan Carlos I',
      mapQuery: 'Hospital+Polivalente,+anexo+Juan+Carlos+I,+Las+Palmas',
    },
    {
      iso: '2026-05-28T18:30:00+01:00',
      title: 'Mi novio coreano',
      subtitle: 'Stand up solidaria con Ángela De Prisco',
      dateLabel: 'Jue, 28 May 2026',
      time: '18:30',
      venue: 'IES La Isleta',
      address: 'Calle Juan Rejón 58, Las Palmas',
      mapQuery: 'IES+La+Isleta,+Calle+Juan+Rej%C3%B3n+58,+Las+Palmas',
      note: 'Sin reserva · donativo agradecido',
    },
    {
      iso: '2026-06-03T18:30:00+01:00',
      title: 'Las Caras del Amor',
      dateLabel: 'Mié, 3 Jun 2026',
      time: '18:30',
      venue: 'IES La Isleta',
      address: 'Calle Juan Rejón 58, Las Palmas',
      mapQuery: 'IES+La+Isleta,+Calle+Juan+Rej%C3%B3n+58,+Las+Palmas',
      note: 'Sin reserva · donativo agradecido',
    },
    {
      iso: '2026-06-18T18:00:00+01:00',
      title: 'La Librería de las Almas',
      dateLabel: 'Jue, 18 Jun 2026',
      time: '18:00',
      venue: 'Centro Penitenciario Salto del Negro',
      address: 'Las Palmas',
      mapQuery: 'Centro+Penitenciario+Salto+del+Negro,+Las+Palmas',
    },
  ]

  window.AQA_eventMeta = function (evt) {
    var parts = [evt.dateLabel]
    if (evt.time) parts.push(evt.time)
    parts.push(evt.venue)
    if (evt.address && evt.address !== evt.venue) parts.push(evt.address.split(',')[0])
    return parts.join(' · ')
  }

  /** Past once the scheduled start time has passed. */
  window.AQA_isPastEvent = function (iso) {
    return new Date(iso).getTime() <= Date.now()
  }

  /** Upcoming first (chronological), then past (chronological). */
  window.AQA_eventsForAgenda = function () {
    var upcoming = []
    var past = []
    window.AQA_EVENTS.forEach(function (evt) {
      if (window.AQA_isPastEvent(evt.iso)) past.push(evt)
      else upcoming.push(evt)
    })
    return { upcoming: upcoming, past: past }
  }
})()
