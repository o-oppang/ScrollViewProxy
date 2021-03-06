// Created by Casper Zandbergen on 01/06/2020.
// https://twitter.com/amzdme

import SwiftUI
import Introspect

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension ScrollView {
    /// Creates a ScrollView with a ScrollViewReader
    public init<ID: Hashable, ProxyContent: View>(_ axes: Axis.Set = .vertical, showsIndicators: Bool = true, @ViewBuilder content: @escaping (ScrollViewProxy<ID>) -> ProxyContent) where Content == ScrollViewReader<ID, ProxyContent> {
        self.init(axes, showsIndicators: showsIndicators, content: {
            ScrollViewReader { content($0) }
        })
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {
    /// Adds an ID to this view so you can scroll to it with `ScrollViewProxy.scrollTo(_:alignment:animated:)`
    public func id<ID: Hashable>(_ id: ID, scrollView proxy: ScrollViewProxy<ID>) -> some View {
        func save(geometry: GeometryProxy) -> some View {
            proxy.save(geometry: geometry, for: id)
            return Color.clear
        }

        return self.background(GeometryReader(content: save(geometry:)))
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct ScrollViewReader<ID: Hashable, Content: View>: View {
    private var content: (ScrollViewProxy<ID>) -> Content

    @State private var proxy = ScrollViewProxy<ID>()

    public init(@ViewBuilder content: @escaping (ScrollViewProxy<ID>) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(proxy)
            .coordinateSpace(name: proxy.space)
            .introspectScrollView { self.proxy.coordinator.scrollView = $0 }
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct ScrollViewProxy<ID: Hashable> {
    fileprivate class Coordinator<ID: Hashable> {
        var frames = [ID: CGRect]()
        weak var scrollView: UIScrollView?
    }
    fileprivate var coordinator = Coordinator<ID>()
    fileprivate var space: UUID = UUID()
    
    fileprivate init() { }

    /// Scrolls to an edge or corner
    public func scrollTo(_ alignment: Alignment, animated: Bool = true) {
        guard let scrollView = coordinator.scrollView else { return }

        let contentRect = CGRect(origin: .zero, size: scrollView.contentSize)
        let visibleFrame = frame(contentRect, with: alignment)
        scrollView.scrollRectToVisible(visibleFrame, animated: animated)
    }

    /// Scrolls the view with ID to an edge or corner
    public func scrollTo(_ id: ID, alignment: Alignment = .top, animated: Bool = true) {
        guard let scrollView = coordinator.scrollView else { return }
        guard let cellFrame = coordinator.frames[id] else {
            return print("ID (\(id)) not found, make sure to add views with `.id(_:scrollView:)`")
        }

        let visibleFrame = frame(cellFrame, with: alignment)
        scrollView.scrollRectToVisible(visibleFrame, animated: animated)
    }

    private func frame(_ frame: CGRect, with alignment: Alignment) -> CGRect {
        guard let scrollView = coordinator.scrollView else { return frame }

        var visibleSize = scrollView.visibleSize
        visibleSize.width -= scrollView.adjustedContentInset.horizontal
        visibleSize.height -= scrollView.adjustedContentInset.vertical

        var origin = CGPoint.zero
        switch alignment {
        case .center:
            origin.x = frame.midX - visibleSize.width / 2
            origin.y = frame.midY - visibleSize.height / 2
        case .leading:
            origin.x = frame.minX
            origin.y = frame.midY - visibleSize.height / 2
        case .trailing:
            origin.x = frame.maxX - visibleSize.width
            origin.y = frame.midY - visibleSize.height / 2
        case .top:
            origin.x = frame.midX - visibleSize.width / 2
            origin.y = frame.minY
        case .bottom:
            origin.x = frame.midX - visibleSize.width / 2
            origin.y = frame.maxY - visibleSize.height
        case .topLeading:
            origin.x = frame.minX
            origin.y = frame.minY
        case .topTrailing:
            origin.x = frame.maxX - visibleSize.width
            origin.y = frame.minY
        case .bottomLeading:
            origin.x = frame.minX
            origin.y = frame.maxY - visibleSize.height
        case .bottomTrailing:
            origin.x = frame.maxX - visibleSize.width
            origin.y = frame.maxY - visibleSize.height
        default:
            fatalError("Not implemented")
        }

        origin.x = max(0, min(origin.x, scrollView.contentSize.width - visibleSize.width))
        origin.y = max(0, min(origin.y, scrollView.contentSize.height - visibleSize.height))
        return CGRect(origin: origin, size: visibleSize)
    }

    fileprivate func save(geometry: GeometryProxy, for id: ID) {
        coordinator.frames[id] = geometry.frame(in: .named(space))
    }
}

extension UIEdgeInsets {
    /// top + bottom
    var vertical: CGFloat {
        return top + bottom
    }
    /// left + right
    var horizontal: CGFloat {
        return left + right
    }
}
