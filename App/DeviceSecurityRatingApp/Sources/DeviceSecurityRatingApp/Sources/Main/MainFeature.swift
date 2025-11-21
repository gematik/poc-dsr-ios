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

struct MainFeature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {
            case security(SecurityFeature.State)
        }

        enum Action {
            case security(SecurityFeature.Action)
        }

        var body: some ReducerOf<Self> {
            Scope(state: /State.security, action: /Action.security) {
                SecurityFeature()
            }
        }
    }

    struct State: Equatable {
        var loading: Loading = .empty
        var text = ""
        var tasks: IdentifiedArrayOf<Components.Schemas.ERezept_v1> = [
            .mock,
            .mock2,
        ]

        @PresentationState var path: Path.State?

        enum Loading {
            case empty
            case finished
            case loading
        }
    }

    enum Action {
        case showSecurity
        case path(PresentationAction<Path.Action>)
        case load
        case receive([Components.Schemas.ERezept_v1])
        case error(String)
    }

    @Dependency(\.fdClient) var fdClient
    @Dependency(\.trustService) var trustService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .receive(value):
                state.loading = .finished
                state.tasks = IdentifiedArray(uniqueElements: value)
                return .none
            case let .error(value):
                state.loading = .empty
                state.text = value
                return .none
            case .load:
                state.loading = .loading
                state.text = ""
                return .run { send in
                    do {
                        let attestation = try await trustService.requestAttestation()

                        let tasks = try await fdClient.getTasks(attestation)

                        await send(.receive(tasks))
                    } catch {
                        await send(.error(error.localizedDescription))
                    }
                }
            case .path:
                return .none
            case .showSecurity:
                state.path = .security(.init())
                return .none
            }
        }.ifLet(\.$path, action: /Action.path) {
            Path()
        }
    }
}

struct MainView: View {
    var store: StoreOf<MainFeature>

    @ObservedObject var viewStore: ViewStoreOf<MainFeature>

    init(store: StoreOf<MainFeature>) {
        self.store = store
        viewStore = ViewStore(store) { $0 }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    WithViewStore(store) { $0 } content: { viewStore in
                        VStack(spacing: 16) {
                            HStack {
                                Spacer()
                                Button {
                                    viewStore.send(.load)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                            }
                            .padding(.horizontal)
                            switch viewStore.loading {
                            case .loading:
                                VStack {
                                    Spacer(minLength: 200)
                                    HStack(alignment: .bottom) {
                                        Spacer()
                                        VStack(spacing: 16) {
                                            ProgressView()
                                            Text("Lade Inhalte...")
                                        }
                                        .foregroundColor(Colors.text)
                                        .font(.footnote)
                                        .padding()
                                        .background(Colors.systemFillSecondary)
                                        .cornerRadius(16)
                                        Spacer()
                                    }
                                }
                                .transition(.scale)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            case .empty:
                                VStack {
                                    Spacer(minLength: 200)
                                    HStack {
                                        Spacer()

                                        VStack {
                                            Button {
                                                viewStore.send(.load)
                                            } label: {
                                                Label("Inhalte laden", systemImage: "arrow.clockwise")
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            case .finished:
                                VStack(spacing: 16) {
                                    ForEach(viewStore.tasks, id: \.self) { task in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.prescription.medication)
                                                .font(.body.bold())
                                            Text(task.prescription.dosageInstruction ?? "no dosage")
                                            HStack {
                                                Text(task.prescription.packSize ?? "no packSize")
                                                Spacer()
                                                Text(task.prescription.strength ?? "no strength")
                                            }
                                            .font(.footnote)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Colors.systemBackgroundSecondary)
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .toolbar {
                    Button {
                        store.send(.showSecurity, animation: .easeInOut)
                    } label: {
                        Image(systemName: "checkmark.shield")
                    }
                }

                if viewStore.text.lengthOfBytes(using: .utf8) > 0 {
                    VStack {
                        Spacer()

                        HStack {
                            Text(viewStore.text)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Colors.systemBackgroundSecondary)
                        .cornerRadius(8)
                        .padding(16)
                        .shadow(radius: 2)
                    }
                }

                IfLetStore(
                    store.scope(state: \.$path, action: MainFeature.Action.path),
                    state: /MainFeature.Path.State.security,
                    action: MainFeature.Path.Action.security
                ) { store in
                    SecurityView(store: store)
                }
            }
            .navigationTitle("Main")
            .frame(maxHeight: .infinity)
        }
    }
}

struct MainViewPreviewProvider: PreviewProvider {
    static var previews: some View {
        MainView(store: .init(initialState: .init(loading: .empty)) {
            MainFeature()
                ._printChanges()
        })
    }
}

extension Components.Schemas.ERezept_v1: Identifiable {
    static var mock: Self =
        .init(id: "123",
              issuedAt: Date(),
              patient: .mock,
              doctor: .mock,
              prescription: .mock)
    static var mock2: Self =
        .init(id: "1233",
              issuedAt: Date(),
              patient: .mock,
              doctor: .mock,
              prescription: .mock)
}

extension Components.Schemas.ERezept_v1.patientPayload {
    static var mock: Self =
        .init(
            name: "name",
            address: "address",
            contact: "contact"
        )
}

extension Components.Schemas.ERezept_v1.doctorPayload {
    static var mock: Self =
        .init(
            name: "Dr. Dr. dr"
        )
}

extension Components.Schemas.ERezept_v1.prescriptionPayload {
    static var mock: Self =
        .init(
            medication: "medication",
            strength: "strength",
            packSize: "packSize",
            dosageInstruction: "dosageInstruction"
        )
}
