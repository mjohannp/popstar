# Pop Star

Nachbau des Klassikers **PopStar!** – als Web-SPA (`index.html`, kein Build,
keine Abhängigkeiten) und als native iOS-App in SwiftUI (`ios/`).

## Web starten

```bash
open index.html          # macOS
# oder
python3 -m http.server   # dann http://localhost:8000
```

## iOS-App

```bash
cd ios
xcodegen generate        # nur nötig, wenn sich Dateien/Struktur ändern
open PopStar.xcodeproj   # in Xcode: Scheme „PopStar", Zielgerät wählen, Run
```

- **SwiftUI ab iOS 17**, MVVM: `GameEngine` (`@Observable`) enthält die komplette
  Spiellogik ohne UI, die Views sind rein deklarativ
- Sounds werden zur Laufzeit per `AVAudioEngine` synthetisiert, Haptik über
  `UIFeedbackGenerator` – keine Audio-Dateien
- Rekord in `UserDefaults`
- Unit-Tests der Spiellogik: `xcodebuild test -scheme PopStar` (Punkteformel,
  Gruppensuche, Schwerkraft/Spalten, Bonus, Stage-Ende)
- Für das eigene iPhone: in Xcode unter *Signing & Capabilities* das eigene
  Team auswählen – das Projekt ist für automatisches Signing vorbereitet

## Auf dem Handy spielen (GitHub Pages)

1. Auf GitHub ein **öffentliches** Repository anlegen (z. B. `popstar`).
2. Alle Dateien aus diesem Ordner hochladen (`index.html`, `manifest.webmanifest`,
   `icons/`, `README.md`, `.gitignore`).
3. Im Repo: **Settings → Pages → Source: Deploy from a branch → `main` / `(root)` → Save**.
4. Nach ein bis zwei Minuten läuft das Spiel unter
   `https://<dein-name>.github.io/popstar/`.

Tipp: Auf dem Handy die Seite öffnen und **„Zum Home-Bildschirm"** wählen – dank
Web-Manifest startet das Spiel dann ohne Browser-Leiste im Vollbild.

## Spielregeln

- Das Feld besteht aus Sternen in fünf Farben (Web: 10×10, iOS-App: 8 Spalten
  × 12 Reihen – frei konfigurierbar über `GameEngine(rows:columns:)`).
- Tippe auf eine Gruppe aus **2 oder mehr** gleichfarbigen, waagerecht/senkrecht
  verbundenen Sternen – sie leuchten auf.
- Tippe erneut auf die Gruppe, um sie platzen zu lassen.
- Punkte: **5 × Blöcke²** (2 Blöcke = 20, 5 Blöcke = 125, 10 Blöcke = 500 …).
- Danach fallen die Steine nach unten und die Spalten rücken nach links.
- Sind keine Züge mehr möglich, endet die Stage. Bleiben höchstens 10 Blöcke
  übrig, gibt es einen Bonus von **2000 − 20 × Blöcke²**.
- Danach startet die nächste Stage – gespielt wird, bis du aufhörst.

## Web-Features

- Vollständig responsiv (Handy bis Desktop), Safe-Area-Support
- Weiche Fall-, Auswahl- und Platz-Animationen, Partikel, Punkte-Popups
- Soundeffekte per WebAudio (abschaltbar), kein externes Audio nötig
- Rekord wird lokal gespeichert (`localStorage`)
- Tastatur: `Esc` hebt die Auswahl auf

## Web-Aufbau

Alles steckt in `index.html`:

| Abschnitt | Inhalt |
| --- | --- |
| CSS | Layout, Kachel-Optik (Sterne per `clip-path`), Animationen |
| Spiellogik | `findGroup`, `collapse` (Schwerkraft + Spalten), `hasMoves`, `endStage` |
| Rendering | DOM-Kacheln mit `transform: translate3d`, CSS-Transitions |
| Audio | kleine Synth-Sounds über `OscillatorNode` |
