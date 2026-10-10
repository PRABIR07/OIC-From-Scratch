# OIC from Scratch ✍️

**Learn Oracle Integration Cloud (OIC) from zero**: step-by-step, hand-written style notes with diagrams, made for complete beginners.

by **@devwithprabir**

🌐 **Website:** https://prabir07.github.io/OIC-From-Scratch/
📖 **All notes:** https://prabir07.github.io/OIC-From-Scratch/notes/

---

## Phases

| # | Phase | What you'll learn | Notes |
|---|-------|-------------------|-------|
| 1 | **How Systems Talk** | Client & server, DNS, URLs, ports, HTTP methods, status codes, headers & body, HTTPS | [Read](https://prabir07.github.io/OIC-From-Scratch/notes/phase-01-how-systems-talk/) |
| 2 | Data Formats | JSON, XML, XSD, XPath, XSLT | Coming soon |
| 3 | APIs | REST, SOAP, authentication, Postman | Coming soon |
| 4 | SQL & Databases | Queries, joins, PL/SQL basics | Coming soon |
| 5 | Integration Concepts | Sync vs async, events, files, patterns | Coming soon |
| 6 | OIC Basics | Connections, adapters, mapper, monitoring | Coming soon |
| 7 | OIC Intermediate | Loops, fault handling, stage file, lookups | Coming soon |
| 8 | Oracle Fusion Applications | BIP reports, FBDI, HDL, business events | Coming soon |
| 9 | Advanced & Related Tools | VBCS, Process Automation, OCI basics | Coming soon |
| 10 | Certification & Job Prep | Exam prep, portfolio projects, interviews | Coming soon |

## How to use the notes

- **Read online:** open the website on your laptop or phone.
- **Save as PDF:** open a note in Chrome → `Cmd/Ctrl + P` → *Save as PDF* → under *More settings* turn on **Background graphics**. All quiz answers are included in the PDF.
- **Track progress:** tick the *Got it* box at the end of each chapter. Ticks are saved in your own browser.

## How the site works

```
OIC-From-Scratch/
├── index.html                  ← Home page (hero, latest notes, roadmap, about)
├── notes.json                  ← THE LIST: every note + roadmap + your social links
├── notes/
│   ├── index.html              ← Notes page (search + filter by phase)
│   └── phase-01-how-systems-talk/
│       └── index.html          ← Phase 1 notes
├── assets/
│   ├── style.css               ← shared notebook design
│   └── site.js                 ← builds the note cards from notes.json
└── README.md
```

The Home and Notes pages read `notes.json`, so **publishing a note never means editing the pages themselves.**

### Publishing a new note

1. Add a folder `notes/<slug>/` containing the note as `index.html`
   (for example `notes/phase-02-data-formats/index.html`).
2. Add one entry to the `notes` list in `notes.json`:

   ```json
   {
     "slug": "phase-02-data-formats",
     "phase": 2,
     "title": "Data Formats",
     "summary": "One or two sentences about what the note covers.",
     "topics": ["JSON", "XML", "XSD", "XPath", "XSLT"],
     "date": "2026-10-20",
     "readMinutes": 25,
     "video": "",
     "status": "published"
   }
   ```

3. Commit. Within a minute or two the note appears on the Notes page, as a **Latest note** on the Home page (with a *New* badge for 14 days), and the roadmap marks that phase as ready.

Use `"status": "draft"` to upload a note without showing it yet.

### Adding your social links

Fill in `site.links` in `notes.json` (`youtube`, `linkedin`, `instagram`, `github`). Empty links stay hidden.

---

If these notes helped you, ⭐ star the repo and share it with a friend who is starting with OIC.
