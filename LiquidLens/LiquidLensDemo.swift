import SwiftUI
import UIKit

/// Research-only demo. `_UILiquidLensView` is private UIKit API and must not be
/// shipped in an App Store build.
struct LiquidLensDemo: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .pink.opacity(0.7),
                    .orange.opacity(0.3),
                    .cyan,
                    .indigo
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Circular Liquid Lens")
                        .font(.title.bold())

                    Text("Drag the lens around the circular menu")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .shadow(radius: 8)

                Spacer()

                PrivateLiquidLensTabBar()
                    .frame(width: 310, height: 310)

                Text("Private API · for experimentation only")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding()
        }
    }
}

/// Bridges the UIKit-based private lens into SwiftUI.
private struct PrivateLiquidLensTabBar: UIViewRepresentable {
    func makeUIView(context: Context) -> LiquidLensTabBarView {
        LiquidLensTabBarView()
    }

    func updateUIView(_ uiView: LiquidLensTabBarView, context: Context) {}
}

@MainActor
private final class LiquidLensTabBarView: UIView {
    // MARK: Geometry

    private let itemCount = 3

    private let restingLensSize = CGSize(
        width: 96,
        height: 96
    )

    private let liftedLensSize = CGSize(
        width: 116,
        height: 116
    )

    private let tabs = [
        (symbol: "bubble.left.fill", title: "Chats"),
        (symbol: "person.2.fill", title: "Contacts"),
        (symbol: "gearshape.fill", title: "Settings")
    ]

    // MARK: View hierarchy

    private let glassView: UIVisualEffectView

    /// Regular content displayed across the entire menu.
    private let itemsView = UIView()

    /// Alternative content supplied to the private lens while lifted.
    private let selectedItemsView = UIView()

    private let statusLabel = UILabel()

    private var lensView: UIView!
    private var usesPrivateLens = false
    private var selectedIndex = 0

