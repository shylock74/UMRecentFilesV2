# UMRecentFilesV2

Un package Swift moderno per macOS (12.0+) dedicato alla gestione e visualizzazione evoluta dei file recenti, progettato come successore diretto di `UMRecentFiles` (da `UMOmniaFramework` / `UMFoundation`) e di `UMRecentFilesView` (da `UMSwiftUI`).

## ✨ Caratteristiche Principali

- **Design System con `UMUIControls`**: Interfaccia integrata nativamente con `UMUITheme` (supporto scuro/chiaro, token di colore e spaziatura), `UMUITextField` e `UMUIEmptyStateView`.
- **Anteprime QuickLook Asincrone**: Generazione automatica in background delle miniature reali dei file (`QLThumbnailGenerator`) con cache in memoria `NSCache` e fallback alle icone di sistema.
- **Doppio Layout (Lista e Griglia)**: L'utente o lo sviluppatore può alternare tra una lista ricca (con percorsi abbreviati, dimensioni e date) e una griglia a card visive.
- **Pin / Preferiti**: Possibilità di fissare file in cima alla lista (sia via hover button, sia da context menu).
- **Azioni Rapide su Hover & Menu Contestuale Completo**:
  - Apri / Esegui
  - Fissa/Sblocca in cima (*Pin*)
  - Mostra nel Finder (*Show in Finder*)
  - Copia percorso o nome file
  - Rimuovi dai recenti / Svuota menu
- **Filtri Rapidi & Ricerca**: Ricerca case-insensitive e pillole orizzontali per filtrare istantaneamente per estensione (`.mp4`, `.wav`, `.pdf`, ecc.).
- **Drag & Drop Bidirezionale**: Trascina un file fuori dalla lista per usarlo in altre app o trascina file dentro per aprirli/registrarli.
- **Finestra Welcome / "Open Recent" Dedicata**: Sostituisce il vecchio storyboard `UMOpenRecentWindow.storyboard` con `UMOpenRecentPanelView` e l'API statica `UMOpenRecent.showWindow(...)` (o l'alias `UMOpenRecentVC.showWindow(...)`).
- **Supporto Menu AppKit & SwiftUI**: Metodo `fillRecentFilesMenu(menu:selectedFileCallback:)` su `NSMenuItem` e componente SwiftUI `UMRecentFilesMenu`.
- **Architettura Ibrida**: Sincronizzazione automatica tra `UserDefaults` (JSON) e i documenti di sistema di macOS (`NSDocumentController.shared`).

---

## 📦 Installazione (Swift Package Manager)

Aggiungi `UMRecentFilesV2` al tuo file `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/shylock74/UMRecentFilesV2.git", branch: "main")
]
```

E aggiungilo come dipendenza del target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "UMRecentFilesV2", package: "UMRecentFilesV2")
    ]
)
```

---

## 🚀 Utilizzo Rapido

### 1. Vista SwiftUI Collassabile (Drop-in Replacement per la Sidebar o Inspector)

```swift
import SwiftUI
import UMRecentFilesV2

struct ContentView: View {
    var body: some View {
        VStack {
            UMRecentFilesView(filterExtensions: ["mp4", "mov", "wav"]) { selectedURL in
                print("File selezionato: \(selectedURL.path)")
            }
            Spacer()
        }
        .padding()
    }
}
```

### 2. Finestra "Open Recent" (Welcome Modal / Panel)

```swift
import UMRecentFilesV2

// Mostra la finestra moderna in stile Xcode / BeatMark
UMOpenRecent.showWindow(
    image: NSImage(named: "AppLogo"),
    removeExtension: true,
    createNewCallback: {
        print("Crea nuovo progetto...")
    },
    selectedFileCallback: { url in
        print("Apertura: \(url)")
    }
)
```

### 3. Gestione Dati e Menu AppKit (`NSMenuItem`)

```swift
import UMRecentFilesV2

// Registra un nuovo file recente
UMRecentFiles.addFile(url: projectURL)

// Popola il sottomenu "Open Recent" nell'NSMenu
@IBOutlet weak var recentFilesMenuItem: NSMenuItem!

func setupMenu() {
    UMRecentFiles.fillRecentFilesMenu(menu: recentFilesMenuItem) { url in
        self.openDocument(at: url)
    }
}
```

---

## 🛠 Requisiti di Sistema
- **macOS**: 12.0 o successivo
- **Swift**: 5.9 o successivo
- **Xcode**: 15.0 o successivo

---

## 📄 Licenza
Copyright © 2026 Ulti.Media. All rights reserved.
