//
//  main.swift
//  BluetoothTester
//
//  Created by Bjørn Inge Berg on 18/12/2019.
//  Copyright © 2019 Bjørn Inge Berg. All rights reserved.
//
import Foundation

func runLoop() {
    let shouldKeepRunning = true
    let runLoop = RunLoop.current
    while shouldKeepRunning  &&
        runLoop.run(mode: .default, before: .distantFuture) {

    }
    NSLog("OK, quitting!")
}

BluetoothEmulator()

runLoop()
