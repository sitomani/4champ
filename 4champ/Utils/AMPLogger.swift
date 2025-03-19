//
//  AMPLogger.swift
//  ampplayer
//
//  Copyright © 2025 Aleksi Sitomaniemi. All rights reserved.
//
import os

struct AMPLogger {
    private let logger = Logger(subsystem: "net.4champ", category: "app")

    func verbose(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .info, message, function: function, file: file, line: line)
    }

    func debug(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .debug, message, function: function, file: file, line: line)
    }

    func info(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .info, message, function: function, file: file, line: line)
    }

    func warning(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .default, message, function: function, file: file, line: line)
    }

    func error(_ message: Any, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .error, message, function: function, file: file, line: line)
    }

    private func log(level: OSLogType, _ message: Any, function: String, file: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let logPrefix: String

#if DEBUG
        logPrefix = "\((fileName as NSString).deletingPathExtension).\(function)"
#else
        if level == .debug { return }
        logPrefix = ""
#endif

        switch message {
        case let string as String:
            logger.log(level: level, "\(logPrefix) \(string)")
        case let url as URL:
            logger.log(level: level, "\(logPrefix) URL: \(url.absoluteString)")
        case let error as Error:
            logger.log(level: level, "\(logPrefix) Error: \(error.localizedDescription)")
        default:
            logger.log(level: level, "\(logPrefix) Unknown type: \(String(describing: message))")
        }
    }
}
