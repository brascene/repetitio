//
//  CalendarEventCardView.swift
//  YRepeat
//
//  Created for Calendar feature
//

import SwiftUI

struct CalendarEventCardView: View {
    let event: CalendarEvent
    let isPastEvent: Bool
    let onAddTodo: () -> Void
    let onToggleTodo: (CalendarTodo) -> Void
    let onEditTodo: (CalendarTodo) -> Void
    let onDeleteTodo: (CalendarTodo) -> Void
    let onDeleteEvent: () -> Void
    
    @State private var isPressed = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(event.date)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            HStack(alignment: .top, spacing: 16) {
                // Date Badge
                VStack(spacing: 4) {
                    Text(dayNumber)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isToday ? [.white, .cyan] : [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(monthAbbreviation)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                }
                .frame(width: 56, height: 64)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isToday
                                        ? [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]
                                        : [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: isToday ? Color.blue.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
                
                // Date Info & Metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateFormatter.string(from: event.date))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Label(relativeDateString(from: event.date), systemImage: isToday ? "sparkles" : "clock")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(isToday ? .cyan : .white.opacity(0.6))
                        
                        if !event.todos.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 12))
                                Text("\(completedTodosCount)/\(event.todos.count)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.top, 4)
                
                Spacer()
                
                // Action Menu
                Menu {
                    if !isPastEvent {
                        Button(action: onAddTodo) {
                            Label("Add Todo", systemImage: "plus")
                        }
                    }
                    
                    Button(role: .destructive, action: onDeleteEvent) {
                        Label("Delete Event", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            
            // Divider if there are todos
            if !event.todos.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 16)
            }
            
            // Todos List
            if !event.todos.isEmpty {
                VStack(spacing: 0) {
                    ForEach(event.todos) { todo in
                        CalendarTodoRow(
                            todo: todo,
                            isPastEvent: isPastEvent,
                            onToggle: { onToggleTodo(todo) },
                            onEdit: { onEditTodo(todo) },
                            onDelete: { onDeleteTodo(todo) }
                        )
                        
                        // Separator between items (except last)
                        if todo.id != event.todos.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 52) // Align with text
                        }
                    }
                }
                .padding(.vertical, 8)
            } else if !isPastEvent {
                // Empty State Action
                Button(action: onAddTodo) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add first todo")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(16)
                    .contentShape(Rectangle())
                }
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.02))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isToday ? 0.25 : 0.15),
                            Color.white.opacity(isToday ? 0.1 : 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 2) // Slight margin for shadow
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            isPressed = pressing
        }) {
            // Action handled by menu
        }
    }
    
    // MARK: - Helpers
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: event.date)
    }
    
    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.date)
    }
    
    private var completedTodosCount: Int {
        event.todos.filter { $0.isCompleted }.count
    }
    
    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        
        let components = calendar.dateComponents([.day], from: now, to: date)
        if let day = components.day {
            if day < 0 { return "\(-day) days ago" }
            return "In \(day) days"
        }
        return ""
    }
}

// MARK: - Todo Row Component

struct CalendarTodoRow: View {
    let todo: CalendarTodo
    let isPastEvent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            todo.isCompleted ? Color.green.opacity(0.6) : Color.white.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if todo.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Title
            Text(todo.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(todo.isCompleted ? .white.opacity(0.5) : .white)
                .strikethrough(todo.isCompleted, color: .white.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Context Menu
            Menu {
                if !isPastEvent {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            todo.isCompleted ? Color.green.opacity(0.05) : Color.clear
        )
    }
}

