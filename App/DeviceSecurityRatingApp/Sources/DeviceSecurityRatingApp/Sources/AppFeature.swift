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

struct AppFeature: Reducer {
    enum State {
        case onboarding(Onboarding1Feature.State)
        case tabs(TabsFeature.State)
    }

    enum Action {
        case onboarding(action: Onboarding1Feature.Action)
        case tabs(action: TabsFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: /State.onboarding, action: /Action.onboarding(action:)) {
            Onboarding1Feature()
        }
        Scope(state: /State.tabs, action: /Action.tabs(action:)) {
            TabsFeature()
        }
        Reduce { state, action in
            switch action {
            case .onboarding(action: .delegate(.finish)):
                state = .tabs(.init())
                return .none
            default:
                return .none
            }
        }
    }
}

public struct DeviceSecurityRatingApp: View {
    public init() {}

    public var body: some View {
        AppView(
            store: Store(
                initialState: .onboarding(.init())
            ) {
                AppFeature()
            }
        )
    }
}

struct AppView: View {
    var store: StoreOf<AppFeature>

    init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    var body: some View {
        SwitchStore(store) { initialState in
            switch initialState {
            case .onboarding:
                CaseLet(
                    /AppFeature.State.onboarding,
                    action: AppFeature.Action.onboarding(action:)
                ) { loggedInStore in
                    Onboarding1View(store: loggedInStore)
                }
            case .tabs:
                CaseLet(/AppFeature.State.tabs, action: AppFeature.Action.tabs(action:)) { store in
                    TabsView(store: store)
                }
            }
        }
    }
}

struct AppFeature_PreviewProvider: PreviewProvider {
    static var previews: some View {
        AppView(store: .init(initialState: .tabs(.init())) {
            AppFeature()
        })
    }
}
