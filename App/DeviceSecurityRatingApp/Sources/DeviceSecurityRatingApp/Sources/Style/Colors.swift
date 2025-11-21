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

import SwiftUI

// swiftlint:disable missing_docs

public enum Colors {
    // accent colors
    public static let primary: Color = primary600
    public static let secondary = Color(.systemGray6)
    public static let tertiary: Color = primary100

    // colors used for text
    public static let text = Color(.label)
    public static let textSecondary = Color(.secondaryLabel)
    public static let textTertiary = Color(.white)

    // colors used for screen backgrounds
    public static let backgroundNeutral = Color(.systemBackground)
    public static let backgroundSecondary = Color(.secondarySystemBackground)

    public static let alertNegativ = red600
    public static let alertPositiv = secondary600

    public static let starYellow = Color.yellow

    public static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    public static let separator = Color(UIColor.separator)
    public static let blurOverlayColor = Color.black.opacity(0.6)
}

extension Colors {
    // disabled
    public static let disabled = Color("disabled", bundle: .module)
    // primary == blue
    public static let primary900 = Color("primary900", bundle: .module)
    public static let primary800 = Color("primary800", bundle: .module)
    public static let primary700 = Color("primary700", bundle: .module)
    public static let primary600 = Color("primary600", bundle: .module)
    public static let primary500 = Color("primary500", bundle: .module)
    public static let primary400 = Color("primary400", bundle: .module)
    public static let primary300 = Color("primary300", bundle: .module)
    public static let primary200 = Color("primary200", bundle: .module)
    public static let primary100 = Color("primary100", bundle: .module)
    // secondary == green
    public static let secondary900 = Color("secondary900", bundle: .module)
    public static let secondary800 = Color("secondary800", bundle: .module)
    public static let secondary700 = Color("secondary700", bundle: .module)
    public static let secondary600 = Color("secondary600", bundle: .module)
    public static let secondary500 = Color("secondary500", bundle: .module)
    public static let secondary400 = Color("secondary400", bundle: .module)
    public static let secondary300 = Color("secondary300", bundle: .module)
    public static let secondary200 = Color("secondary200", bundle: .module)
    public static let secondary100 = Color("secondary100", bundle: .module)
    // red
    public static let red900 = Color("red900", bundle: .module)
    public static let red800 = Color("red800", bundle: .module)
    public static let red700 = Color("red700", bundle: .module)
    public static let red600 = Color("red600", bundle: .module)
    public static let red500 = Color("red500", bundle: .module)
    public static let red400 = Color("red400", bundle: .module)
    public static let red300 = Color("red300", bundle: .module)
    public static let red200 = Color("red200", bundle: .module)
    public static let red100 = Color("red100", bundle: .module)
    // yellow
    public static let yellow900 = Color("yellow900", bundle: .module)
    public static let yellow800 = Color("yellow800", bundle: .module)
    public static let yellow700 = Color("yellow700", bundle: .module)
    public static let yellow600 = Color("yellow600", bundle: .module)
    public static let yellow500 = Color("yellow500", bundle: .module)
    public static let yellow400 = Color("yellow400", bundle: .module)
    public static let yellow300 = Color("yellow300", bundle: .module)
    public static let yellow200 = Color("yellow200", bundle: .module)
    public static let yellow100 = Color("yellow100", bundle: .module)
}

extension Colors {
    // system gray colors
    public static let systemGray = Color(UIColor.systemGray)
    public static let systemGray2 = Color(UIColor.systemGray2)
    public static let systemGray3 = Color(UIColor.systemGray3)
    public static let systemGray4 = Color(UIColor.systemGray4)
    public static let systemGray5 = Color(UIColor.systemGray5)
    public static let systemGray6 = Color(UIColor.systemGray6)
    // system background colors
    public static let systemBackground = Color(UIColor.systemBackground)
    public static let systemBackgroundSecondary = Color(UIColor.secondarySystemBackground)
    public static let systemBackgroundTertiary = Color(UIColor.tertiarySystemBackground)
    // system fill colors
    public static let systemFill = Color(UIColor.systemFill)
    public static let systemFillSecondary = Color(UIColor.secondarySystemFill)
    public static let systemFillTertiary = Color(UIColor.tertiarySystemFill)
    public static let systemFillQuarternary = Color(UIColor.quaternarySystemFill)
    // label colors
    public static let systemLabel = Color(UIColor.label)
    public static let systemLabelSecondary = Color(UIColor.secondaryLabel)
    public static let systemLabelTertiary = Color(UIColor.tertiaryLabel)
    public static let systemLabelQuarternary = Color(UIColor.quaternaryLabel)
    // colors that are not dynamic
    public static let systemColorWhite = Color.white
    public static let systemColorBlack = Color.black
    public static let systemColorClear = Color.clear
}

// swiftlint:enable missing_docs
