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

struct SettingsFeature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case devices(DevicesFeature.State)
        }

        enum Action {
            case devices(DevicesFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.devices, action: /Action.devices) {
                DevicesFeature()
            }
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?
    }

    enum Action {
        case path(PresentationAction<Path.Action>)
        case showDevices
    }

    @Dependency(\.fdClient) var fdClient
    @Dependency(\.trustService) var trustService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .showDevices:
                state.path = .devices(.init())
                return .none
            case .path:
                return .none
            }
        }.ifLet(\.$path, action: /Action.path) {
            Path()
        }
    }
}

struct SettingsView: View {
    var store: StoreOf<SettingsFeature>

    @ObservedObject var viewStore: ViewStoreOf<SettingsFeature>

    init(store: StoreOf<SettingsFeature>) {
        self.store = store
        viewStore = ViewStore(store) { $0 }
    }

    var body: some View {
        NavigationView {
            List {
                NavigationLinkStore(
                    store.scope(state: \.$path, action: SettingsFeature.Action.path),
                    state: /SettingsFeature.Path.State.devices,
                    action: SettingsFeature.Path.Action.devices,
                    onTap: {
                        viewStore.send(.showDevices)
                    },
                    destination: DevicesView.init(store:),
                    label: {
                        Label("Devices", systemImage: "iphone")
                    }
                )
            }
            .navigationTitle("Settings")
            .frame(maxHeight: .infinity)
        }
    }
}

struct SettingsViewPreviewProvider: PreviewProvider {
    static var previews: some View {
        SettingsView(store: .init(initialState: .init()) {
            SettingsFeature()
                ._printChanges()
        })
    }
}
