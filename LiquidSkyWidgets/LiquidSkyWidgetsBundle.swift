//
//  LiquidSkyWidgetsBundle.swift
//  LiquidSkyWidgets
//
//  Created by Callum Matthews on 28/08/2025.
//

import WidgetKit
import SwiftUI

@main
struct LiquidSkyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LiquidSkyWidgets()
        LiquidSkyWidgetsControl()
        LiquidSkyWidgetsLiveActivity()
    }
}
