//
//  CalendarView.swift
//  YRepeat
//
//  Created for Calendar feature
//

import SwiftUI

enum EventFilter: String, CaseIterable {
    case upcoming = "Upcoming"
    case past = "Past"
}

struct CalendarView: View {
    @EnvironmentObject var manager: CalendarManager
    @State private var showingAddEvent = false
    @State private var selectedDate = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var editingTodo: CalendarTodo?
    @State private var editingTodoTitle = ""
    @State private var showingEditAlert = false
    @State private var selectedFilter: EventFilter = .upcoming
    @State private var showingDeleteAllConfirmation = false
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Segmented Control
                segmentedControlView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Content
                if filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddCalendarEventView(manager: manager, selectedDate: $selectedDate)
        }
        .sheet(item: $selectedEvent) { event in
            AddCalendarTodoView(manager: manager, event: event)
        }
        .alert("Edit Todo", isPresented: $showingEditAlert) {
            TextField("Todo title", text: $editingTodoTitle)
            Button("Cancel", role: .cancel) {
                editingTodo = nil
                editingTodoTitle = ""
            }
            Button("Save") {
                if let todo = editingTodo, !editingTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    manager.updateTodo(todoId: todo.id, title: editingTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                    editingTodo = nil
                    editingTodoTitle = ""
                }
            }
            .disabled(editingTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Edit the todo title")
        }
        .onChange(of: editingTodo) { oldValue, newValue in
            if newValue != nil {
                showingEditAlert = true
                if let todo = newValue {
                    editingTodoTitle = todo.title
                }
            }
        }
        .alert("Delete Events", isPresented: $showingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Past Events", role: .destructive) {
                manager.deletePastEvents()
            }
            Button("Delete All Events", role: .destructive) {
                manager.deleteAllEvents()
            }
        } message: {
            Text("Choose what to delete:\n\n• Delete Past Events: Removes only past events\n• Delete All Events: Removes all events (past and upcoming)")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Calendar")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        showingDeleteAllConfirmation = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControlView: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(EventFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Filtered Events
    
    private var filteredEvents: [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        
        switch selectedFilter {
        case .upcoming:
            return manager.events.filter { event in
                let eventDate = Calendar.current.startOfDay(for: event.date)
                return eventDate >= today
            }
        case .past:
            return manager.events.filter { event in
                let eventDate = Calendar.current.startOfDay(for: event.date)
                return eventDate < today
            }
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(filteredEvents) { event in
                    CalendarEventCard(
                        event: event,
                        isPastEvent: selectedFilter == .past,
                        onAddTodo: {
                            selectedEvent = event
                        },
                        onToggleTodo: { todo in
                            manager.toggleTodoCompletion(todoId: todo.id)
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        },
                        onEditTodo: { todo in
                            editingTodo = todo
                        },
                        onDeleteTodo: { todo in
                            manager.deleteTodo(todo.id)
                        },
                        onDeleteEvent: {
                            manager.deleteEvent(event.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: selectedFilter == .upcoming ? "calendar.badge.plus" : "calendar.badge.minus")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text(selectedFilter == .upcoming ? "No Upcoming Events" : "No Past Events")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(selectedFilter == .upcoming 
                         ? "Add your first calendar event\nto start tracking"
                         : "Completed events will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                }
            }
            
            if selectedFilter == .upcoming {
                Button {
                    showingAddEvent = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Event")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Calendar Event Card

struct CalendarEventCard: View {
    let event: CalendarEvent
    let isPastEvent: Bool
    let onAddTodo: () -> Void
    let onToggleTodo: (CalendarTodo) -> Void
    let onEditTodo: (CalendarTodo) -> Void
    let onDeleteTodo: (CalendarTodo) -> Void
    let onDeleteEvent: () -> Void
    
    @State private var showingActionSheet = false
    @State private var isPressed = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(event.date)
    }
    
    private var gradientColors: [Color] {
        if isToday {
            return [Color.blue.opacity(0.3), Color.purple.opacity(0.2), Color.cyan.opacity(0.15)]
        } else if isPastEvent {
            return [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]
        } else {
            return [Color.blue.opacity(0.25), Color.purple.opacity(0.15), Color.indigo.opacity(0.1)]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header with Gradient Background
            HStack(alignment: .top, spacing: 16) {
                // Date Badge with Gradient
                VStack(spacing: 6) {
                    Text(dayNumber)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isToday ? [.white, .cyan] : [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(monthAbbreviation)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .frame(width: 60)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // Animated gradient background
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: isToday 
                                        ? [Color.blue.opacity(0.4), Color.purple.opacity(0.3)]
                                        : [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Glass effect overlay
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isToday ? Color.blue.opacity(0.3) : Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // Date Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(dateFormatter.string(from: event.date))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    HStack(spacing: 6) {
                        Image(systemName: isToday ? "sparkles" : "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: isToday 
                                        ? [.cyan, .blue]
                                        : [.white.opacity(0.7), .white.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(relativeDateString(from: event.date))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    
                    // Todo count badge
                    if !event.todos.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("\(completedTodosCount)/\(event.todos.count)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                }
                
                Spacer()
                
                // Enhanced Menu Button
                Menu {
                    if !isPastEvent {
                        Button {
                            onAddTodo()
                        } label: {
                            Label("Add Todo", systemImage: "plus.circle.fill")
                        }
                    }
                    
                    if !event.todos.isEmpty {
                        if !isPastEvent {
                            Divider()
                        }
                        
                        Button(role: .destructive) {
                            onDeleteEvent()
                        } label: {
                            Label("Delete Event", systemImage: "trash.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.9), .white.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(8)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Glass blur effect
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                }
            )
            
            // Todos Section
            if event.todos.isEmpty {
                if !isPastEvent {
                    Button {
                        onAddTodo()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Add Todo")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.15),
                                                Color.cyan.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.4),
                                            Color.cyan.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                } else {
                    HStack {
                        Spacer()
                        Text("No todos")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(event.todos) { todo in
                        TodoRow(
                            todo: todo,
                            isPastEvent: isPastEvent,
                            onToggle: { onToggleTodo(todo) },
                            onEdit: { onEditTodo(todo) },
                            onDelete: { onDeleteTodo(todo) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(
            ZStack {
                // Base glass effect
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                
                // Gradient overlay
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: isToday ? Color.blue.opacity(0.3) : Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
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
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if date < now {
            let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(daysAgo) days ago"
        } else {
            let daysUntil = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            return "In \(daysUntil) days"
        }
    }
}

// MARK: - Todo Row

struct TodoRow: View {
    let todo: CalendarTodo
    let isPastEvent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Enhanced Checkbox with Animation
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            } label: {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: todo.isCompleted
                                    ? [Color.green.opacity(0.6), Color.mint.opacity(0.4)]
                                    : [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 28, height: 28)
                    
                    // Inner fill with gradient
                    if todo.isCompleted {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo Title with Enhanced Typography
            Text(todo.title)
                .font(.system(size: 16, weight: todo.isCompleted ? .medium : .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: todo.isCompleted
                            ? [Color.white.opacity(0.5), Color.white.opacity(0.3)]
                            : [Color.white, Color.white.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .strikethrough(todo.isCompleted, color: .white.opacity(0.3))
                .lineLimit(2)
            
            Spacer()
            
            // Enhanced Menu Button
            Menu {
                if !isPastEvent {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil.circle.fill")
                    }
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash.circle.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                    )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: todo.isCompleted
                                ? [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ]
                                : [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.08)
                                ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Subtle glow for active todos
                if !todo.isCompleted {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Add Calendar Event View

struct AddCalendarEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .colorScheme(.dark)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding()
                    
                    Button {
                        manager.addEvent(date: selectedDate)
                        dismiss()
                    } label: {
                        Text("Add Event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Calendar Todo View

struct AddCalendarTodoView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: CalendarManager
    let event: CalendarEvent
    @State private var todoTitle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Todo Title")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter todo title (e.g., Take 250mg)", text: $todoTitle)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .autocapitalization(.sentences)
                            .submitLabel(.done)
                            .onSubmit {
                                let trimmedTitle = todoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedTitle.isEmpty {
                                    manager.addTodo(to: event.id, title: trimmedTitle)
                                    dismiss()
                                }
                            }
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button {
                        let trimmedTitle = todoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedTitle.isEmpty {
                            manager.addTodo(to: event.id, title: trimmedTitle)
                            dismiss()
                        }
                    } label: {
                        Text("Add Todo")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                    .disabled(todoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Add Todo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(CalendarManager())
}

