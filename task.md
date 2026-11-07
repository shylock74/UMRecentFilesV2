# Task List - UMRecentFilesV2

- [✅] Milestone 1: Configurazione Package e Target macOS
  - [✅] Aggiornamento Package.swift con supporto macOS (.v12) e dipendenze
  - [✅] Verifica compilazione iniziale con `swift build`
- [✅] Milestone 2: Core Data Layer e Helpers
  - [✅] Implementazione UMRecentFileHelpers.swift (formattazione dimensioni, date, string search, Finder reveal, security bookmarks)
  - [✅] Implementazione UMRecentFile.swift (modello Codable/Identifiable/Sendable con decodifica retrocompatibile)
  - [✅] Implementazione UMRecentFilesConfiguration.swift (opzioni sorgente dati, ordinamento, filtri)
  - [✅] Implementazione UMRecentFiles.swift (manager ibrido UserDefaults + NSDocumentController, gestione Pin, rimozione, fillRecentFilesMenu)
  - [✅] Implementazione UMRecentThumbnailLoader.swift (anteprime QuickLook asincrone con NSCache e fallback a NSWorkspace icon)
- [✅] Milestone 3: Componenti UI SwiftUI con UMUIControls
  - [✅] Implementazione UMRecentFilesHeaderView.swift e UMRecentFilesFilterBar.swift (ricerca con UMUITextField, pillole filtri)
  - [✅] Implementazione UMRecentFileRowView.swift (riga lista con QuickLook icon, metadati, hover action buttons, context menu, drag & drop)
  - [✅] Implementazione UMRecentFileCardView.swift (layout a griglia con card e preview grafica)
  - [✅] Implementazione UMRecentFilesView.swift (pannello collassabile retrocompatibile con transizioni, layout switch e stati vuoti con UMUIEmptyStateView)
  - [✅] Implementazione UMOpenRecentPanelView.swift e wrapper AppKit UMOpenRecent / UMOpenRecentVC
  - [✅] Implementazione UMRecentFilesMenu.swift (supporto menu SwiftUI e AppKit)
- [✅] Milestone 4: Typealias, Retrocompatibilità e Documentazione
  - [✅] Esportazione typealias e metodi helper in UMRecentFilesV2.swift
  - [✅] Aggiornamento README.md e creazione/aggiornamento WalkThrough.md
- [✅] Milestone 5: Previews, Testing e Verifica Finale
  - [✅] Implementazione UMRecentFilesShowcase.swift con mock data realistici e preview interattive
  - [✅] Scrittura ed esecuzione unit tests in UMRecentFilesV2Tests
  - [✅] Verifica build e test completi (`swift test`)

