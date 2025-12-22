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
    
    // Animation state
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Premium background
            LiquidBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                CalendarHeaderView(
                    onAdd: { showingAddEvent = true },
                    onDeleteAll: { showingDeleteAllConfirmation = true }
                )
                .zIndex(1)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Filter Segmented Control
                        CalendarSegmentedControl(selectedFilter: $selectedFilter)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        if filteredEvents.isEmpty {
                            emptyStateView
                                .transition(.opacity)
                                .padding(.top, 40)
                        } else {
                            eventsList
                        }
                    }
                    .padding(.bottom, 100)
                }
                .scrollContentBackground(.hidden)
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
                withAnimation {
                    manager.deletePastEvents()
                }
            }
            Button("Delete All Events", role: .destructive) {
                withAnimation {
                    manager.deleteAllEvents()
                }
            }
        } message: {
            Text("Choose what to delete:\n\n• Delete Past Events: Removes only past events\n• Delete All Events: Removes all events (past and upcoming)")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Events List
    
    private var eventsList: some View {
        LazyVStack(spacing: 20) {
            ForEach(filteredEvents) { event in
                CalendarEventCardView(
                    event: event,
                    isPastEvent: selectedFilter == .past,
                    onAddTodo: {
                        selectedEvent = event
                    },
                    onToggleTodo: { todo in
                        manager.toggleTodoCompletion(todoId: todo.id)
                    },
                    onEditTodo: { todo in
                        editingTodo = todo
                    },
                    onDeleteTodo: { todo in
                        withAnimation {
                            manager.deleteTodo(todo.id)
                        }
                    },
                    onDeleteEvent: {
                        withAnimation {
                            manager.deleteEvent(event.id)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Filtered Events
    
    private var filteredEvents: [CalendarEvent] {
        let today = Calendar.current.startOfDay(for: Date())
        
        switch selectedFilter {
        case .upcoming:
            return manager.events
                .filter { event in
                    let eventDate = Calendar.current.startOfDay(for: event.date)
                    return eventDate >= today
                }
                .sorted { $0.date < $1.date }
        case .past:
            return manager.events
                .filter { event in
                    let eventDate = Calendar.current.startOfDay(for: event.date)
                    return eventDate < today
                }
                // Latest first (most recent past event at the top)
                .sorted { $0.date > $1.date }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Image(systemName: selectedFilter == .upcoming ? "calendar.badge.plus" : "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animateContent ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateContent)
                }
                
                VStack(spacing: 12) {
                    Text(selectedFilter == .upcoming ? "No Upcoming Events" : "No Past Events")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(selectedFilter == .upcoming 
                         ? "Plan ahead by adding new events and tasks to your calendar."
                         : "Your completed events history will appear here.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            if selectedFilter == .upcoming {
                Button {
                    showingAddEvent = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                        Text("Add First Event")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    CalendarView()
        .environmentObject(CalendarManager())
}
