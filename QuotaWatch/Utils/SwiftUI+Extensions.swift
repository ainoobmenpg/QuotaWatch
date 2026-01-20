//
//  SwiftUI+Extensions.swift
//  QuotaWatch
//
//  SwiftUI View を NSImage に変換する拡張機能
//

import SwiftUI

/// View から NSImage を生成する拡張機能
extension View {
    /// ViewをNSImageに変換する
    /// - Parameters:
    ///   - width: 画像の幅
    ///   - height: 画像の高さ
    /// - Returns: NSImage
    func asNSImage(width: CGFloat, height: CGFloat) -> NSImage? {
        let hostingView = NSHostingView(rootView: self)
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        let image = NSImage(size: hostingView.bounds.size)
        image.addRepresentation(bitmapRep)

        return image
    }
}
