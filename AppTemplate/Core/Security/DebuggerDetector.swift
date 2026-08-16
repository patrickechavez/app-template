//
//  DebuggerDetector.swift
//  AppTemplate
//  Created by John Patrick Echavez on 8/16/26.
//

import Darwin

protocol DebuggerDetecting: Sendable {
    var isDebuggerAttached: Bool { get }
}

/// Reports whether a debugger is attached via the `P_TRACED` process flag.
/// Report-only — deliberately avoiding `ptrace(PT_DENY_ATTACH)`, which can get
/// an App Store submission rejected.
struct DefaultDebuggerDetector: DebuggerDetecting {

    var isDebuggerAttached: Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else {
            return false
        }

        let tracedFlag: Int32 = 0x0800 // P_TRACED
        return (info.kp_proc.p_flag & tracedFlag) != 0
    }
}
