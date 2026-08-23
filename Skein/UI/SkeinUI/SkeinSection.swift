//
//  SkeinSection.swift
//  Skein
//

import SwiftUI

struct SkeinSectionOptions: OptionSet {
    let rawValue: Int

    static let isBordered = SkeinSectionOptions(rawValue: 1 << 0)
    static let hasDividers = SkeinSectionOptions(rawValue: 1 << 1)

    static let plain: SkeinSectionOptions = []
    static let `default`: SkeinSectionOptions = [.isBordered, .hasDividers]
}

struct SkeinSection<Header: View, Content: View, Footer: View>: View {
    private let header: Header
    private let content: Content
    private let footer: Footer
    private let spacing: CGFloat
    private let options: SkeinSectionOptions

    private var isBordered: Bool { options.contains(.isBordered) }
    private var hasDividers: Bool { options.contains(.hasDividers) }

    init(
        spacing: CGFloat = 10,
        options: SkeinSectionOptions = .default,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.spacing = spacing
        self.options = options
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    init(
        spacing: CGFloat = 10,
        options: SkeinSectionOptions = .default,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Header == EmptyView {
        self.init(spacing: spacing, options: options) {
            EmptyView()
        } content: {
            content()
        } footer: {
            footer()
        }
    }

    init(
        spacing: CGFloat = 10,
        options: SkeinSectionOptions = .default,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            header()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        spacing: CGFloat = 10,
        options: SkeinSectionOptions = .default,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            EmptyView()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        _ title: LocalizedStringKey,
        spacing: CGFloat = 10,
        options: SkeinSectionOptions = .default,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            Text(title)
                .font(.headline)
        } content: {
            content()
        }
    }

    var body: some View {
        if isBordered {
            SkeinGroupBox(padding: spacing) {
                header
            } content: {
                dividedContent
            } footer: {
                footer
            }
        } else {
            VStack(alignment: .leading) {
                header
                dividedContent
                footer
            }
        }
    }

    @ViewBuilder
    private var dividedContent: some View {
        if hasDividers {
            _VariadicView.Tree(SkeinSectionLayout(spacing: spacing)) {
                content
                    .frame(maxWidth: .infinity)
            }
        } else {
            content
                .frame(maxWidth: .infinity)
        }
    }
}

private struct SkeinSectionLayout: _VariadicView_UnaryViewRoot {
    let spacing: CGFloat

    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let last = children.last?.id
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(children) { child in
                child
                if child.id != last {
                    Divider()
                }
            }
        }
    }
}
