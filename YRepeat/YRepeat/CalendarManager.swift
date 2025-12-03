//
//  CalendarManager.swift
//  YRepeat
//
//  Created for Calendar feature
//

import Foundation
import Combine
import UIKit
internal import CoreData

struct CalendarEvent: Identifiable {
    let id: UUID
    let date: Date
    let createdAt: Date
    var todos: [CalendarTodo]
}

struct CalendarTodo: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    
    static func == (lhs: CalendarTodo, rhs: CalendarTodo) -> Bool {
        lhs.id == rhs.id
    }
}

class CalendarManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    private let notificationManager = NotificationManager.shared
    private var isUpdatingNotifications = false
    private var foregroundObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        
        // Request notification permissions
        notificationManager.requestAuthorization()
        
        loadEvents()
        prefillInitialDataIfNeeded()
        
        // Ensure notifications are set up correctly after loading
        updateNotificationsForNextEvent()
        
        // Setup app lifecycle observers to refresh notifications when app becomes active
        setupAppLifecycleObserver()
    }
    
    private func setupAppLifecycleObserver() {
        // Listen for app becoming active (foreground)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadEvents()
            self?.updateNotificationsForNextEvent()
        }
        
        // Also listen for app becoming active
        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadEvents()
            self?.updateNotificationsForNextEvent()
        }
    }
    
    // MARK: - CRUD Operations
    
    func addEvent(date: Date) {
        let entity = CalendarEventEntity(context: context)
        entity.id = UUID()
        entity.date = date
        entity.createdAt = Date()
        
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    func addTodo(to eventId: UUID, title: String) {
        guard let eventEntity = getEventEntity(for: eventId) else { return }
        
        let todoEntity = CalendarTodoEntity(context: context)
        todoEntity.id = UUID()
        todoEntity.title = title
        todoEntity.isCompleted = false
        todoEntity.createdAt = Date()
        todoEntity.event = eventEntity
        
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    func updateTodo(todoId: UUID, title: String) {
        guard let todoEntity = getTodoEntity(for: todoId) else { return }
        
        todoEntity.title = title
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    func toggleTodoCompletion(todoId: UUID) {
        guard let todoEntity = getTodoEntity(for: todoId) else { return }
        
        todoEntity.isCompleted.toggle()
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    func deleteEvent(_ eventId: UUID) {
        guard let entity = getEventEntity(for: eventId) else { return }
        
        context.delete(entity)
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    func deleteTodo(_ todoId: UUID) {
        guard let todoEntity = getTodoEntity(for: todoId) else { return }
        
        context.delete(todoEntity)
        try? context.save()
        loadEvents()
        
        // Update notifications to only schedule for next unchecked event
        updateNotificationsForNextEvent()
    }
    
    // MARK: - Notification Management
    
    /// Updates notifications to only schedule for the next upcoming unchecked event
    /// This method checks if notifications are already scheduled for the correct event to avoid unnecessary rescheduling
    private func updateNotificationsForNextEvent() {
        // Prevent concurrent updates to avoid race conditions
        guard !isUpdatingNotifications else {
            print("⚠️ Notification update already in progress, skipping...")
            return
        }
        
        isUpdatingNotifications = true
        
        // Find the next upcoming event with at least one incomplete todo
        let today = Calendar.current.startOfDay(for: Date())
        
        let nextEvent = events
            .filter { event in
                // Event date is today or in the future
                let eventDate = Calendar.current.startOfDay(for: event.date)
                guard eventDate >= today else { return false }
                
                // Event has at least one incomplete todo
                return !event.todos.isEmpty && event.todos.contains { !$0.isCompleted }
            }
            .sorted { $0.date < $1.date }
            .first
        
        guard let event = nextEvent,
              let firstIncompleteTodo = event.todos.first(where: { !$0.isCompleted }) else {
            // No upcoming unchecked events - cancel all notifications
            notificationManager.cancelAllNotifications()
            isUpdatingNotifications = false
            print("ℹ️ No upcoming unchecked events found - cancelled all notifications")
            return
        }
        
        // Check if notifications are already scheduled for this event
        notificationManager.hasNotificationsScheduled(for: event.id) { [weak self] hasNotifications in
            guard let self = self else { return }
            
            if hasNotifications {
                self.isUpdatingNotifications = false
                print("✅ Notifications already scheduled for next event: \(event.date) - \(firstIncompleteTodo.title) - skipping reschedule")
                return
            }
            
            // Notifications not scheduled or scheduled for different event - cancel all and reschedule
            self.notificationManager.cancelAllNotifications()
            self.notificationManager.scheduleNotifications(
                for: event.id,
                date: event.date,
                todoTitle: firstIncompleteTodo.title
            )
            self.isUpdatingNotifications = false
            print("✅ Scheduled notifications for next event: \(event.date) - \(firstIncompleteTodo.title)")
        }
    }
    
    // MARK: - Prefill Data
    
    private func prefillInitialDataIfNeeded() {
        let hasPrefilledKey = "calendar_prefilled"
        if UserDefaults.standard.bool(forKey: hasPrefilledKey) {
            return // Already prefilled
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Start date: November 15, 2025
        var startComponents = DateComponents()
        startComponents.year = 2025
        startComponents.month = 11
        startComponents.day = 15
        guard let startDate = calendar.date(from: startComponents) else { return }
        
        // End date: June 7, 2026
        var endComponents = DateComponents()
        endComponents.year = 2026
        endComponents.month = 6
        endComponents.day = 7
        guard let endDate = calendar.date(from: endComponents) else { return }
        
        // Create events every 4 days
        var currentDate = startDate
        while currentDate <= endDate {
            // Create event
            let eventEntity = CalendarEventEntity(context: context)
            eventEntity.id = UUID()
            eventEntity.date = currentDate
            eventEntity.createdAt = Date()
            
            // Create todo for this event
            let todoEntity = CalendarTodoEntity(context: context)
            todoEntity.id = UUID()
            todoEntity.title = "Take a medicine"
            todoEntity.isCompleted = false
            todoEntity.createdAt = Date()
            todoEntity.event = eventEntity
            
            // Don't schedule notifications here - will be done after all events are created
            
            // Move to next date (4 days later)
            currentDate = calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate
        }
        
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: hasPrefilledKey)
            loadEvents()
            
            // Schedule notifications only for the next unchecked event
            updateNotificationsForNextEvent()
            
            print("✅ Prefilled calendar events from Nov 15, 2025 to June 7, 2026")
        } catch {
            print("❌ Failed to prefill calendar events: \(error)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadEvents() {
        let fetchRequest: NSFetchRequest<CalendarEventEntity> = CalendarEventEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CalendarEventEntity.date, ascending: true)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            events = entities.compactMap { entity in
                guard let id = entity.id,
                      let date = entity.date else {
                    return nil
                }
                
                // Load todos for this event
                let todos = (entity.todos?.allObjects as? [CalendarTodoEntity] ?? []).compactMap { todoEntity -> CalendarTodo? in
                    guard let todoId = todoEntity.id,
                          let title = todoEntity.title else {
                        return nil
                    }
                    
                    return CalendarTodo(
                        id: todoId,
                        title: title,
                        isCompleted: todoEntity.isCompleted,
                        createdAt: todoEntity.createdAt ?? Date()
                    )
                }.sorted { $0.createdAt < $1.createdAt }
                
                return CalendarEvent(
                    id: id,
                    date: date,
                    createdAt: entity.createdAt ?? Date(),
                    todos: todos
                )
            }
        } catch {
            print("Failed to load calendar events: \(error)")
            events = []
        }
    }
    
    private func getEventEntity(for eventId: UUID) -> CalendarEventEntity? {
        let fetchRequest: NSFetchRequest<CalendarEventEntity> = CalendarEventEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", eventId as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first
        } catch {
            print("Failed to fetch event entity: \(error)")
            return nil
        }
    }
    
    private func getTodoEntity(for todoId: UUID) -> CalendarTodoEntity? {
        let fetchRequest: NSFetchRequest<CalendarTodoEntity> = CalendarTodoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", todoId as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first
        } catch {
            print("Failed to fetch todo entity: \(error)")
            return nil
        }
    }
    
    deinit {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

