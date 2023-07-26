//
//  TraceTile.swift
//  Traces
//
//  Created by Bryce on 5/19/23.
//

import SwiftUI
import MapKit

struct TraceTile: View {
    
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var supabaseManager = SupabaseManager.shared
    @State var username: String = ""
    var trace: Trace
    
    var body: some View {
        HStack {
            MapBox(focalTrace: trace)
                .clipShape(RoundedRectangle(cornerRadius: 29))
                .frame(width: 144, height: 144)
                .padding(4)
                .background( BorderedRectangle() )
            Spacer()
            ZStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Spacer()
                        Text(trace.locationName)
                            .foregroundColor(themeManager.theme.text)
                        Text("@\(username)")
                            .foregroundColor(themeManager.theme.text.opacity(0.4))
                            .font(.caption)
                        Text(getFormattedDate())
                            .foregroundColor(themeManager.theme.text.opacity(0.6))
                            .font(.caption2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            username = await supabaseManager.getUsernameFromID(trace.userID)
        }
        .padding(8)
    }
    
    private func getFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: supabaseManager.convertFromTimestamptzDate(trace.creationDate))
        return dateString
    }
}
