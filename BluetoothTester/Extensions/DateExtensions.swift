//
//  DateExtensions.swift
//  BluetoothTester
//
//  Created by Bjørn Inge Berg on 19/03/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import Foundation
extension TimeInterval {
    func stringDaysFromTimeInterval() -> String {
        let aday = 86_400.0 //in seconds
        let time = Double(self).magnitude

        let days = time / aday

        return days.twoDecimals
    }
}
