import Foundation


func doVMLeak() {
    
    let service = "SampleService"
    
    func composeQuery() -> [String: Any] {
        return [kSecClass as String: kSecClassInternetPassword,
                kSecAttrServer as String: service,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnAttributes as String: true,
                kSecReturnData as String: true]
    }
    
    func save(value: String) {
        let encodedValue = value.data(using: String.Encoding.utf8)!
        var query = composeQuery()
        query[kSecValueData as String] = encodedValue
        SecItemAdd(query as CFDictionary, nil)
    }
    
    autoreleasepool {
        save(value: "SomeValue")
    }
    for _ in 0..<20000 {
        let query = composeQuery()
//        continue // < --- UNCOMMENT here - no leak
        _ = autoreleasepool {
            //######################
            // THE PROBLEM IS HERE
            //######################
            SecItemCopyMatching(query as CFDictionary, nil)
            //######################
            // THE END
            //######################
        }
    }
}

print("Leak reproduction is started")
    
doVMLeak()

print("Leak reproduction is finished. Please check out Memory and VM Compressed columns in Activity Monitor for KeychainLeak process")

RunLoop.main.run()
