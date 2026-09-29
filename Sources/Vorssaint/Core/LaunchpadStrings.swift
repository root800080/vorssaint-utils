// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct LaunchpadStrings {
    let pageTitle: String
    let hubDescription: String
    let openButton: String
    let searchPlaceholder: String
    let shortcutTitle: String
    let newFolderDefaultName: String
    let resetLayoutButton: String
}

extension FeatureStrings {
    static func launchpad(_ language: AppLanguage) -> LaunchpadStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .uk: return .uk
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension LaunchpadStrings {
    static let enUS = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Open a full-screen grid of every installed app, like the original Launchpad.",
        openButton: "Open Launchpad",
        searchPlaceholder: "Search Applications",
        shortcutTitle: "Shortcut",
        newFolderDefaultName: "New Folder",
        resetLayoutButton: "Reset Layout")

    static let ptBR = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Abra uma grade em tela cheia com todos os apps instalados, como o Launchpad original.",
        openButton: "Abrir Launchpad",
        searchPlaceholder: "Buscar Aplicativos",
        shortcutTitle: "Atalho",
        newFolderDefaultName: "Nova Pasta",
        resetLayoutButton: "Redefinir Layout")

    static let tr = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Orijinal Launchpad gibi, yüklü tüm uygulamaların tam ekran bir ızgarasını açar.",
        openButton: "Launchpad’i Aç",
        searchPlaceholder: "Uygulama Ara",
        shortcutTitle: "Kısayol",
        newFolderDefaultName: "Yeni Klasör",
        resetLayoutButton: "Düzeni Sıfırla")

    static let ru = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Открывает полноэкранную сетку всех установленных приложений, как в оригинальном Launchpad.",
        openButton: "Открыть Launchpad",
        searchPlaceholder: "Поиск приложений",
        shortcutTitle: "Сочетание клавиш",
        newFolderDefaultName: "Новая папка",
        resetLayoutButton: "Сбросить раскладку")

    static let es = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Abre una cuadrícula a pantalla completa con todas las apps instaladas, como el Launchpad original.",
        openButton: "Abrir Launchpad",
        searchPlaceholder: "Buscar aplicaciones",
        shortcutTitle: "Atajo",
        newFolderDefaultName: "Nueva carpeta",
        resetLayoutButton: "Restablecer diseño")

    static let sk = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Otvorí celoobrazovkovú mriežku všetkých nainštalovaných aplikácií, podobne ako pôvodný Launchpad.",
        openButton: "Otvoriť Launchpad",
        searchPlaceholder: "Hľadať aplikácie",
        shortcutTitle: "Skratka",
        newFolderDefaultName: "Nový priečinok",
        resetLayoutButton: "Obnoviť rozloženie")

    static let de = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Öffnet ein Vollbildraster aller installierten Apps, wie das ursprüngliche Launchpad.",
        openButton: "Launchpad öffnen",
        searchPlaceholder: "Programme suchen",
        shortcutTitle: "Tastenkombination",
        newFolderDefaultName: "Neuer Ordner",
        resetLayoutButton: "Layout zurücksetzen")

    static let fr = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Ouvre une grille plein écran de toutes les apps installées, comme le Launchpad d’origine.",
        openButton: "Ouvrir Launchpad",
        searchPlaceholder: "Rechercher des applications",
        shortcutTitle: "Raccourci",
        newFolderDefaultName: "Nouveau dossier",
        resetLayoutButton: "Réinitialiser la disposition")

    static let it = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Apre una griglia a schermo intero con tutte le app installate, come il Launchpad originale.",
        openButton: "Apri Launchpad",
        searchPlaceholder: "Cerca applicazioni",
        shortcutTitle: "Scorciatoia",
        newFolderDefaultName: "Nuova cartella",
        resetLayoutButton: "Ripristina disposizione")

    static let ja = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "元のLaunchpadのように、インストール済みのすべてのアプリを全画面表示のグリッドで開きます。",
        openButton: "Launchpadを開く",
        searchPlaceholder: "アプリケーションを検索",
        shortcutTitle: "ショートカット",
        newFolderDefaultName: "新規フォルダ",
        resetLayoutButton: "レイアウトをリセット")

    static let ko = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "원래의 Launchpad처럼 설치된 모든 앱을 전체 화면 그리드로 엽니다.",
        openButton: "Launchpad 열기",
        searchPlaceholder: "응용 프로그램 검색",
        shortcutTitle: "단축키",
        newFolderDefaultName: "새로운 폴더",
        resetLayoutButton: "레이아웃 재설정")

    static let uk = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "Відкриває повноекранну сітку всіх встановлених застосунків, як оригінальний Launchpad.",
        openButton: "Відкрити Launchpad",
        searchPlaceholder: "Пошук програм",
        shortcutTitle: "Сполучення клавіш",
        newFolderDefaultName: "Нова папка",
        resetLayoutButton: "Скинути розташування")

    static let zhHans = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "像原来的 Launchpad 一样，全屏显示所有已安装应用的网格。",
        openButton: "打开 Launchpad",
        searchPlaceholder: "搜索应用程序",
        shortcutTitle: "快捷键",
        newFolderDefaultName: "新建文件夹",
        resetLayoutButton: "重置布局")

    static let zhTW = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "像原本的 Launchpad 一樣，以全螢幕方式顯示所有已安裝應用程式的網格。",
        openButton: "打開 Launchpad",
        searchPlaceholder: "搜尋應用程式",
        shortcutTitle: "快速鍵",
        newFolderDefaultName: "新資料夾",
        resetLayoutButton: "重設版面配置")

    static let zhHK = LaunchpadStrings(
        pageTitle: "Launchpad Classic",
        hubDescription: "像原本的 Launchpad 一樣，以全螢幕顯示所有已安裝應用程式的網格。",
        openButton: "打開 Launchpad",
        searchPlaceholder: "搜尋應用程式",
        shortcutTitle: "快速鍵",
        newFolderDefaultName: "新資料夾",
        resetLayoutButton: "重設版面配置")
}
