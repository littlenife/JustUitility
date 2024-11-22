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

extension SafeHTML:CustomStringConvertible {
    var description: String {
        return self.value
    }
}

extension SafeHTML:CustomDebugStringConvertible {
    var debugDescription: String {
        return "SafeHTML:\(value)"
    }
}

//打开全模块优化
//将泛型函数标记为@inline 以便其他模块使用
//标准库大量使用@inlinable来确保API的特化
//编译器标记会把模块中的所有API标记为可内联来尝试这一过程自动化
//C++ Rust 所有东西进行泛型特化
//Java 只把泛型作为类型检查，在运行时通过包装将它抹去
//Swift 允许对泛型函数或类型在声明侧和客户端的使用进行分别编译
//它允许Apple在它的SDK中以二进制的方式搭载Swift书写的框架
//类似的，在我们自己的代码中，也可以用泛
//型抽象任何与类型无关的逻辑细节，并以此划分出更加清晰的责任边
//界。


@inlinable func min<T:Comparable>(_ x:T, _ y:T) -> T {
    return y < x ? y : x
}

struct FIFOQueue<Element> {
    private var left:[Element] = []
    private var right:[Element] = []

    mutating func enqueue(_ newElement:Element) {
        right.append(newElement)
    }

    mutating func dequeue()->Element? {
        if left.isEmpty {
            left = right.reverse()
            right.removeAll()
        }
       return left.popLast()
    }
}

extension FIFOQueue:Collection {
    public var startIndex:Int { return 0 }
    public var endIndex: Int { return left.count + right.count }
    public func index(after:Int) -> Int {
        precondition((i >= startIndex && i <endIndex), "index out of bounds")
        return i + 1
    }

    public subscript(position:Int) -> Element {
        precondition((startIndex ..< endIndex).contains(position),"index out of bounds")
        if position < left.endIndex {
            return left[left.count - postion -1]
        } else {
            return right[position - left.count]
        }
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

    let res = min(11.2, 12.2)
    print("\(res)")

}






















main()