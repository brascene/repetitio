//
//  CalendarHeaderComponents.swift
//  YRepeat
//
//  Created for Calendar feature
//

import SwiftUI

struct CalendarHeaderView: View {
    @Binding var isMenuShowing: Bool
    @EnvironmentObject var themeManager: ThemeManager
    let onAdd: () -> Void
    let onDeleteAll: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                MenuButton(isMenuShowing: $isMenuShowing)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: themeManager.backgroundColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)

                        Image(systemName: "calendar")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Calendar")
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
                
                HStack(spacing: 8) {
                    Button(action: onDeleteAll) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red.opacity(0.9))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            )
                    }
                    
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }
}

struct CalendarSegmentedControl: View {
    @Binding var selectedFilter: EventFilter
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EventFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedFilter == filter {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.15))
                                        .matchedGeometryEffect(id: "filterBackground", in: namespace)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @Namespace private var namespace
}

