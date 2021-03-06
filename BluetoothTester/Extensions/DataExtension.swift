//
//  DataExtension.swift
//  BluetoothTester
//
//  Created by Bjørn Inge Berg on 19/03/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import Foundation
extension Data {
    mutating func resetAllBytes() {
        self = Data()
    }

    // From Stackoverflow, see https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }

    public func hexEncodedString() -> String {
        String(self.reduce(into: "".unicodeScalars, { result, value in
            result.append(Data.hexAlphabet[Int(value / 16)])
            result.append(Data.hexAlphabet[Int(value % 16)])
        }))
    }

    func toDebugString() -> String {
        self.map { "\($0)"}.joined(separator: ", ")
    }
}
