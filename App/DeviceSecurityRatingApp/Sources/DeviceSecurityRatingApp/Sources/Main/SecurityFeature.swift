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

struct SecurityFeature: Reducer {
    struct State: Equatable {
        var location: String = "Berlin, DE"
        var name: String = "Mustermann, Max"
        var deviceName: String = "iPhone"
        var loggedInSince = Date().addingTimeInterval(-60 * 60 * 3)
    }

    enum Action {
        case dismiss
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismiss:
                return .run { _ in await dismiss(animation: .easeInOut) }
            }
        }
    }
}

struct SecurityView: View {
    var store: StoreOf<SecurityFeature>

    var body: some View {
        Group {
            Rectangle()
                .fill(Color.black.opacity(0.25))
                .transition(.opacity)
                .ignoresSafeArea()
                .zIndex(1)
                .onTapGesture {
                    store.send(.dismiss, animation: .easeInOut)
                }

            VStack {
                WithViewStore(store) { $0 } content: { viewStore in
                    VStack(alignment: .leading, spacing: 16) {
                        Label(viewStore.location, systemImage: "mappin.and.ellipse")
                        Label(viewStore.name, systemImage: "person")
                        Label(viewStore.deviceName, systemImage: "iphone")
                        Label(title: {
                            VStack(alignment: .leading) {
                                Text("Eingeloggt seit")
                                Text(viewStore.loggedInSince.description)
                                    .font(.footnote)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }, icon: { Image(systemName: "checkmark") })

                        HStack {
                            Spacer()

                            Button {
                                store.send(.dismiss, animation: .easeInOut)
                            } label: {
                                Text("schließen")
                            }
                            .buttonStyle(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .padding()
                .background(Colors.systemBackground)
                .cornerRadius(32)
                .padding()

                Spacer()
            }
            .transition(.move(edge: .top))
            .zIndex(2)
        }
        .frame(maxHeight: .infinity)
    }
}

struct SecurityViewPreviewProvider: PreviewProvider {
    static var previews: some View {
        ZStack {
            SecurityView(store: .init(initialState: .init()) {
                SecurityFeature()
            })
        }
    }
}
