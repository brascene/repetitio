//
//  CheckView.swift
//  YRepeat
//
//  Created for Check feature
//

import SwiftUI

struct CheckView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @StateObject private var manager = CheckBoxManager()

    @State private var showDeleteAlert = false
    @State private var selectedSections = 3
    @State private var selectedBoxes = 15

    var body: some View {
        ZStack {
            // Liquid background effect
            LiquidBackgroundView()
                .environmentObject(themeManager)

            VStack(spacing: 0) {
                // Header
                headerView

                if manager.hasStarted {
                    // Main Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Progress Card
                            progressCard

                            // Sections
                            ForEach(0..<manager.numberOfSections, id: \.self) { sectionIndex in
                                sectionView(for: sectionIndex)
                            }

                            // Delete All Button
                            deleteButton
                                .padding(.top, 16)
                                .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                } else {
                    // Configuration View
                    configurationView
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                MenuButton(isMenuShowing: $isMenuShowing)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: themeManager.backgroundColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)

                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Check")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Progress text
            if manager.hasStarted {
                Text("\(manager.checkedBoxes)/\(manager.totalBoxes) checked")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        GlassmorphicCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Progress")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(Int(manager.progress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: themeManager.backgroundColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * manager.progress, height: 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manager.progress)
                    }
                }
                .frame(height: 12)
            }
            .padding(20)
        }
    }

    // MARK: - Section View

    private func sectionView(for sectionIndex: Int) -> some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                // Section Header
                HStack {
                    Text("Section \(sectionIndex + 1)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    let sectionBoxes = manager.sections[safe: sectionIndex] ?? []
                    let checkedInSection = sectionBoxes.filter { $0.isChecked }.count
                    Text("\(checkedInSection)/\(manager.boxesPerSection)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Grid of Boxes
                let columns = gridColumns(for: manager.boxesPerSection)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(manager.sections[safe: sectionIndex] ?? []) { box in
                        checkBoxView(box: box)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - CheckBox View

    private func checkBoxView(box: CheckBox) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                manager.toggleBox(id: box.id)
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        box.isChecked
                            ? LinearGradient(
                                colors: themeManager.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                box.isChecked ? Color.clear : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .frame(height: 60)

                if box.isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: themeManager.backgroundColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Configure Your Checklist")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Set up the number of sections and boxes to get started")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 24) {
                    // Number of Sections
                    GlassmorphicCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Number of Sections")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { num in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedSections = num
                                    }
                                }) {
                                    Text("\(num)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedSections == num ? .white : .white.opacity(0.5))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(
                                            selectedSections == num
                                                ? LinearGradient(
                                                    colors: themeManager.backgroundColors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                  )
                                                : LinearGradient(
                                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                  )
                                        )
                                        .cornerRadius(12)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                }

                    // Boxes per Section
                    GlassmorphicCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Boxes per Section")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Picker("", selection: $selectedBoxes) {
                                ForEach([5, 10, 15, 20, 25, 30], id: \.self) { num in
                                    Text("\(num) boxes").tag(num)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }
                        .padding(20)
                    }

                    // Start Button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            manager.startWithConfiguration(sections: selectedSections, boxes: selectedBoxes)
                        }
                    }) {
                        ZStack {
                            // Base theme gradient
                            LinearGradient(
                                colors: themeManager.backgroundColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )

                            // White overlay to brighten
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            // Button content
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Checking")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .cornerRadius(16)
                        .shadow(color: themeManager.backgroundColors.first?.opacity(0.5) ?? .clear, radius: 20, x: 0, y: 10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Delete Button

    private var deleteButton: some View {
        Button(action: {
            showDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete All & Start Fresh")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .alert("Delete All Boxes?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    manager.deleteAll()
                }
            }
        } message: {
            Text("This will delete all boxes and reset your configuration. You can start fresh with new settings.")
        }
    }

    // MARK: - Helpers

    private func gridColumns(for boxCount: Int) -> [GridItem] {
        let columnsCount = min(boxCount, 5) // Max 5 columns
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnsCount)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CheckView(isMenuShowing: .constant(false))
        .environmentObject(ThemeManager())
}
