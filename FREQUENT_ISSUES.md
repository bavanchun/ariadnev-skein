# Frequent Issues <!-- omit in toc -->

- [Items are moved to the always-hidden section](#items-are-moved-to-the-always-hidden-section)
- [Skein removed an item](#skein-removed-an-item)
- [Skein does not remember the order of items](#skein-does-not-remember-the-order-of-items)
- [How do I solve the `Skein cannot arrange menu bar items in automatically hidden menu bars` error?](#how-do-i-solve-the-skein-cannot-arrange-menu-bar-items-in-automatically-hidden-menu-bars-error)

## Items are moved to the always-hidden section

By default, macOS adds new items to the far left of the menu bar, which is also the location of Skein's always-hidden section. Most apps are configured
to remember the positions of their items, but some are not. macOS treats the items of these apps as new items each time they appear. This results in
these items appearing in the always-hidden section, even if they have been previously been moved.

Skein does not currently manage individual items, and in fact cannot, as of the current release. Once upstream Ice issues
[#6](https://github.com/jordanbaird/Ice/issues/6) and [#26](https://github.com/jordanbaird/Ice/issues/26) are implemented, Skein will be able to
monitor the items in the menu bar, and move the ones it recognizes to their previous locations, even if macOS rearranges them. Both numbers refer to
[jordanbaird/Ice](https://github.com/jordanbaird/Ice), the project Skein is forked from — not to issues in this repository.

## Skein removed an item

Skein does not have the ability to move or remove items. It likely got placed in the always-hidden section by macOS. Option + click the Skein icon to show
the always-hidden section, then Command + drag the item into a different section.

## Skein does not remember the order of items

This is not a bug, but a missing feature. It is being tracked upstream in [jordanbaird/Ice#26](https://github.com/jordanbaird/Ice/issues/26).

## How do I solve the `Skein cannot arrange menu bar items in automatically hidden menu bars` error?

1. Open `System Settings` on your Mac
2. Go to `Control Center`
3. Select `Never` as shown in the image below
4. Update your `Menu Bar Items` in `Skein`
5. Return `Automatically hide and show the menu bar` to your preferred settings

![Disable Menu Bar Hiding](https://github.com/user-attachments/assets/74c1fde6-d310-4fe3-9f2b-703d8ccb636a)
