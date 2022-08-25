/*
 Modified MIT License

 Copyright 2022 OneSignal

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 1. The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 2. All copies of substantial portions of the Software may only be used in connection
 with services provided by OneSignal.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Foundation

public class OSModelChangedArgs: NSObject {
    /**
     The full model in its current state.
     */
    public let model: OSModel

    /**
     The property that was changed.
     */
    public let property: String

    /**
     The old value of the property, prior to it being changed.
     */
    public let oldValue: Any?

    /**
     The new value of the property, after it has been changed.
     */
    public let newValue: Any?
    
    init(model: OSModel, property: String, oldValue: Any?, newValue: Any?) {
        self.model = model
        self.property = property
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

public protocol OSModelChangedHandler {
    func onModelUpdated(args: OSModelChangedArgs, hydrating: Bool)
}
