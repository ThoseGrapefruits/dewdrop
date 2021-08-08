//
//  DDPopoverView.swift
//  DDPopoverView
//
//  Created by Logan Moore on 2021-08-08.
//

import Foundation
import UIKit

struct DDPopoverView: View {
    @State private var showingPopover = false

    var body: some View {
        .popover(isPresented: $showingPopover) {
            Text("Your content here")
                .font(.headline)
                .padding()
        }
    }
}
