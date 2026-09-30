// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Strings for the Shortcuts actions. Same contract as the other
/// FeatureStrings structs: memberwise init in declaration order, one static
/// per language, all in this file.
struct ShortcutsActionsStrings {
    let sectionTitle: String
    let toggle: String
    let caption: String
    let disabledMessage: String
    let notInstalledMessage: String
    let darkModeName: String
}

extension FeatureStrings {
    static func shortcutsActions(_ language: AppLanguage) -> ShortcutsActionsStrings {
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
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        case .uk: return .uk
        }
    }
}

extension ShortcutsActionsStrings {
    static let enUS = ShortcutsActionsStrings(
        sectionTitle: "Shortcuts actions",
        toggle: "Allow Shortcuts to run Vorssaint actions",
        caption: "Lets the Shortcuts app run actions from Vorssaint, only for the features you have installed. Nothing runs in the background.",
        disabledMessage: "Turn on “Allow Shortcuts to run Vorssaint actions” in the Advanced settings of Vorssaint first.",
        notInstalledMessage: "This feature is not installed in Vorssaint.",
        darkModeName: "Dark mode"
    )

    static let ptBR = ShortcutsActionsStrings(
        sectionTitle: "Ações dos Atalhos",
        toggle: "Permitir que os Atalhos executem ações do Vorssaint",
        caption: "Permite que o app Atalhos execute ações do Vorssaint, só para as funções instaladas. Nada roda em segundo plano.",
        disabledMessage: "Ative antes “Permitir que os Atalhos executem ações do Vorssaint” em Avançado, nos ajustes do Vorssaint.",
        notInstalledMessage: "Esta função não está instalada no Vorssaint.",
        darkModeName: "Modo escuro"
    )

    static let tr = ShortcutsActionsStrings(
        sectionTitle: "Kestirme eylemleri",
        toggle: "Kestirmelerin Vorssaint eylemlerini çalıştırmasına izin ver",
        caption: "Kestirmeler uygulamasının Vorssaint eylemlerini çalıştırmasına izin verir, yalnızca kurduğunuz özellikler için. Arka planda hiçbir şey çalışmaz.",
        disabledMessage: "Önce Vorssaint’in Gelişmiş ayarlarında “Kestirmelerin Vorssaint eylemlerini çalıştırmasına izin ver” seçeneğini açın.",
        notInstalledMessage: "Bu özellik Vorssaint’te kurulu değil.",
        darkModeName: "Koyu mod"
    )

    static let ru = ShortcutsActionsStrings(
        sectionTitle: "Действия для Быстрых команд",
        toggle: "Разрешить Быстрым командам запускать действия Vorssaint",
        caption: "Позволяет приложению «Быстрые команды» запускать действия Vorssaint, только для установленных функций. В фоне ничего не работает.",
        disabledMessage: "Сначала включите «Разрешить Быстрым командам запускать действия Vorssaint» в разделе «Дополнительно» настроек Vorssaint.",
        notInstalledMessage: "Эта функция не установлена в Vorssaint.",
        darkModeName: "Тёмная тема"
    )

    static let es = ShortcutsActionsStrings(
        sectionTitle: "Acciones de Atajos",
        toggle: "Permitir que Atajos ejecute acciones de Vorssaint",
        caption: "Permite que la app Atajos ejecute acciones de Vorssaint, solo de las funciones instaladas. Nada se ejecuta en segundo plano.",
        disabledMessage: "Activa antes «Permitir que Atajos ejecute acciones de Vorssaint» en los ajustes Avanzado de Vorssaint.",
        notInstalledMessage: "Esta función no está instalada en Vorssaint.",
        darkModeName: "Modo oscuro"
    )

    static let sk = ShortcutsActionsStrings(
        sectionTitle: "Akcie pre Skratky",
        toggle: "Povoliť Skratkám spúšťať akcie Vorssaint",
        caption: "Umožní aplikácii Skratky spúšťať akcie Vorssaint, len pre nainštalované funkcie. Nič nebeží na pozadí.",
        disabledMessage: "Najprv zapnite „Povoliť Skratkám spúšťať akcie Vorssaint“ v nastaveniach Pokročilé v aplikácii Vorssaint.",
        notInstalledMessage: "Táto funkcia nie je v aplikácii Vorssaint nainštalovaná.",
        darkModeName: "Tmavý režim"
    )

    static let de = ShortcutsActionsStrings(
        sectionTitle: "Kurzbefehl-Aktionen",
        toggle: "Kurzbefehlen erlauben, Vorssaint-Aktionen auszuführen",
        caption: "Erlaubt der App „Kurzbefehle“, Aktionen von Vorssaint auszuführen, nur für die installierten Funktionen. Im Hintergrund läuft nichts.",
        disabledMessage: "Aktiviere zuerst „Kurzbefehlen erlauben, Vorssaint-Aktionen auszuführen“ in den Erweitert-Einstellungen von Vorssaint.",
        notInstalledMessage: "Diese Funktion ist in Vorssaint nicht installiert.",
        darkModeName: "Dunkelmodus"
    )

