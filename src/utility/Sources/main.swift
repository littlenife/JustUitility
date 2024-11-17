// Console app.

import Foundation

extension String {
    var htmlEscaped:String {
        return replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}

struct SafeHTML {
    private(set) var value:String
    init(unsafe html:String){
        self.value = html.htmlEscaped
    }
}

extension SafeHTML:ExpressibleByStringLiteral {
    public init(stringLiteral value:StringLiteralType){
        self.value = value
    }
}

extension SafeHTML:ExpressibleByStringInterpolation {
   init(stringInterpolation: SafeHTML) {
      self.value = stringInterpolation.value
    }
}

extension SafeHTML:StringInterpolationProtocol {
    init(literalCapacity: Int, interpolationCount: Int) {
        self.value = ""
        value.reserveCapacity(literalCapacity)
    }

    mutating func appendLiteral(_ literal: StringLiteralType) {
        value += literal
    }

    mutating func appendInterpolation<T>(_ x:T) {
        self.value += String(describing: x).htmlEscaped
    }

    mutating func appendInterpolation<T>(raw x:T) {
        self.value += String(describing: x)
    }
}




func main() {

//    let safe:SafeHTML = "<p>Angle brackets in literals are not escaped</p>"

    let unsafeInput = "<script>alert('Oops!')</script>"
    let safe:SafeHTML = "<li>Username:\(unsafeInput)</li>"
    print(safe)

    let star = "<sup>*</sup>"
    let safe2:SafeHTML = "<li>Username\(raw: star):\(unsafeInput)</li>"
    print(safe2)

}






















main()