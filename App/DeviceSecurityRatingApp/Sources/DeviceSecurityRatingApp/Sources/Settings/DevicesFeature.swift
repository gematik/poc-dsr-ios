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
import IdentifiedCollections
import OpenAPIClientAttest
import SwiftUI

struct DevicesFeature: Reducer {
    struct State: Equatable {
        var devices: IdentifiedArrayOf<Device> = []
        var deletionRunning = false
    }

    enum Action: Equatable {
        case load
        case devicesReceived([OpenAPIClientAttest.Components.Schemas.DeviceRegistration])
        case deleteDevices(IndexSet)
    }

    @Dependency(\.trustService) var trustService

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                return .run { send in
                    do {
                        let devices = try await trustService.getDevices(for: "X114428530")
                        await send(.devicesReceived(devices))
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            case let .devicesReceived(devices):
                state.devices = IdentifiedArray(uniqueElements: devices.map(Device.init(registration:)))
                state.deletionRunning = false
                return .none
            case let .deleteDevices(indexSet):
                let devicesToDelete = indexSet.map { offset in
                    state.devices[offset]
                }
                state.devices.remove(atOffsets: indexSet)
                state.deletionRunning = true

                return .run { send in
                    do {
                        for device in devicesToDelete {
                            let deviceIdentifier = device.registration.deviceIdentifier.replacingOccurrences(
                                of: "+",
                                with: "%2B"
                            )
                            try await trustService.deleteDevice(
                                userIdentifier: "X114428530",
                                deviceIdentifier: deviceIdentifier
                            )
                        }
                    } catch {
                        // Error Handling
                    }

                    do {
                        let devices = try await trustService.getDevices(for: "X114428530")
                        await send(.devicesReceived(devices))
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

struct DevicesView: View {
    var store: StoreOf<DevicesFeature>

    @ObservedObject var viewStore: ViewStoreOf<DevicesFeature>

    init(store: StoreOf<DevicesFeature>) {
        self.store = store
        viewStore = ViewStore(store) { $0 }
    }

    var body: some View {
        VStack {
            List {
                ForEach(viewStore.devices) { device in
                    VStack {
                        Text(device.name)

                        Text(device.type)
                            .font(.footnote)
                            .foregroundColor(Colors.systemLabelSecondary)

                        Text(device.createdAt.description)
                            .font(.footnote)
                            .foregroundColor(Colors.systemLabelSecondary)
                    }
                }
                .onDelete(perform: delete(at:))
            }
            .disabled(viewStore.deletionRunning)
            .overlay {
                if viewStore.deletionRunning {
                    VStack {
                        Spacer()
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
                        Spacer()
                    }.background(.black.opacity(0.5))
                }
            }
        }
        .navigationTitle("Devices")
        .onAppear {
            viewStore.send(.load)
        }
    }

    func delete(at offsets: IndexSet) {
        viewStore.send(.deleteDevices(offsets))
    }
}

struct Device: Identifiable, Equatable {
    let id: UUID
    let registration: OpenAPIClientAttest.Components.Schemas.DeviceRegistration

    init(registration: OpenAPIClientAttest.Components.Schemas.DeviceRegistration) {
        @Dependency(\.uuid) var uuidGenerator

        id = uuidGenerator()
        self.registration = registration
    }

    var name: String {
        registration.deviceIdentifier
    }

    var type: String {
        switch registration.deviceType {
        case .IOS:
            return "iOS"
        case .ANDROID:
            return "Android"
        case let .undocumented(value):
            return value
        }
    }

    var createdAt: Date {
        registration.createdAt
    }
}
