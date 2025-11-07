//
//  LocalizationService.swift
//  PlantDoctorApp
//
//  Created by Claude
//

import Foundation

class LocalizationService {
    static let shared = LocalizationService()

    private var currentLanguage: AppLanguage = .english

    private init() {
        currentLanguage = PersistenceService.shared.getLanguage()
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        PersistenceService.shared.saveLanguage(language)
    }

    func getLanguage() -> AppLanguage {
        return currentLanguage
    }

    // Localized strings
    func localize(_ key: LocalizedStringKey) -> String {
        return key.localized(for: currentLanguage)
    }
}

enum LocalizedStringKey {
    case appTitle
    case appSubtitle
    case camera
    case gallery
    case analyzing
    case healthStatus
    case diagnosis
    case problemsFound
    case treatment
    case confidence
    case healthy
    case issuesDetected
    case history
    case reminders
    case community
    case settings
    case export
    case share
    case plantName
    case species
    case commonName
    case scientificName
    case careLevel
    case watering
    case sunlight
    case noPlantSelected

    func localized(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishStrings[self] ?? "Unknown"
        case .spanish:
            return spanishStrings[self] ?? englishStrings[self] ?? "Unknown"
        case .french:
            return frenchStrings[self] ?? englishStrings[self] ?? "Unknown"
        case .german:
            return germanStrings[self] ?? englishStrings[self] ?? "Unknown"
        case .chinese:
            return chineseStrings[self] ?? englishStrings[self] ?? "Unknown"
        case .japanese:
            return japaneseStrings[self] ?? englishStrings[self] ?? "Unknown"
        default:
            return englishStrings[self] ?? "Unknown"
        }
    }

    private var englishStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "Plant Doctor",
            .appSubtitle: "Diagnose your plant's health",
            .camera: "Camera",
            .gallery: "Gallery",
            .analyzing: "Analyzing your plant...",
            .healthStatus: "Health Status",
            .diagnosis: "Diagnosis",
            .problemsFound: "Problems Found",
            .treatment: "Treatment Recommendations",
            .confidence: "Confidence",
            .healthy: "Plant looks healthy!",
            .issuesDetected: "Issues detected",
            .history: "History",
            .reminders: "Reminders",
            .community: "Community",
            .settings: "Settings",
            .export: "Export",
            .share: "Share",
            .plantName: "Plant Name",
            .species: "Species",
            .commonName: "Common Name",
            .scientificName: "Scientific Name",
            .careLevel: "Care Level",
            .watering: "Watering",
            .sunlight: "Sunlight",
            .noPlantSelected: "No plant selected"
        ]
    }

    private var spanishStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "Doctor de Plantas",
            .appSubtitle: "Diagnostica la salud de tu planta",
            .camera: "Cámara",
            .gallery: "Galería",
            .analyzing: "Analizando tu planta...",
            .healthStatus: "Estado de Salud",
            .diagnosis: "Diagnóstico",
            .problemsFound: "Problemas Encontrados",
            .treatment: "Recomendaciones de Tratamiento",
            .confidence: "Confianza",
            .healthy: "¡La planta se ve saludable!",
            .issuesDetected: "Problemas detectados",
            .history: "Historial",
            .reminders: "Recordatorios",
            .community: "Comunidad",
            .settings: "Configuración",
            .export: "Exportar",
            .share: "Compartir"
        ]
    }

    private var frenchStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "Docteur des Plantes",
            .appSubtitle: "Diagnostiquez la santé de votre plante",
            .camera: "Caméra",
            .gallery: "Galerie",
            .analyzing: "Analyse de votre plante...",
            .healthStatus: "État de Santé",
            .diagnosis: "Diagnostic",
            .problemsFound: "Problèmes Trouvés",
            .treatment: "Recommandations de Traitement",
            .confidence: "Confiance",
            .healthy: "La plante a l'air saine!",
            .issuesDetected: "Problèmes détectés"
        ]
    }

    private var germanStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "Pflanzendoktor",
            .appSubtitle: "Diagnostizieren Sie die Gesundheit Ihrer Pflanze",
            .camera: "Kamera",
            .gallery: "Galerie",
            .analyzing: "Ihre Pflanze wird analysiert...",
            .healthStatus: "Gesundheitszustand",
            .diagnosis: "Diagnose",
            .problemsFound: "Gefundene Probleme",
            .treatment: "Behandlungsempfehlungen",
            .confidence: "Vertrauen",
            .healthy: "Die Pflanze sieht gesund aus!",
            .issuesDetected: "Probleme erkannt"
        ]
    }

    private var chineseStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "植物医生",
            .appSubtitle: "诊断您的植物健康",
            .camera: "相机",
            .gallery: "图库",
            .analyzing: "正在分析您的植物...",
            .healthStatus: "健康状况",
            .diagnosis: "诊断",
            .problemsFound: "发现的问题",
            .treatment: "治疗建议",
            .confidence: "置信度",
            .healthy: "植物看起来很健康！",
            .issuesDetected: "检测到问题"
        ]
    }

    private var japaneseStrings: [LocalizedStringKey: String] {
        [
            .appTitle: "植物ドクター",
            .appSubtitle: "植物の健康を診断する",
            .camera: "カメラ",
            .gallery: "ギャラリー",
            .analyzing: "植物を分析中...",
            .healthStatus: "健康状態",
            .diagnosis: "診断",
            .problemsFound: "見つかった問題",
            .treatment: "治療の推奨事項",
            .confidence: "信頼度",
            .healthy: "植物は健康に見えます！",
            .issuesDetected: "問題が検出されました"
        ]
    }
}
