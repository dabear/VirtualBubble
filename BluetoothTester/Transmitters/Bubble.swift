//
//  Bubble.swift
//  BluetoothTester
//
//  Created by Bjørn Inge Berg on 21/03/2020.
//  Copyright © 2020 Bjørn Inge Berg. All rights reserved.
//

import Foundation

public enum BubbleResponseType: UInt8 {
    case dataPacket = 130
    case bubbleInfo = 128 // = wakeUp + device info
    case noSensor = 191
    case serialNumber = 192
}

public class BubbleTx {
    static func formatDataPacket(sequence: [UInt8], mtu: Int) -> Data {
        var packet = [BubbleResponseType.dataPacket.rawValue, 0, 0, 0] + sequence
        //we zero pad to fullfill protocol expectations
        while packet.count < mtu {
            packet.append(0)
        }

        return Data(packet)

    }

    static let dataPacketPrefixLength = 4

    static func formatBubbleInfo() -> Data {
        //let hardware = value[value.count-2].description + "." + value[value.count-1].description
        //let firmware = value[2].description + "." + value[3].description
    //let patchInfo = Data(Double(firmware)! < 1.35 ? value[3...8] : value[5...10])
        let battery: UInt8 = 100
        let hardware = 1

        return Data([BubbleResponseType.bubbleInfo.rawValue, 0, 1, 2, battery, 0, 5, 3] as [UInt8])

    }

    static func formatSerialNumber() -> Data {
        Data([BubbleResponseType.serialNumber.rawValue, 0, 111, 94, 250, 96, 0, 160, 7, 224])
    }
}
