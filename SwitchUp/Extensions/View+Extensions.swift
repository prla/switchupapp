//
//  View+Extensions.swift
//  SwitchUp
//
//  Created by Paulo André on 13.07.25.
//

import SwiftUI
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
