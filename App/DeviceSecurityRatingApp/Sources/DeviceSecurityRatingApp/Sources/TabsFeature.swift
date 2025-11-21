//
//  Copyright (Change Date see Readme), gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  *******
//
//  For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import ComposableArchitecture
import SwiftUI

struct TabsFeature: Reducer {
    enum Path: Equatable {
//        case settings(SettingsFeature.State)
        case main
        case settings
    }

    struct State: Equatable {
        var main: MainFeature.State = .init()
        var settings: SettingsFeature.State = .init()

        var path: Path = .main
    }

    enum Action {
//        case settings(action: SettingsFeature.Action)
        case main(action: MainFeature.Action)
        case settings(action: SettingsFeature.Action)

        case setPath(_ path: Path)
    }

    var body: some ReducerOf<Self> {
//        Scope(state: /State.settings, action: /Action.settings(action:)) {
//            SettingsFeature()
//        }
        Scope(state: \.main, action: /Action.main(action:)) {
            MainFeature()
        }
        Scope(state: \.settings, action: /Action.settings(action:)) {
            SettingsFeature()
        }
        Reduce { state, action in
            switch action {
//            case .onboarding(action: .delegate(.finish)):
//                state = .main(.init())
//                return .none
            case let .setPath(path):
                state.path = path
                return .none
            default:
                return .none
            }
        }
    }
}

struct TabsView: View {
    var store: StoreOf<TabsFeature>
    @ObservedObject
    var viewStore: ViewStoreOf<TabsFeature>

    init(store: StoreOf<TabsFeature>) {
        self.store = store
        viewStore = ViewStore(store) { $0 }
    }

    var body: some View {
        TabView(selection: viewStore.binding(get: \.path, send: TabsFeature.Action.setPath)) {
            MainView(
                store: store.scope(
                    state: \.main,
                    action: TabsFeature.Action.main(action:)
                )
            )
            .tabItem {
                Label("Main", systemImage: "pills")
            }
            .tag(TabsFeature.Path.main)

            SettingsView(
                store: store.scope(
                    state: \.settings,
                    action: TabsFeature.Action.settings(action:)
                )
            ).tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(TabsFeature.Path.settings)
        }
    }
}

struct TabsFeature_PreviewProvider: PreviewProvider {
    static var previews: some View {
        AppView(store: .init(initialState: .tabs(.init())) {
            AppFeature()
                ._printChanges()
        })
    }
}
