// OIC from Scratch · renders the notes lists from notes.json
(function () {
  var root = document.body.getAttribute('data-root') || './';

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function fmtDate(iso) {
    var d = new Date(iso + 'T00:00:00');
    if (isNaN(d)) return '';
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  function isNew(iso) {
    var d = new Date(iso + 'T00:00:00');
    return !isNaN(d) && (Date.now() - d.getTime()) < 14 * 864e5;
  }
  function card(n) {
    var href = root + 'notes/' + encodeURIComponent(n.slug) + '/index.html';
    var chips = (n.topics || []).map(function (t) { return '<li>' + esc(t) + '</li>'; }).join('');
    var meta = [fmtDate(n.date), n.readMinutes ? n.readMinutes + ' min read' : '', n.video ? 'video available' : '']
      .filter(Boolean).join(' · ');
    return '<li><a class="note-card" href="' + href + '">' +
      '<span class="tape" aria-hidden="true"></span>' +
      '<span class="top"><span class="pn" aria-label="Phase ' + esc(n.phase) + '">' + esc(n.phase) + '</span>' +
      '<span><span class="meta">Phase ' + esc(n.phase) + (isNew(n.date) ? ' · <span class="new">New</span>' : '') + '</span>' +
      '<h3>' + esc(n.title) + '</h3></span></span>' +
      '<p>' + esc(n.summary) + '</p>' +
      '<ul class="chips">' + chips + '</ul>' +
      '<span class="meta">' + esc(meta) + '</span>' +
      '<span class="go">Read notes →</span></a></li>';
  }
  function published(data) {
    return (data.notes || []).filter(function (n) { return n.status === 'published'; })
      .sort(function (a, b) { return (b.date || '').localeCompare(a.date || '') || b.phase - a.phase; });
  }

  function renderLatest(data) {
    var el = document.getElementById('latest');
    if (!el) return;
    var list = published(data).slice(0, 3);
    el.innerHTML = list.length ? list.map(card).join('')
      : '<li class="empty">The first notes are on their way.</li>';
    var first = published(data).sort(function (a, b) { return a.phase - b.phase; })[0];
    var start = document.getElementById('start-reading');
    if (start && first) start.href = root + 'notes/' + encodeURIComponent(first.slug) + '/index.html';
  }

  function renderRoadmap(data) {
    var el = document.getElementById('roadmap');
    if (!el) return;
    var byPhase = {};
    published(data).forEach(function (n) { if (!byPhase[n.phase]) byPhase[n.phase] = n; });
    var road = data.roadmap || [];
    var ready = road.filter(function (r) { return byPhase[r.phase]; });
    var here = ready.length ? ready[ready.length - 1].phase : null;
    var nextUp = road.filter(function (r) { return !byPhase[r.phase]; })[0];
    var lastStage = '';

    el.innerHTML = road.map(function (r, i) {
      var n = byPhase[r.phase];
      var stage = '';
      if (r.stage && r.stage !== lastStage) { lastStage = r.stage; stage = '<li class="stage"><span>' + esc(r.stage) + '</span></li>'; }
      var cls = n ? 'done' : (nextUp && nextUp.phase === r.phase ? 'next' : '');
      var badge = n ? '<span class="state ok">Ready</span>' : (cls === 'next' ? '<span class="state nx">Up next</span>' : '<span class="state">Coming soon</span>');
      var items = (r.list || []).map(function (t) { return '<li>' + esc(t) + '</li>'; }).join('');
      var link = n ? '<a class="btn small" href="' + root + 'notes/' + encodeURIComponent(n.slug) + '/index.html">Read the notes →</a>' : '';
      return stage + '<li class="stop ' + cls + (i % 2 ? ' right' : ' left') + '">' +
        '<span class="pn" aria-hidden="true">' + esc(r.phase) + '</span>' +
        (r.phase === here ? '<span class="here" aria-hidden="true">You are here</span>' : '') +
        '<details' + (n ? ' open' : '') + '><summary>' +
          '<span class="ttl"><span class="sr">Phase ' + esc(r.phase) + ': </span>' + esc(r.title) + '</span>' +
          '<span class="row">' + (r.weeks ? '<span class="wk">⏱ ' + esc(r.weeks) + '</span>' : '') + badge + '</span>' +
          '<span class="sub">' + esc(r.topics) + '</span>' +
        '</summary>' + (items ? '<ul class="topics">' + items + '</ul>' : '') + link + '</details></li>';
    }).join('');

    var bar = document.getElementById('road-progress');
    if (bar) {
      var pct = road.length ? Math.round(ready.length / road.length * 100) : 0;
      bar.innerHTML = '<span class="lbl"><b>' + ready.length + ' of ' + road.length + '</b> phases ready' +
        (nextUp ? ' · next up: <b>' + esc(nextUp.title) + '</b>' : '') + '</span>' +
        '<span class="track" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="' + pct + '" aria-label="Phases ready">' +
        '<span class="fill" style="width:' + Math.max(pct, 3) + '%"></span></span>';
    }
  }

  function renderAll(data) {
    var el = document.getElementById('all-notes');
    if (!el) return;
    var search = document.getElementById('q');
    var filters = document.getElementById('filters');
    var count = document.getElementById('count');
    var all = published(data).sort(function (a, b) { return a.phase - b.phase; });
    var phase = 'all';

    var phases = [];
    all.forEach(function (n) { if (phases.indexOf(n.phase) < 0) phases.push(n.phase); });
    filters.innerHTML = '<button type="button" data-phase="all" aria-pressed="true">All</button>' +
      phases.map(function (p) { return '<button type="button" data-phase="' + p + '" aria-pressed="false">Phase ' + p + '</button>'; }).join('');

    function draw() {
      var q = (search.value || '').trim().toLowerCase();
      var list = all.filter(function (n) {
        if (phase !== 'all' && String(n.phase) !== phase) return false;
        if (!q) return true;
        return [n.title, n.summary, (n.topics || []).join(' '), 'phase ' + n.phase].join(' ').toLowerCase().indexOf(q) >= 0;
      });
      el.innerHTML = list.length ? list.map(card).join('')
        : '<li class="empty">No notes match “' + esc(search.value) + '”. Try a topic like DNS or status codes.</li>';
      count.textContent = list.length + (list.length === 1 ? ' note' : ' notes');
    }
    filters.addEventListener('click', function (e) {
      var b = e.target.closest('button');
      if (!b) return;
      phase = b.getAttribute('data-phase');
      filters.querySelectorAll('button').forEach(function (x) { x.setAttribute('aria-pressed', x === b ? 'true' : 'false'); });
      draw();
    });
    search.addEventListener('input', draw);
    draw();
  }

  function renderLinks(data) {
    var links = (data.site && data.site.links) || {};
    document.querySelectorAll('[data-link]').forEach(function (a) {
      var url = links[a.getAttribute('data-link')];
      if (url) { a.href = url; a.hidden = false; } else { a.hidden = true; }
    });
  }

  fetch(root + 'notes.json', { cache: 'no-cache' })
    .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (data) { renderLatest(data); renderRoadmap(data); renderAll(data); renderLinks(data); })
    .catch(function () {
      ['latest', 'all-notes', 'roadmap'].forEach(function (id) {
        var el = document.getElementById(id);
        if (el) el.innerHTML = '<li class="empty">Couldn’t load the notes list. Refresh the page to try again.</li>';
      });
    });
})();
