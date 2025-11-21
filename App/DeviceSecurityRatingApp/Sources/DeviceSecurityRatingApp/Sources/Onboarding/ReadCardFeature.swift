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
import DeviceCheck
import DeviceSecurityRating
import SwiftUI

struct ReadCardFeature: Reducer {
    struct Path: Reducer {
        enum State: Equatable {}

        enum Action {}

        var body: some ReducerOf<Self> {
            EmptyReducer()
        }
    }

    struct State: Equatable {
        @PresentationState var path: Path.State?

        var loadingState: LoadingState = .prepare

        enum LoadingState: Equatable {
            case prepare
            case loading
            case finished
            case failed(severity: Severity, message: String)
        }

        enum Severity: Equatable {
            case warning
            case error
        }

        init(loadingState: LoadingState = .prepare, path: Path.State? = nil) {
            self.loadingState = loadingState
            self.path = path
        }
    }

    enum Action {
        case path(PresentationAction<Path.Action>)
        case start
        case updateLoadingState(State.LoadingState)
        case delegate(Delegate)

        enum Delegate {
            case finished
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.trustService) var trustService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .updateLoadingState(loadingState):
                state.loadingState = loadingState
                return .none
            case .delegate:
                return .none
            case .start:
                switch state.loadingState {
                case .prepare,
                     .failed:
                    state.loadingState = .loading
                    return .run { send in
                        do {
                            try await trustService.resetAttestation()

                            try await trustService.registration()

                            await send(.updateLoadingState(.finished))
                        } catch {
                            let message: String
                            switch error {
                            case DCError.serverUnavailable:
                                message = "servers are currently unavailable"
                            default:
                                message = error.localizedDescription
                            }

                            await send(.updateLoadingState(.finished))
//                            await send(.updateLoadingState(.failed(severity: .error, message: message)))
                        }
                    }
                    .animation(.easeInOut)
                case .loading:
                    return .none
                case .finished:
                    return .send(.delegate(.finished))
                }
            case .path:
                return .none
            }
        }
//        .ifLet(\.$path, action: /Action.path) {
//            Path()
//        }
    }
}

struct ReadCardView: View {
    var store: StoreOf<ReadCardFeature>
    @ObservedObject var viewStore: ViewStoreOf<ReadCardFeature>

    init(store: StoreOf<ReadCardFeature>) {
        self.store = store
        viewStore = ViewStore(store) { $0 }
    }

    var title: String {
        switch viewStore.loadingState {
        case .prepare:
            return "Karte an Telefon anlegen"
        case .loading:
            return "Prüfung Ihrer Gerätesicherheit"
        case .finished:
            return "Die Prüfung war erfolgreich"
        case .failed:
            return "Die Prüfung ist fehlgeschlagen"
        }
    }

    var description: String {
        switch viewStore.loadingState {
        case .prepare:
            return "Karte an Telefon anlegen"
        case .loading:
            return "Prüfung Ihrer Gerätesicherheit"
        case .finished:
            return "Die Prüfung war erfolgreich"
        case let .failed(severity: _, message: message):
            return message
        }
    }

    var descriptionColor: Color {
        switch viewStore.loadingState {
        case .failed(severity: .error, message: _):
            return Colors.alertNegativ
        case .failed(severity: .warning, message: _):
            return Colors.yellow600
        default:
            return Colors.text
        }
    }

    var imageName: String {
        switch viewStore.loadingState {
        case .prepare:
            return "read_card_egk_alignment"
        case .loading:
            return "read_card_security_info"
        case .finished:
            return "read_card_security_info"
        case .failed(severity: .warning, message: _):
            return "read_card_security_warning"
        case .failed(severity: .error, message: _):
            return "read_card_security_error"
        }
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 32) {
                    Text(title)
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(description)
                        .foregroundColor(descriptionColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(imageName, bundle: .module)
                }
                .padding()
            }

            HStack {
                Spacer()

                Button {
                    store.send(.start, animation: .default)
                } label: {
                    Text("Anmelden")
                }
                .buttonStyle(.primary(isEnabled: viewStore.loadingState != .loading))
                .padding()

                Spacer()
            }
        }
    }
}

struct ReadCardView_PreviewProvider: PreviewProvider {
    static var previews: some View {
        ReadCardView(store: StoreOf<ReadCardFeature>(
            initialState: .init(loadingState: .prepare)
        ) {
            ReadCardFeature()
        })
    }
}
