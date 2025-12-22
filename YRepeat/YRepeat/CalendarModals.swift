//
//  CalendarModals.swift
//  YRepeat
//
//  Created for Calendar feature
//

import SwiftUI

// MARK: - Add Calendar Event View

struct AddCalendarEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager: CalendarManager
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            ZStack {
                LiquidBackgroundView()
                
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
                            .fill(.ultraThinMaterial)
                    )
                    .padding()
                    
                    Button {
                        manager.addEvent(date: selectedDate)
                        dismiss()
                    } label: {
                        Text("Add Event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
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
                LiquidBackgroundView()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Todo Title")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        TextField("Enter todo title (e.g., Take medicine)", text: $todoTitle)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
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
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(todoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(todoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
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

