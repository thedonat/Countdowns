//
//  CountdownsWidgetBundle.swift
//  CountdownsWidget
//
//  Created by Burak Donat on 1/14/26.
//

import WidgetKit
import SwiftUI

@main
struct CountdownsWidgetBundle: WidgetBundle {
    var body: some Widget {
        NearestEventWidget()
        UpcomingEventsWidget()
        CategoryEventsWidget()
    }
}
