//
//  ErrorText.swift
//  Traces
//
//  Created by Bryce on 6/8/23.
//

import SwiftUI

struct ErrorText: View {
    let error: Error
    
    init(_ error: Error) {
        self.error = error
    }
    
    var body: some View {
        Text(String(describing: error))
            .foregroundColor(.red)
            .font(.footnote)
    }
}

struct ErrorText_Previews: PreviewProvider {
    static var previews: some View {
        ErrorText(NSError())
    }
}

