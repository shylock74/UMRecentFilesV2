# WalkThrough - `UMRecentFilesV2`

Questo documento illustra la struttura, le decisioni architetturali e la guida passo-passo alla migrazione verso `UMRecentFilesV2`.

---

## 🏛 Architettura dei Componenti

Il package è strutturato in modo modulare senza dipendere dal monolite `UMOmniaFramework`, avvalendosi unicamente di `UMUIControls` e dei framework Apple macOS:

### 1. `Core/`
- **`UMRecentFile`**: Modello `Codable`, `Identifiable`, `Hashable` e `Sendable`. Decodifica in modo *fault-tolerant* anche vecchi dati JSON di `UMRecentFiles` salvati in precedenti versioni dell'app.
- **`UMRecentFiles`**: Il manager principale (`ObservableObject`). Supporta modalità ibrida (`UserDefaults` + `NSDocumentController.shared`), conteggio massimo configurabile (`maxCount`), pin/preferiti, filtri e ordinamento.
- **`UMRecentThumbnailLoader`**: Caricatore asincrono di anteprime basato su `QLThumbnailGenerator` con `NSCache` e fallback ad alta fedeltà sull'icona di sistema del file.
- **`UMRecentFileHelpers`**: Funzioni di supporto pure per formattazione dimensioni byte, date relative/compatte, verifica esistenza disco, Security-Scoped Bookmarks e reveal nel Finder.

### 2. `Views/`
- **`UMRecentFilesView`**: Container collassabile SwiftUI con animazione spring, persistenza dello stato aperto/chiuso con `@AppStorage`, conteggio file, supporto drag-and-drop e stati vuoti con `UMUIEmptyStateView`.
- **`UMRecentFilesHeaderView`**: Header con titolo, icona, badge conteggio, pulsante switch lista/griglia e menu di ordinamento a tendina.
- **`UMRecentFilesFilterBar`**: Barra di ricerca integrata con `UMUITextField` e pillole filtraggio per estensione.
- **`UMRecentFileRowView`**: Riga per la modalità elenco con icona/anteprima QuickLook, indicatore Pin, percorso abbreviato, data, dimensione, pulsanti di azione rapida su hover (Pin, Finder, Rimuovi) e context menu completo.
- **`UMRecentFileCardView`**: Card compatta per la modalità griglia con anteprima grafica superiore e metadati.
- **`UMOpenRecentPanelView`**: Sostituto in puro SwiftUI di `UMOpenRecentVC` (layout a due colonne stile Welcome Screen con branding app e browser file recenti).
- **`UMRecentFilesMenu`**: Componente menu nativo SwiftUI e bridging con `NSMenuItem` per la barra dei menu di sistema.

---

## 🔄 Guida alla Migrazione da Versioni Precedenti

### Da `UMOmniaFramework` / `UMFoundation` (`UMRecentFiles`):
1. Rimuovi `import UMOmniaFramework` o `import UMFoundation` riferiti a `UMRecentFiles`.
2. Aggiungi `import UMRecentFilesV2`.
3. Le chiamate esistenti come `UMRecentFiles.shared.addFile(...)` e `UMRecentFiles.fillRecentFilesMenu(...)` continuano a funzionare senza alcuna modifica di codice.

### Da `UMOmniaFramework` (`UMOpenRecentVC`):
1. Invece di istanziare o chiamare lo storyboard di `UMOpenRecentVC`, usa:
   ```swift
   UMOpenRecent.showWindow(
       image: NSImage(named: "AppLogo"),
       createNewCallback: { ... },
       selectedFileCallback: { url in ... }
   )
   ```
2. La firma è retrocompatibile anche tramite l'alias `UMOpenRecentVC.showWindow(...)`.

### Da `UMSwiftUI` (`UMRecentFilesView`):
1. Sostituisci `import UMSwiftUI` con `import UMRecentFilesV2`.
2. La vista mantiene l'initializer identico:
   ```swift
   UMRecentFilesView(filterExtensions: ["mov", "mp4"]) { url in
       // file aperto
   }
   ```
   ma ora beneficia automaticamente del restyling con `UMUIControls`, delle miniature QuickLook, del toggle lista/griglia e dei filtri.

