//
//  HabitModels.swift
//  YRepeat
//
//  Created for Habits feature
//

import SwiftUI

struct HabitIcons {
    static let all: [(sfSymbol: String, emoji: String)] = [
        // Basic & Common
        ("star.fill", "⭐"), ("heart.fill", "❤️"), ("flame.fill", "🔥"), ("leaf.fill", "🍃"), ("book.fill", "📚"),
        ("dumbbell.fill", "🏋️"), ("moon.fill", "🌙"), ("sun.max.fill", "☀️"), ("drop.fill", "💧"), ("bolt.fill", "⚡"),
        
        // Activities & Fitness
        ("figure.walk", "🚶"), ("figure.run", "🏃"), ("figure.yoga", "🧘"), ("figure.strengthtraining.traditional", "💪"),
        ("figure.dance", "💃"), ("figure.skiing.downhill", "⛷️"), ("figure.surfing", "🏄"), ("figure.climbing", "🧗"),
        ("sportscourt.fill", "🏟️"), ("basketball.fill", "🏀"), ("soccerball", "⚽"), ("football.fill", "🏈"),
        ("tennis.racket", "🎾"), ("figure.swimming", "🏊"), ("bicycle", "🚴"), ("figure.cycling", "🚴"),
        ("figure.archery", "🏹"), ("figure.boxing", "🥊"), ("figure.golf", "⛳"), ("figure.hiking", "🥾"),
        ("figure.hunting", "🎯"), ("figure.jumprope", "🦘"), ("figure.pilates", "🧘"), ("figure.rowing", "🚣"),
        
        // Food & Drink
        ("cup.and.saucer.fill", "☕"), ("fork.knife", "🍴"), ("wineglass.fill", "🍷"), ("mug.fill", "☕"),
        ("takeoutbag.and.cup.and.straw.fill", "🥤"), ("birthday.cake.fill", "🎂"), ("carrot.fill", "🥕"),
        ("apple.fill", "🍎"), ("banana.fill", "🍌"), ("orange.fill", "🍊"), ("strawberry.fill", "🍓"),
        ("fish.fill", "🐟"), ("pizza.fill", "🍕"), ("tray.fill", "🍽️"), ("takeoutbag.fill", "🥡"),
        ("bowl.fill", "🥣"), ("spoon.fill", "🥄"), ("fork.fill", "🍴"), ("knife.fill", "🔪"),
        ("waterbottle.fill", "💧"), ("popcorn.fill", "🍿"), ("icecream.fill", "🍦"), ("lollipop", "🍭"),
        ("candybar.fill", "🍫"), ("gift.fill", "🎁"), ("party.popper.fill", "🎉"),
        
        // Transportation
        ("car.fill", "🚗"), ("airplane", "✈️"), ("tram.fill", "🚊"), ("bus.fill", "🚌"),
        ("bicycle", "🚲"), ("fuelpump.fill", "⛽"), ("car.2.fill", "🚙"), ("sailboat.fill", "⛵"),
        
        // Home & Daily Life
        ("house.fill", "🏠"), ("bed.double.fill", "🛏️"), ("shower.fill", "🚿"), ("toothbrush.fill", "🪥"),
        ("pills.fill", "💊"), ("cross.case.fill", "➕"), ("bandage.fill", "🩹"), ("stethoscope", "🩺"),
        
        // Health & Wellness
        ("brain.head.profile", "🧠"), ("eye.fill", "👁️"), ("ear.fill", "👂"), ("hand.raised.fill", "✋"),
        ("hand.thumbsup.fill", "👍"), ("heart.text.square.fill", "💚"), ("lungs.fill", "🫁"),
        
        // Creative & Entertainment
        ("music.note", "🎵"), ("guitars.fill", "🎸"), ("paintbrush.fill", "🖌️"), ("camera.fill", "📷"),
        ("photo.fill", "📸"), ("film.fill", "🎬"), ("gamecontroller.fill", "🎮"), ("tv.fill", "📺"),
        ("laptopcomputer", "💻"), ("iphone", "📱"), ("ipad", "📱"),
        
        // Learning & Work
        ("pencil", "✏️"), ("pencil.tip", "✏️"), ("highlighter", "🖍️"), ("bookmark.fill", "🔖"),
        ("tag.fill", "🏷️"), ("graduationcap.fill", "🎓"), ("briefcase.fill", "💼"),
        
        // Time & Reminders
        ("bell.fill", "🔔"), ("alarm.fill", "⏰"), ("clock.fill", "🕐"), ("timer", "⏱️"),
        ("calendar", "📅"), ("clock.badge.checkmark.fill", "✅"),
        
        // Status & Actions
        ("checkmark.circle.fill", "✅"), ("xmark.circle.fill", "❌"), ("plus.circle.fill", "➕"),
        ("minus.circle.fill", "➖"), ("questionmark.circle.fill", "❓"), ("exclamationmark.triangle.fill", "⚠️"),
        ("info.circle.fill", "ℹ️"), ("star.circle.fill", "⭐"), ("heart.circle.fill", "❤️"), ("flame.circle.fill", "🔥"),
        
        // Nature & Weather
        ("leaf.circle.fill", "🍃"), ("bolt.circle.fill", "⚡"), ("drop.circle.fill", "💧"),
        ("sun.circle.fill", "☀️"), ("moon.circle.fill", "🌙"), ("cloud.fill", "☁️"), ("cloud.rain.fill", "🌧️"),
        ("snowflake", "❄️"), ("tornado", "🌪️"), ("hurricane", "🌀"), ("tree.fill", "🌳"), ("flower.fill", "🌸"),
        
        // Animals
        ("pawprint.fill", "🐾"), ("fish.fill", "🐟"), ("bird.fill", "🐦"), ("tortoise.fill", "🐢"),
        ("ladybug.fill", "🐞"), ("ant.fill", "🐜"), ("butterfly.fill", "🦋"),
        
        // Achievement & Status
        ("crown.fill", "👑"), ("trophy.fill", "🏆"), ("medal.fill", "🥇"), ("rosette", "🏵️"),
        ("seal.fill", "🔰"), ("shield.fill", "🛡️"), ("star.square.fill", "⭐"), ("heart.square.fill", "❤️")
    ]
    
    static func emojiForIcon(_ iconName: String) -> String {
        return all.first(where: { $0.sfSymbol == iconName })?.emoji ?? "⭐"
    }
}

