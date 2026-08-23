//
//  ControlItemImageSet.swift
//  Skein
//

/// A named set of images that are used by control items.
///
/// An image set contains images for a control item in both the hidden and visible states.
struct ControlItemImageSet: Codable, Hashable, Identifiable {
    enum Name: String, Codable, Hashable {
        case arrow = "Arrow"
        case chevron = "Chevron"
        case door = "Door"
        case dot = "Dot"
        case ellipsis = "Ellipsis"
        case snowflake = "Snowflake"
        case sunglasses = "Sunglasses"
        case custom = "Custom"
    }

    let name: Name
    let hidden: ControlItemImage
    let visible: ControlItemImage

    var id: Int { hashValue }

    init(name: Name, hidden: ControlItemImage, visible: ControlItemImage) {
        self.name = name
        self.hidden = hidden
        self.visible = visible
    }

    init(name: Name, image: ControlItemImage) {
        self.init(name: name, hidden: image, visible: image)
    }
}

extension ControlItemImageSet {
    /// The default image set for the Skein icon.
    static let defaultSkeinIcon = ControlItemImageSet(
        name: .dot,
        hidden: .catalog("DotFill"),
        visible: .catalog("DotStroke")
    )

    /// The image set for the snowflake Skein icon.
    ///
    /// Named on its own because the `1.1.0` migration writes it directly. Reaching
    /// into `userSelectableSkeinIcons` for it would leave the migration silently
    /// doing nothing if this entry were ever renamed.
    static let snowflakeSkeinIcon = ControlItemImageSet(
        name: .snowflake,
        hidden: .symbol("snowflake.circle.fill"),
        visible: .symbol("snowflake.circle")
    )

    /// The image sets that the user can choose to display in the Skein icon.
    static let userSelectableSkeinIcons = [
        ControlItemImageSet(
            name: .arrow,
            hidden: .symbol("arrowshape.left.fill"),
            visible: .symbol("arrowshape.right.fill")
        ),
        ControlItemImageSet(
            name: .chevron,
            hidden: .symbol("chevron.left"),
            visible: .symbol("chevron.right")
        ),
        ControlItemImageSet(
            name: .door,
            hidden: .symbol("door.left.hand.closed"),
            visible: .symbol("door.left.hand.open")
        ),
        ControlItemImageSet(
            name: .dot,
            hidden: .catalog("DotFill"),
            visible: .catalog("DotStroke")
        ),
        ControlItemImageSet(
            name: .ellipsis,
            hidden: .catalog("EllipsisFill"),
            visible: .catalog("EllipsisStroke")
        ),
        snowflakeSkeinIcon,
        ControlItemImageSet(
            name: .sunglasses,
            hidden: .symbol("sunglasses.fill"),
            visible: .symbol("sunglasses")
        ),
    ]
}