    static let fr = ShortcutsActionsStrings(
        sectionTitle: "Actions pour Raccourcis",
        toggle: "Autoriser Raccourcis à exécuter des actions de Vorssaint",
        caption: "Permet à l’app Raccourcis d’exécuter des actions de Vorssaint, uniquement pour les fonctions installées. Rien ne tourne en arrière-plan.",
        disabledMessage: "Activez d’abord «\u{00A0}Autoriser Raccourcis à exécuter des actions de Vorssaint\u{00A0}» dans les réglages Avancé de Vorssaint.",
        notInstalledMessage: "Cette fonction n’est pas installée dans Vorssaint.",
        darkModeName: "Mode sombre"
    )

    static let it = ShortcutsActionsStrings(
        sectionTitle: "Azioni per Comandi rapidi",
        toggle: "Consenti ai Comandi rapidi di eseguire azioni di Vorssaint",
        caption: "Permette all’app Comandi rapidi di eseguire azioni di Vorssaint, solo per le funzioni installate. Niente gira in background.",
        disabledMessage: "Attiva prima «Consenti ai Comandi rapidi di eseguire azioni di Vorssaint» nelle impostazioni Avanzate di Vorssaint.",
        notInstalledMessage: "Questa funzione non è installata in Vorssaint.",
        darkModeName: "Modalità scura"
    )

    static let ja = ShortcutsActionsStrings(
        sectionTitle: "ショートカットのアクション",
        toggle: "ショートカットが Vorssaint のアクションを実行できるようにする",
        caption: "ショートカット App が Vorssaint のアクションを実行できるようにします。対象はインストール済みの機能のみで、バックグラウンドでは何も動作しません。",
        disabledMessage: "先に Vorssaint の「詳細」設定で「ショートカットが Vorssaint のアクションを実行できるようにする」をオンにしてください。",
        notInstalledMessage: "この機能は Vorssaint にインストールされていません。",
        darkModeName: "ダークモード"
    )

    static let ko = ShortcutsActionsStrings(
        sectionTitle: "단축어 동작",
        toggle: "단축어가 Vorssaint 동작을 실행하도록 허용",
        caption: "단축어 앱이 설치된 기능에 한해 Vorssaint 동작을 실행하도록 허용합니다. 백그라운드에서는 아무것도 실행되지 않습니다.",
        disabledMessage: "먼저 Vorssaint의 고급 설정에서 ‘단축어가 Vorssaint 동작을 실행하도록 허용’을 켜세요.",
        notInstalledMessage: "이 기능은 Vorssaint에 설치되어 있지 않습니다.",
        darkModeName: "다크 모드"
    )

    static let zhHans = ShortcutsActionsStrings(
        sectionTitle: "快捷指令操作",
        toggle: "允许快捷指令运行 Vorssaint 操作",
        caption: "允许“快捷指令”App 运行 Vorssaint 的操作，仅限已安装的功能。不会在后台运行任何内容。",
        disabledMessage: "请先在 Vorssaint 的“高级”设置中开启“允许快捷指令运行 Vorssaint 操作”。",
        notInstalledMessage: "此功能未在 Vorssaint 中安装。",
        darkModeName: "深色模式"
    )

    static let zhTW = ShortcutsActionsStrings(
        sectionTitle: "捷徑動作",
        toggle: "允許捷徑執行 Vorssaint 動作",
        caption: "允許「捷徑」App 執行 Vorssaint 的動作，僅限已安裝的功能。不會在背景執行任何內容。",
        disabledMessage: "請先在 Vorssaint 的「進階」設定中開啟「允許捷徑執行 Vorssaint 動作」。",
        notInstalledMessage: "此功能尚未在 Vorssaint 中安裝。",
        darkModeName: "深色模式"
    )

    static let zhHK = ShortcutsActionsStrings(
        sectionTitle: "捷徑動作",
        toggle: "允許捷徑執行 Vorssaint 動作",
        caption: "允許「捷徑」App 執行 Vorssaint 的動作，僅限已安裝的功能。不會在背景執行任何內容。",
        disabledMessage: "請先在 Vorssaint 的「進階」設定中開啟「允許捷徑執行 Vorssaint 動作」。",
        notInstalledMessage: "此功能未有在 Vorssaint 中安裝。",
        darkModeName: "深色模式"
    )

    static let uk = ShortcutsActionsStrings(
        sectionTitle: "Дії для Команд",
        toggle: "Дозволити Командам запускати дії Vorssaint",
        caption: "Дозволяє застосунку «Команди» запускати дії Vorssaint, лише для встановлених функцій. У фоновому режимі нічого не працює.",
        disabledMessage: "Спершу ввімкніть «Дозволити Командам запускати дії Vorssaint» у налаштуваннях «Додатково» в Vorssaint.",
        notInstalledMessage: "Цю функцію не встановлено у Vorssaint.",
        darkModeName: "Темний режим"
    )
}
