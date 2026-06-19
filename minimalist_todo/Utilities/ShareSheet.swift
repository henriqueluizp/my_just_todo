//
//  ShareSheet.swift
//  minimalist_todo
//
//  Minimal UIActivityViewController bridge for sharing the exported JSON
//  backup file from SwiftUI.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
