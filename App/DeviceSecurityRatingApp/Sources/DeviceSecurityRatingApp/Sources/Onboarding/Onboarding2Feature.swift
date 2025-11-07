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

struct Onboarding2Feature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case can(state: CANFeature.State)
        }

        enum Action {
            case can(action: CANFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.can, action: /Action.can(action:)) {
                CANFeature()
            }
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?
    }

    enum Action {
        case path(PresentationAction<Path.Action>)
        case proceed
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .proceed:
                state.path = .can(state: .init())
                return .none
            case .path:
                return .none
            }
        }
        .ifLet(\.$path, action: /Action.path) {
            Path()
        }
    }
}

struct Onboarding2View: View {
    var store: StoreOf<Onboarding2Feature>

    var body: some View {
        VStack {
            ScrollView {
                Image("onboarding2", bundle: .module)
                    .resizable()

                VStack(spacing: 32) {
                    Text("Immer Sicher auf Ihre Daten zugreifen")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 8) {
                        Text(
                            "Damit Sie zukünftig auf Ihre Daten zugreifen können, prüfen wir jetzt Ihre Identität." +
                                " Dafür benötigen Sie: "
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        BulletPoint("Ihre eGK")
                        BulletPoint("Ihre CAN")
                        BulletPoint("Ihre PIN")
                        BulletPoint("Ein NFC fähiges Telefon")
                    }
                }
                .padding(.horizontal, 32)
            }
            .navigationTitle("Immer Sicher auf Ihre Daten zugreifen")
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .top)

            HStack {
                Spacer()

                Button {
                    store.send(.proceed)
                } label: {
                    Text("Weiter")
                }
                .buttonStyle(.primary)
                .padding()

                Spacer()
            }

            NavigationLinkStore(
                store.scope(state: \.$path, action: Onboarding2Feature.Action.path),
                state: /Onboarding2Feature.Path.State.can(state:),
                action: Onboarding2Feature.Path.Action.can(action:)
            ) {
                // not reachable
            }
            destination: { store in
                CANView(store: store)
            } label: {
                EmptyView()
            }
        }
    }
}

struct Onboarding2FeaturePreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Onboarding2View(store: .init(initialState: .init()) {
                Onboarding2Feature()
            })
        }
    }
}
