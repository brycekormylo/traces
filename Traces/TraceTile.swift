//
//  TraceTile.swift
//  Traces
//
//  Created by Bryce on 5/19/23.
//

import SwiftUI
import MapKit
import PopupView

struct TraceTile: View {
    
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var supabaseManager = SupabaseManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @State var username: String = ""
    @State var shouldPresentOptions: Bool = false
    @State var shouldPresentEditSheet: Bool = false
    @State var userHasOwnership: Bool = false
    @State var deleteConfirmed: Bool = false
    var trace: Trace
    
    var body: some View {
        VStack {
            buildTileBody()
                .frame(height: 180)
                .padding(.horizontal)
            if shouldPresentOptions {
                buildOptions()
                    .transition(.move(edge: self.shouldPresentOptions ? .trailing : .leading))
                    .frame(height: 120)
            }
        }
        .frame(height: self.shouldPresentOptions ? 300 : 180)
        .background(themeManager.theme.background)
        .animation(
            .interactiveSpring(response: 0.45, dampingFraction: 0.8, blendDuration: 0.69), value: self.shouldPresentOptions)

    }
    
    private func buildTileBody() -> some View {
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
                        Button(action: {
                            shouldPresentOptions.toggle()
                            deleteConfirmed = false
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(themeManager.theme.text.opacity(0.6))
                                .padding(6)
                                .frame(width: 24, height: 24)
                        }
                        Spacer()
                        Text(trace.locationName)
                            .foregroundColor(themeManager.theme.text)
                        if !userHasOwnership {
                            Text("@\(username)")
                                .foregroundColor(themeManager.theme.text.opacity(0.4))
                                .font(.caption)
                        }
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
    
    private func buildOptions() -> some View {
        HStack {
            Spacer()
            VStack() {
                Button(action: {
                    notificationManager.sendNotification(.linkCopied)
                    shouldPresentOptions.toggle()
                }) {
                    settingsItem(title: "Share", icon: "square.and.arrow.up")
                }
                
                if userHasOwnership {
                    Button(action: {
                        shouldPresentOptions.toggle()
                        TraceEditPopup(trace: trace).showAndStack()
                    }) {
                        settingsItem(title: "Edit", icon: "pencil")
                    }
                    Button(action: {
                        print(deleteConfirmed)
                        if !deleteConfirmed {
                            deleteConfirmed = true
                        } else {
                            notificationManager.sendNotification(.traceDeleted)
                            supabaseManager.deleteTrace(trace)
                            shouldPresentOptions.toggle()
                            deleteConfirmed = false
                        }
                    }) {
                        settingsItem(title: deleteConfirmed ? "Are you sure?" : "Delete", icon: deleteConfirmed ? "trash" : "questionmark", isCritical: true)
                            .animation(.easeInOut, value: deleteConfirmed)
                    }

                } else {
                    Button(action: {
                        notificationManager.sendNotification(.traceSaved)
                        shouldPresentOptions.toggle()
                    }) {
                        settingsItem(title: "Save", icon: "square.and.arrow.down")
                    }
                    Button(action: {
                        notificationManager.sendNotification(.traceReported)
                        shouldPresentOptions.toggle()
                    }) {
                        settingsItem(title: "Report", icon: "exclamationmark.bubble", isCritical: true)
                    }
                }

            }
        }
    }
    
    private func settingsItem(title: String, icon: String, isCritical: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Circle()
                .fill(.clear)
                .overlay(
                    Image(systemName: icon)
                )
        }
        .foregroundColor(isCritical ? .red.opacity(0.8) : themeManager.theme.text.opacity(0.8))
        .frame(width: 180)
        .padding(.trailing, 24)
    }
    
    private func getFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: supabaseManager.convertFromTimestamptzDate(trace.creationDate))
        return dateString
    }
}
