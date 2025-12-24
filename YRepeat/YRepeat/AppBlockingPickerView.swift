//
//  AppBlockingPickerView.swift
//  YRepeat
//
//  Created for App Blocking feature
//

#if DEBUG
import SwiftUI
import FamilyControls

struct AppBlockingPickerView: View {
    @ObservedObject var manager: AppBlockingManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selection: FamilyActivitySelection

    init(manager: AppBlockingManager) {
        self.manager = manager
        _selection = State(initialValue: manager.selectedApps)
    }

    var body: some View {
        ZStack {
            // Theme-aware background
            LiquidBackgroundView()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }

                    Spacer()

                    Text("Select Apps")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        manager.selectedApps = selection
                        manager.saveSettings()
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 40)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Instructions
                VStack(spacing: 12) {
                    Text("Choose apps that will remain accessible during blocking time.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Text("All other apps will be blocked.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

                // Family Activity Picker
                FamilyActivityPicker(selection: $selection)
                    .padding(.horizontal, 20)
            }
        }
    }
}
#endif
