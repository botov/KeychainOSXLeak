# The problem

Please check out following macOS console app and advice how to prevent memory footproint growth (leakage) caused by SecItemCopyMatching:


	...
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
        //continue // UNCOMMENT here - no leak
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
	...

There are no leaks according to instruments. But I see in Activity Monitor, memory footprint keep growing and eventially almost all is going to swap.

![Activity Monitor](Leak.png?raw=true "Leak in Activity Monitor")

According to vmmap:

                    VIRTUAL RESIDENT    DIRTY  SWAPPED VOLATILE   NONVOL    EMPTY   REGION
    REGION TYPE        SIZE     SIZE     SIZE     SIZE     SIZE     SIZE     SIZE    COUNT (non-coalesced)
    VM_ALLOCATE       78.1M       0K       0K    78.1M       0K       0K       0K      647


Accoring my observations each SecItemCopyMatching costs aprox 4KB of leaked (abandoned and swaped) memory. So if you increase the main loop iterations from 20 000 to 200 000 => you will observe ~800MB of leaked memory.

What's wrong with the SecItemCopyMatching usage?

# To build and run KeychainLeak

A description of this package.

in Package.swift directory:
	
	swift build
	swift run

if needed:

	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
