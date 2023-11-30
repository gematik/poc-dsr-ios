//
//  Copyright (c) 2023 gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ComposableArchitecture
import SwiftUI

struct Onboarding1Feature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case screen2(state: Onboarding2Feature.State)
        }

        enum Action {
            case screen2(action: Onboarding2Feature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.screen2, action: /Action.screen2(action:)) {
                Onboarding2Feature()
            }
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?
    }

    enum Action {
        case path(PresentationAction<Path.Action>)
        case delegate(Delegate)
        case proceed

        enum Delegate {
            case finish
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .proceed:
                state.path = .screen2(state: .init())
                return .none
            case .path(.presented(.screen2(
                action: .path(.presented(.can(
                    action: .path(.presented(.pin(
                        action: .path(.presented(.readCard(
                            action: .delegate(.finished)
                        )))
                    )))
                )))
            ))):
                return .send(.delegate(.finish))
            case .path:
                return .none
            case .delegate:
                return .none
            }
        }.ifLet(\.$path, action: /Action.path) {
            Path()
        }
    }
}

struct Onboarding1View: View {
    var store: StoreOf<Onboarding1Feature>

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Image("onboarding1", bundle: .module)
                        .resizable()

                    VStack(spacing: 32) {
                        Text("Ihre Patientendaten immer dabei")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 8) {
                            BulletPoint("Ihre medizinischen Daten für eine optimale Behandlung")
                            BulletPoint("Geben Sie Ihre Daten den medizinischen Experten Ihres Vertrauens frei")
                            BulletPoint("Verwalten Sie online Ihre persönlichen Notfalldaten")
                            BulletPoint("Lösen Sie einfach und schnell Rezepte ein")
                            BulletPoint("uvm.")
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .ignoresSafeArea(.all, edges: .top)

                HStack {
                    Spacer()

                    Button {
                        store.send(.proceed)
                    } label: {
                        Text("Anmelden")
                    }
                    .buttonStyle(.primary)
                    .padding()

                    Spacer()
                }
                NavigationLinkStore(
                    store.scope(state: \.$path, action: Onboarding1Feature.Action.path),
                    state: /Onboarding1Feature.Path.State.screen2(state:),
                    action: Onboarding1Feature.Path.Action.screen2(action:)
                ) {
                    // not reachable
                } destination: { store in
                    Onboarding2View(store: store)
                } label: {
                    EmptyView()
                }
            }
        }
    }
}

struct Onboarding1FeaturePreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Onboarding1View(store: .init(initialState: .init()) {
                Onboarding1Feature()
                    ._printChanges()
            })
        }
    }
}
