# Task List - UMRecentFilesV2: Disk Search Feature

- [✅] Milestone 6: Rilevamento Tipi e Motore di Ricerca Asincrono su Disco
  - [✅] Implementazione UMAppDocumentTypes.swift (rilevamento automatico estensioni e UTType da Info.plist e fallback)
  - [✅] Implementazione UMFileSearchCoordinator.swift (motore ibrido NSMetadataQuery per Spotlight + DirectoryEnumerator ricorsivo, streaming debounced con batching, cancellazione e controllo stato)
  - [✅] Test di compilazione del Core di ricerca
- [✅] Milestone 7: Componenti Grafici per la Ricerca su Disco (SwiftUI & UMUIControls)
  - [✅] Implementazione UMDiskSearchControls.swift (pulsante di avvio, menu di selezione cartella, pillola di stato animata e pulsante Stop)
  - [✅] Integrazione in UMRecentFilesView.swift (sezione o tab "Discovered on Disk", streaming progressivo, gestione tap per apertura e registrazione automatica nei recenti)
  - [✅] Integrazione in UMOpenRecentPanelView.swift (pulsante "Find on Disk...", visualizzazione e gestione file scoperti)
  - [✅] Verifica build di tutti i componenti UI
- [✅] Milestone 8: Previews, Testing, Documentazione e Push
  - [✅] Aggiornamento UMRecentFilesShowcase.swift con simulatore interattivo di ricerca su disco
  - [✅] Aggiunta di unit test in UMRecentFilesV2Tests per il rilevamento tipi e il coordinatore di ricerca
  - [✅] Esecuzione completa di `swift test`
  - [✅] Aggiornamento di README.md, WalkThrough.md e task.md
  - [✅] Commit e Push su main
