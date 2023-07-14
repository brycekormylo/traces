//
//  CustomTabBar.swift
//  Traces
//
//  Created by Bryce on 6/12/23.
//

import SwiftUI
import PopupView

enum Tab: String, Hashable, CaseIterable {
    case home = "house"
    case map = "globe.americas"
    case new = "plus"
    case profile = "person"
    case settings = "gearshape"
}

private let buttonDimen: CGFloat = 55

struct BackgroundHelper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            var parent = view.superview
            repeat {
                if parent?.backgroundColor != nil {
                    parent?.backgroundColor = UIColor.clear
                    break
                }
                parent = parent?.superview
            } while (parent != nil)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CustomTabBarView: View {
    
    @Binding var currentTab: Tab
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    
    var body: some View {
        HStack {
            TabBarButton(imageName: Tab.home.rawValue)
                .frame(width: buttonDimen, height: buttonDimen)
                .onTapGesture {
                    currentTab = .home
                }
            
            TabBarButton(imageName: Tab.map.rawValue)
                .frame(width: buttonDimen, height: buttonDimen)
                .onTapGesture {
                    currentTab = .map
                }
            
            buildNewTraceButton()

            
            TabBarButton(imageName: Tab.profile.rawValue)
                .frame(width: buttonDimen, height: buttonDimen)
                .onTapGesture {
                    currentTab = .profile
                }
            
            TabBarButton(imageName: Tab.settings.rawValue)
                .frame(width: buttonDimen, height: buttonDimen)
                .onTapGesture {
                    currentTab = .settings
                }
            
        }
        .padding(.horizontal, 12)
        .background(
            ZStack {
                Capsule(style: .circular)
                    .fill(themeManager.theme.backgroundAccent)
                Capsule(style: .circular)
                    .stroke(themeManager.theme.border, lineWidth: 2)
            }
        )
        .overlay {
            SelectedTabCircleView(currentTab: $currentTab)
        }
//        .shadow(color: themeManager.theme.text.opacity(0.4), radius: 6, x: 0, y: 6)
        .animation(
            .interactiveSpring(
                response: 0.34, dampingFraction: 0.69, blendDuration: 0.69),
            value: currentTab)
        
    }
}

extension CustomTabBarView {
    func buildNewTraceButton() -> some View {
        ZStack(alignment: .bottom) {
            Button(action: NewTracePopup().showAndStack) {
                Image(systemName: "plus")
                    .scaleEffect(1.4)
                    .frame(width: 48, height: 48)
                    .foregroundColor(themeManager.theme.text)
                    .background(RoundedRectangle(cornerRadius: 16).fill(themeManager.theme.button.opacity(0.6)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.theme.text, lineWidth: 2)
                    )
            }
        }
        .padding(12)
    }
}

private struct TabBarButton: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let imageName: String
    var body: some View {
        Image(systemName: imageName)
            .renderingMode(.template)
            .foregroundColor(themeManager.theme.text)
            .fontWeight(.bold)
            .scaleEffect(1)
    }
}

struct SelectedTabCircleView: View {
    
    @Binding var currentTab: Tab
    @ObservedObject var themeManager = ThemeManager.shared
    
    private var horizontalOffset: CGFloat {
        switch currentTab {
        case .home:
            return -135
        case .map:
            return -72
        case .new:
            return 0
        case .profile:
            return 72
        case .settings:
            return 135
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.theme.button)
                .frame(width: buttonDimen , height: buttonDimen)
            Circle()
                .stroke(themeManager.theme.text, lineWidth: 2)
                .frame(width: buttonDimen , height: buttonDimen)
            TabBarButton(imageName: "\(currentTab.rawValue).fill")
                .foregroundColor(themeManager.theme.text)
        }
        .offset(x: horizontalOffset)
    }
    
}

struct CustomTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBarView(currentTab: .constant(.home))
    }
}







