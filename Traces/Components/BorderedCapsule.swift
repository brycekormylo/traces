//
//  BorderedCapsule.swift
//  Traces
//
//  Created by Bryce on 7/22/23.
//

import SwiftUI

struct BorderedCapsule: View {
    
    @EnvironmentObject var theme: ThemeController
    
    var hasColoredBorder: Bool = false
    var hasThinBorder: Bool = false
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(theme.backgroundAccent)
            Capsule()
                .strokeBorder(hasColoredBorder ? theme.buttonBorder : theme.border, lineWidth: hasThinBorder ? 1.4 : 2)
        }
    }
}
