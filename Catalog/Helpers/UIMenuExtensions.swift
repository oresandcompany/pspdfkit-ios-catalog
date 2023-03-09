//
//  Copyright © 2022-2023 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIMenu {

    /// Filter out actions whose identifiers don't pass the given predicate from
    /// this menu and from the nested sub-menus.
    private func filterActions(_ predicate: (UIAction.Identifier) -> Bool) -> UIMenu {
        replacingChildren(children.compactMap { element in
            if let action = element as? UIAction {
                if predicate(action.identifier) {
                    return action
                } else {
                    return nil
                }
            } else if let menu = element as? UIMenu {
                return menu.filterActions(predicate)
            } else {
                return element
            }
        })
    }

    /// Filter out actions whose identifiers aren't in the given set from this
    /// menu and from the nested sub-menus.
    func filterActions(anyOf identifiers: Set<UIAction.Identifier>) -> UIMenu {
        filterActions { identifiers.contains($0) }
    }

    /// Filter out actions whose identifiers are in the given set from this menu
    /// and from the nested sub-menus.
    func filterActions(noneOf identifiers: Set<UIAction.Identifier>) -> UIMenu {
        filterActions { !identifiers.contains($0) }
    }

    /// Insert the given menu elements at the beginning of this menu.
    func prepend<Elements>(_ elements: Elements) -> UIMenu where Elements: Sequence, Elements.Element == UIMenuElement {
        replacingChildren(Array(elements) + children)
    }

}