    override init(frame: CGRect) {
        let effect = UIGlassEffect(style: .regular)
        effect.isInteractive = true

        glassView = UIVisualEffectView(effect: effect)

        super.init(frame: frame)

        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = .clear

        glassView.clipsToBounds = true
        addSubview(glassView)

        itemsView.isUserInteractionEnabled = false
        addTabItems(
            to: itemsView,
            color: .label
        )

        selectedItemsView.isUserInteractionEnabled = false
        addTabItems(
            to: selectedItemsView,
            color: .systemIndigo
        )

        glassView.contentView.addSubview(selectedItemsView)

        statusLabel.font = .systemFont(
            ofSize: 9,
            weight: .semibold
        )
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel
        statusLabel.isUserInteractionEnabled = false

        glassView.contentView.addSubview(statusLabel)

        lensView = makeLensView()
        lensView.isUserInteractionEnabled = false
        lensView.layer.zPosition = 10

        glassView.contentView.addSubview(lensView)
        glassView.contentView.addSubview(itemsView)

        let gesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleDrag(_:))
        )

        gesture.minimumPressDuration = 0
        gesture.allowableMovement = .greatestFiniteMagnitude

        addGestureRecognizer(gesture)

        isAccessibilityElement = true
        accessibilityLabel = "Circular Liquid Lens menu"
        accessibilityHint = "Drag around the circle to change the selected item"
    }

    private func addTabItems(
        to container: UIView,
        color: UIColor
    ) {
        for tab in tabs {
            container.addSubview(
                CircularMenuItemView(
                    symbolName: tab.symbol,
                    title: tab.title,
                    color: color
                )
            )
        }
    }

    // MARK: Lens setup

    private func makeLensView() -> UIView {
        let restingBackground = UIView()

        restingBackground.backgroundColor =
            UIColor.white.withAlphaComponent(0.38)

        restingBackground.layer.borderColor =
            UIColor.white.withAlphaComponent(0.55).cgColor

        restingBackground.layer.borderWidth = 1

        guard
            let lensClass =
                NSClassFromString("_UILiquidLensView")
                    as AnyObject as? NSObjectProtocol,

            let allocated =
                lensClass
                    .perform(NSSelectorFromString("alloc"))?
                    .takeUnretainedValue(),

            let instance =
                allocated
                    .perform(
                        NSSelectorFromString(
                            "initWithRestingBackground:"
                        ),
                        with: restingBackground
                    )?
                    .takeUnretainedValue() as? UIView
        else {
            statusLabel.text = "Public fallback"
            return makeFallbackLens()
        }

        usesPrivateLens = true
        statusLabel.text = "Private UIKit lens"

        /*
         These relationships are part of the private API.

         Their exact semantics are implementation details and may change
         between OS releases.
         */
        callObject(
            instance,
            selectorName: "setLiftedContainerView:",
            value: glassView.contentView
        )

        callObject(
            instance,
            selectorName: "setLiftedContentView:",
            value: selectedItemsView
        )

        callObject(
            instance,
            selectorName: "setOverridePunchoutView:",
            value: itemsView
        )

        /*
         These numeric values correspond to private UIKit state.

         The underlying enum cases are not publicly documented.
         */
        callInt(
            instance,
            selectorName: "setLiftedContentMode:",
            value: 1
        )

        callInt(
            instance,
            selectorName: "setStyle:",
            value: 1
        )

        callBool(
            instance,
            selectorName: "setWarpsContentBelow:",
            value: true
        )

        instance.setValue(
            UIColor.white.withAlphaComponent(0.38),
            forKey: "restingBackgroundColor"
        )

        return instance
    }

    private func makeFallbackLens() -> UIView {
        let view = UIView()

        view.backgroundColor =
            UIColor.white.withAlphaComponent(0.3)

        view.layer.borderColor =
            UIColor.white.withAlphaComponent(0.55).cgColor

        view.layer.borderWidth = 1
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius =
            restingLensSize.height * 0.5

        return view
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let diameter = min(
            bounds.width,
            bounds.height
        )

        glassView.frame = CGRect(
            x: bounds.midX - diameter * 0.5,
            y: bounds.midY - diameter * 0.5,
            width: diameter,
            height: diameter
        )

        glassView.layer.cornerRadius = diameter * 0.5

        itemsView.frame = glassView.bounds
        selectedItemsView.frame = glassView.bounds

        layoutMenuItems(in: itemsView)
        layoutMenuItems(in: selectedItemsView)

        statusLabel.frame = CGRect(
            x: 0,
            y: diameter - 27,
            width: diameter,
            height: 12
        )

        if lensView.bounds.size == .zero {
            lensView.bounds = CGRect(
                origin: .zero,
                size: restingLensSize
            )

            lensView.center =
                centerForItem(at: selectedIndex)

            if !usesPrivateLens {
                lensView.layer.cornerRadius =
                    restingLensSize.height * 0.5
            }
        }
    }

    // MARK: Interaction

    @objc
    private func handleDrag(
        _ gesture: UILongPressGestureRecognizer
    ) {
        let location =
            gesture.location(
                in: glassView.contentView
            )

        switch gesture.state {
        case .began:
            setLifted(
                true,
                animated: true
            )

            moveLens(to: location)

        case .changed:
            moveLens(to: location)

        case .ended:
            selectedIndex =
                nearestItemIndex(to: location)

            settleLensAndLower()

        case .cancelled, .failed:
            settleLensAndLower()

        default:
            break
        }
    }

    private func moveLens(to point: CGPoint) {
        let menuCenter = CGPoint(
            x: itemsView.bounds.midX,
            y: itemsView.bounds.midY
        )

        let offset = CGVector(
            dx: point.x - menuCenter.x,
            dy: point.y - menuCenter.y
        )

        let distance = hypot(
            offset.dx,
            offset.dy
        )

        let maximumDistance =
            min(
                itemsView.bounds.width,
                itemsView.bounds.height
            ) * 0.5
            - liftedLensSize.width * 0.5
            - 10

        guard
            distance > maximumDistance,
            distance > 0
        else {
            lensView.center = point
            return
        }

        let scale =
            maximumDistance / distance

        lensView.center = CGPoint(
            x: menuCenter.x + offset.dx * scale,
            y: menuCenter.y + offset.dy * scale
        )
    }

    private func settleLensAndLower() {
        let targetCenter =
            centerForItem(at: selectedIndex)

        setLifted(
            false,
            animated: true,
            alongsideAnimations: { [weak self] in
                self?.lensView.center = targetCenter
            }
        )

        accessibilityValue =
            "Tab \(selectedIndex + 1) of \(itemCount)"
    }

    // MARK: Menu geometry

    private func centerForItem(
        at index: Int
    ) -> CGPoint {
        let angles: [CGFloat] = [
            -.pi / 2,
            .pi * 5 / 6,
            .pi / 6
        ]

        let menuCenter = CGPoint(
            x: itemsView.bounds.midX,
            y: itemsView.bounds.midY - 5
        )

        let radius =
            min(
                itemsView.bounds.width,
                itemsView.bounds.height
            ) * 0.27

        let angle = angles[index]

        return CGPoint(
            x: menuCenter.x + cos(angle) * radius,
            y: menuCenter.y + sin(angle) * radius
        )
    }

    private func layoutMenuItems(
        in container: UIView
    ) {
        for (index, itemView)
        in container.subviews.enumerated() {
            itemView.bounds = CGRect(
                x: 0,
                y: 0,
                width: 104,
                height: 62
            )

            itemView.center =
                centerForItem(at: index)
        }
    }

    private func nearestItemIndex(
        to point: CGPoint
    ) -> Int {
        (0..<itemCount).min { lhs, rhs in
            squaredDistance(
                from: point,
                to: centerForItem(at: lhs)
            )
            <
            squaredDistance(
                from: point,
                to: centerForItem(at: rhs)
            )
        } ?? selectedIndex
    }

    private func squaredDistance(
        from lhs: CGPoint,
        to rhs: CGPoint
    ) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y

        return dx * dx + dy * dy
    }

    // MARK: Lift state

    private func setLifted(
        _ lifted: Bool,
        animated: Bool,
        alongsideAnimations extraAnimations: (() -> Void)? = nil
    ) {
        let targetSize =
            lifted
            ? liftedLensSize
            : restingLensSize

        guard usesPrivateLens else {
            UIView.animate(
                withDuration: animated ? 0.25 : 0,
                animations: {
                    self.lensView.bounds.size =
                        targetSize

                    self.lensView.layer.cornerRadius =
                        targetSize.height * 0.5

                    extraAnimations?()
                }
            )

            return
        }

        let selector = NSSelectorFromString(
            "setLifted:animated:alongsideAnimations:completion:"
        )

        guard
            lensView.responds(to: selector),
            let method = lensView.method(for: selector)
        else {
            return
        }

        /*
         The completion block appears to receive the animation's finished
         state. Because this is private API, the signature can change.
         */
        typealias Method = @convention(c) (
            AnyObject,
            Selector,
            Bool,
            Bool,
            @escaping () -> Void,
            ((Bool) -> Void)?
        ) -> Void

        let function =
            unsafeBitCast(
                method,
                to: Method.self
            )

        function(
            lensView,
            selector,
            lifted,
            animated,
            { [weak self] in
                guard let self else { return }

                self.lensView.bounds.size =
                    targetSize

                extraAnimations?()
            },
            nil
        )
    }

    // MARK: Objective-C runtime helpers

    private func callObject(
        _ object: NSObject,
        selectorName: String,
        value: AnyObject
    ) {
        let selector =
            NSSelectorFromString(selectorName)

        guard object.responds(to: selector) else {
            return
        }

        object.perform(
            selector,
            with: value
        )
    }

    private func callInt(
        _ object: NSObject,
        selectorName: String,
        value: Int
    ) {
        let selector =
            NSSelectorFromString(selectorName)

        guard
            object.responds(to: selector),
            let method = object.method(for: selector)
        else {
            return
        }

        typealias Method =
            @convention(c) (
                AnyObject,
                Selector,
                Int
            ) -> Void

        let function =
            unsafeBitCast(
                method,
                to: Method.self
            )

        function(
            object,
            selector,
            value
        )
    }

    private func callBool(
        _ object: NSObject,
        selectorName: String,
        value: Bool
    ) {
        let selector =
            NSSelectorFromString(selectorName)

        guard
            object.responds(to: selector),
            let method = object.method(for: selector)
        else {
            return
        }

        typealias Method =
            @convention(c) (
                AnyObject,
                Selector,
                Bool
            ) -> Void

        let function =
            unsafeBitCast(
                method,
                to: Method.self
            )

        function(
            object,
            selector,
            value
        )
    }
}

// MARK: Menu item

@MainActor
private final class CircularMenuItemView: UIView {
    private let imageView: UIImageView
    private let titleLabel = UILabel()

    init(
        symbolName: String,
        title: String,
        color: UIColor
    ) {
        imageView = UIImageView(
            image: UIImage(
                systemName: symbolName
            )
        )

        super.init(frame: .zero)

        isUserInteractionEnabled = false

        imageView.contentMode = .center
        imageView.tintColor = color

        imageView.preferredSymbolConfiguration =
            UIImage.SymbolConfiguration(
                pointSize: 23,
                weight: .semibold
            )

        addSubview(imageView)

        titleLabel.text = title
        titleLabel.font =
            .systemFont(
                ofSize: 13,
                weight: .semibold
            )

        titleLabel.textColor = color
        titleLabel.textAlignment = .center

        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: 34
        )

        titleLabel.frame = CGRect(
            x: 0,
            y: 39,
            width: bounds.width,
            height: 20
        )
    }
}

#Preview {
    LiquidLensDemo()
}
