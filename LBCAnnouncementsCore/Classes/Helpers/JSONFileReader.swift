//
//  JSONFileReader.swift
//  LBCAnnouncementsCore
//
//  Created by Mouldi GABSI on 02/02/2021.
//

import Foundation

public typealias JSONDictionary = [String: Any]

class JSONFileReader {
    
    class func readFile(_ fileName: String) -> Data? {
        
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: Data.ReadingOptions.dataReadingMapped)
                print("returned data was: \(data)")
                return data
            } catch {
                print("Could not load level file: \(fileName), error: \(error)")
            }
        } else {
            print("Could not find level file: \(fileName)")
        }
        return nil
    }
}
