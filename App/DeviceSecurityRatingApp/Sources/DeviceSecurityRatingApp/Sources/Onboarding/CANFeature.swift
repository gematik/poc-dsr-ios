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

struct CANFeature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case pin(state: PINFeature.State)
        }

        enum Action {
            case pin(action: PINFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.pin, action: /Action.pin(action:)) {
                PINFeature()
            }
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?

        @BindingState var can: String = ""
        @BindingState var focus: Field?

        enum Field: Hashable {
            case can
        }
    }

    enum Action: BindableAction {
        case path(PresentationAction<Path.Action>)
        case binding(BindingAction<State>)
        case proceed
        case onAppear
        case setFocus
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await DispatchQueue.main.sleep(for: 1)

                    await send(.binding(.set(\.$focus, .can)))
                }
            case .setFocus:
                state.focus = .can
                return .none
            case .proceed:
                state.path = .pin(state: .init())
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

struct CANView: View {
    var store: StoreOf<CANFeature>
    @FocusState var focus: CANFeature.State.Field?

    var body: some View {
        WithViewStore(store) { $0 } content: { viewStore in
            ScrollView {
                VStack(spacing: 32) {
                    Text("CAN der eGK  eingeben")
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Diese finden Sie in der rechten oberen Ecke Ihrer Gesundheitskarte.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    FormTextField("CAN", text: viewStore.$can)
                        .focused($focus, equals: CANFeature.State.Field.can)
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
            }
            .bind(viewStore.$focus, to: self.$focus)
            .onAppear {
                store.send(.onAppear)
            }

            NavigationLinkStore(
                store.scope(state: \.$path, action: CANFeature.Action.path),
                state: /CANFeature.Path.State.pin(state:),
                action: CANFeature.Path.Action.pin(action:)
            ) {
                // not reachable
            } destination: { store in
                PINView(store: store)
            } label: {
                EmptyView()
            }
        }
    }
}
