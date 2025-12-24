//
//  YRepeatWidgetBundle.swift
//  YRepeatWidget
//
//  Created by Dino Pelic on 24. 12. 2025..
//

import WidgetKit
import SwiftUI

@main
struct YRepeatWidgetBundle: WidgetBundle {
    var body: some Widget {
        YRepeatWidget()
        YRepeatWidgetControl()
        YRepeatWidgetLiveActivity()
    }
}
