//
//  File.swift
//  Sift
//
//  Created by Ahmad Alhashemi on 2018-01-22.
//  Copyright © 2018 Ahmad Alhashemi. All rights reserved.
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

class File {
    private let file: UnsafeMutablePointer<FILE>!
    private(set) var isClosed = false
    
    init?(path: String, write: Bool = false) {
        file = write ? fopen(path, "a") : fopen(path, "r")
        if file == nil { return nil }
    }
    
    var readLine: String? {
        var linePtrVar: UnsafeMutablePointer<Int8>?
        var count: Int = 0
        
        var readBytes = getline(&linePtrVar, &count, file)
        
        if readBytes == -1 { return nil }
        if readBytes == 0 { return "" }
        
        guard let linePtr = UnsafeMutablePointer<UInt8>(OpaquePointer(linePtrVar))
            else { return nil }
        
        let cr = UInt8(ascii: "\r")
        let lf = UInt8(ascii: "\n")
        
        if readBytes == 1 && linePtr[0] == lf {
            return ""
        }
        
        if readBytes >= 2 {
            switch (linePtr[readBytes - 2], linePtr[readBytes - 1]) {
            case (cr, lf):
                readBytes -= 2
            case (_, lf):
                readBytes -= 1
            default:
                break
            }
        }
        
        let result = String._fromCodeUnitSequenceWithRepair(UTF8.self,
                                                            input: UnsafeMutableBufferPointer(
                                                                start: linePtr,
                                                                count: readBytes)).0
        
        free(linePtr)
        
        return result
    }
    
    func read() -> String {
        fseek(file, 0, SEEK_END)
        let size = ftell(file)
        fseek(file, 0, SEEK_SET)
        
        var buffer = [CChar](repeating: 0, count: size + 1)
        _ = fread(&buffer, 1, size, file)
        
        buffer[size] = 0
        return String(validatingUTF8: buffer) ?? ""
    }
    
    func write(_ string: String) {
        fputs(string, file)
    }
    
    func close() {
        if !isClosed {
            fclose(file)
            isClosed = true
        }
    }
    
    deinit {
        self.close()
    }
}
