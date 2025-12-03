//
//  CalendarView.swift
//  YRepeat
//
//  Created for Calendar feature
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var manager: CalendarManager
    @State private var showingAddEvent = false
    @State private var selectedDate = Date()
    @State private var selectedEvent: CalendarEvent?
    @State private var showingAddTodo = false
    @State private var editingTodo: CalendarTodo?
    @State private var editingTodoTitle = ""
    @State private var showingEditAlert = false
    
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
                
                // Content
                if manager.events.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddCalendarEventView(manager: manager, selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showingAddTodo) {
            if let event = selectedEvent {
                AddCalendarTodoView(manager: manager, event: event)
            }
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
                
                Button {
                    showingAddEvent = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(manager.events) { event in
                    CalendarEventCard(
                        event: event,
                        onAddTodo: {
                            selectedEvent = event
                            showingAddTodo = true
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
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("No Calendar Events Yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Add your first calendar event\nto start tracking")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                }
            }
            
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
            
            Spacer()
        }
    }
}

// MARK: - Calendar Event Card

struct CalendarEventCard: View {
    let event: CalendarEvent
    let onAddTodo: () -> Void
    let onToggleTodo: (CalendarTodo) -> Void
    let onEditTodo: (CalendarTodo) -> Void
    let onDeleteTodo: (CalendarTodo) -> Void
    let onDeleteEvent: () -> Void
    
    @State private var showingActionSheet = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateFormatter.string(from: event.date))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(relativeDateString(from: event.date))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            onAddTodo()
                        } label: {
                            Label("Add Todo", systemImage: "plus")
                        }
                        
                        if !event.todos.isEmpty {
                            Divider()
                            
                            Button(role: .destructive) {
                                onDeleteEvent()
                            } label: {
                                Label("Delete Event", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Todos
                if event.todos.isEmpty {
                    Button {
                        onAddTodo()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Todo")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(event.todos) { todo in
                            TodoRow(
                                todo: todo,
                                onToggle: { onToggleTodo(todo) },
                                onEdit: { onEditTodo(todo) },
                                onDelete: { onDeleteTodo(todo) }
                            )
                        }
                    }
                }
            }
        }
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
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(todo.isCompleted ? .green : .white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo Title
            Text(todo.title)
                .font(.system(size: 16, weight: todo.isCompleted ? .medium : .regular))
                .foregroundColor(todo.isCompleted ? .white.opacity(0.6) : .white)
                .strikethrough(todo.isCompleted)
            
            Spacer()
            
            // Menu - Edit and Delete options for this todo
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(todo.isCompleted ? 0.05 : 0.1))
        )
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
                
                ScrollView {
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
                                .onAppear {
                                    // Focus the text field when view appears
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        // TextField will be focused automatically in iOS
                                    }
                                }
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
                    }
                }
                    
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


#Preview {
    CalendarView()
        .environmentObject(CalendarManager())
}

