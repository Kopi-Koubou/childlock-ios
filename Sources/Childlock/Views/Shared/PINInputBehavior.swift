import SwiftUI

public extension View {
    @ViewBuilder
    func pinInputBehavior() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
        #else
        self
        #endif
    }
}
