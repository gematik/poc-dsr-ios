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

import SwiftUI

/// Wrapped `TextField` applying styles and padding suited for using within `SectionContainer`.
public struct FormTextField: View {
    var titleKey: LocalizedStringKey

    @Binding var text: String

    public init(_ titleKey: LocalizedStringKey, text: Binding<String>) {
        self.titleKey = titleKey
        _text = text
    }

    public var body: some View {
        TextField(titleKey, text: $text)
            .font(.body.bold())
            .padding(16)
            .background(Colors.systemGray6)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Colors.systemGray5, lineWidth: 1.0))
            .cornerRadius(8)
    }
}

struct SectionContainerTextFieldStyle_Preview: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                FormTextField("Text", text: .constant(""))

                FormTextField("Text", text: .constant("somestring"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
