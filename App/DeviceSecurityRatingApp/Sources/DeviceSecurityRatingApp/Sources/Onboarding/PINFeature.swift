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

struct PINFeature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case readCard(state: ReadCardFeature.State)
        }

        enum Action {
            case readCard(action: ReadCardFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.readCard, action: /Action.readCard(action:)) {
                ReadCardFeature()
            }
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?

        @BindingState var pin: String = ""
        @BindingState var focus: Field?

        enum Field: Hashable {
            case pin
        }
    }

    enum Action: BindableAction {
        case path(PresentationAction<Path.Action>)
        case binding(BindingAction<State>)
        case proceed
        case onAppear
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await DispatchQueue.main.sleep(for: 1)

                    await send(.binding(.set(\.$focus, .pin)))
                }
            case .proceed:
                state.path = .readCard(state: .init())
                return .none
            case .binding,
                 .path:
                return .none
            }
        }
        .ifLet(\.$path, action: /Action.path) {
            Path()
        }
    }
}

struct PINView: View {
    var store: StoreOf<PINFeature>
    @FocusState var focus: PINFeature.State.Field?

    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in
            ScrollView {
                VStack(spacing: 32) {
                    Text("PIN eingeben")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Ihre PIN haben Sie von Ihrer  Versicherung erhalten.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    FormTextField("PIN", text: viewStore.$pin)
                        .focused($focus, equals: .pin)
                        .onSubmit {
                            store.send(.proceed)
                        }
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()

                                Button("Done") {
                                    store.send(.proceed)
                                }
                            }
                        }
                }
                .padding(.horizontal, 32)

                NavigationLinkStore(
                    store.scope(state: \.$path, action: PINFeature.Action.path),
                    state: /PINFeature.Path.State.readCard(state:),
                    action: PINFeature.Path.Action.readCard(action:)
                ) {
                    // not reachable
                } destination: { store in
                    ReadCardView(store: store)
                } label: {
                    EmptyView()
                }
            }
            .bind(viewStore.$focus, to: self.$focus)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}
