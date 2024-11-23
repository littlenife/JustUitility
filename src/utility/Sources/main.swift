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
            left = right.reversed()
            right.removeAll()
        }
       return left.popLast()
    }
}

extension FIFOQueue:Collection {
    public var startIndex:Int { return 0 }
    public var endIndex:Int { return left.count + right.count }
    public func index(after i: Int) -> Int {
        precondition(i >= startIndex && i < endIndex,"")
        return i + 1
    }



    public subscript(position:Int) -> Element {
        precondition((startIndex ..< endIndex).contains(position),"index out of bounds")
        if position < left.endIndex {
            return left[left.count - position - 1]
        } else {
            return right[position - left.count]
        }
    }
}


extension Substring {
   var nextWordRange:Range<Index> {
        let start = drop(while: {$0 == " "})
        let end = start.firstIndex(where:{$0 == " "}) ?? endIndex
        return start.startIndex ..< end
    }
}

struct WordsIndex:Comparable {
     fileprivate let range:Range<Substring.Index>
     fileprivate init(_ value:Range<Substring.Index>) {
        self.range = value
    }

    static func < (lhs:WordsIndex, rhs:WordsIndex) -> Bool {
        lhs.range.lowerBound < rhs.range.lowerBound
    }
}

struct Words {
    let string:Substring
    let startIndex:WordsIndex
    init(_ s:String) {
        self.init(s[...])
    }
    private init(_ s:Substring) {
        self.string = s
        self.startIndex = WordsIndex(string.nextWordRange)
    }
    public var endIndex:WordsIndex {
        let e = string.endIndex
        return WordsIndex(e ..< e)
    }
}

extension Words {
    subscript(index:WordsIndex) ->Substring {
        string[index.range]
    }
}

extension Words:Collection {
    public func index(after i: WordsIndex) -> WordsIndex {
        guard i.range.upperBound < string.endIndex else { return endIndex}
        let remainder = string[ i.range.upperBound... ]
        return WordsIndex(remainder.nextWordRange)
    }
}



//默认情况下， Collection会把Slice<Self>作为自己的SubSequene类型。但是很多具体类型都有它们自己
//定制的实现：例如，String的SubSequence类型是Substring,Array的SubSequence类型是ArraySlice
//
// 让子序列和原始集合的类型一致，也就是 SubSequence ==
//Self，会非常方便。因为这样，只要能传递原始集合类型的地方，你也都能
//够使使用切片类型。 Foundation的Data就是这么做的。
//使用它们自己的类型来表示切片，可以比较容易将它们
//的生命周期绑定到局部作作用域中。

extension Collection {
    public func split(batchSize:Int) -> [SubSequence] {
        var result:[SubSequence] = []
        var batchStart = startIndex
        while batchStart < endIndex {
            let batchEnd = index(batchStart,offsetBy: batchSize,limitedBy: endIndex) ?? endIndex
            let batch = self[batchStart ..< batchEnd]
            result.append(batch)
            batchStart = batchEnd
        }
        return result
    }
}



//由于子序列也还同样以Element作为元素类型的集合，我们完全可以用处理集合的方法处理与之对应的
//切片类型。

//鉴于它们的内存开销很低，子序列非常适合表达中间结果。但是，为了避免小切片意外地把整个原始序列
//保持在内存中，通常不建议长时间保存子序列，或者把它们传递给有可能造成这种结果的方法
//为了切断子序列和原始集合类型之间的关系，我们可以用子序列创建一个新集合。String(substring)
// Array(arraySlice)
//

struct Slice<Base:Collection>:Collection {
    typealias Index = Base.Index
    let collection:Base
    var startIndex: Index
    var endIndex: Index
    init(base:Base, bounds:Range<Index>) {
        collection = base
        startIndex = bounds.lowerBound
        endIndex = bounds.upperBound
    }

    func index(after i: Index) -> Index {
        return collection.index(after: i)
    }

    subscript(position: Index) -> Base.Element {
        return collection[position]
    }

    subscript(bounds: Range<Index>) -> Slice<Base> {
        return Slice(base: collection, bounds: bounds)
    }

}

// Slice是非常适合作为默认的子序列类型，不过当创建一个自定义集合类型时，最好还是考虑是否
// 能将集合类型本身当作它的SubSequence使用

 extension Words {
    subscript(range: Range<WordsIndex>) -> Words {
       let start = range.lowerBound.range.lowerBound
       let end = range.upperBound.range.upperBound
       return Words(string[start..<end])
    }
}

//切片与原集合共享索引
//Collection 协议还有另一个正式的要求，那就是切片的索引可以和原集合
//的索引互换使用。

//这也是我们
//应当尽可能始终选择 for x in collection 的形式，而不去主动计算索引的一
//个原因。





func main() {

//    let safe:SafeHTML = "<p>Angle brackets in literals are not escaped</p>"

//    let unsafeInput = "<script>alert('Oops!')</script>"
//    let safe:SafeHTML = "<li>Username:\(unsafeInput)</li>"
//    print(safe)
//
//    let star = "<sup>*</sup>"
//    let safe2:SafeHTML = "<li>Username\(raw: star):\(unsafeInput)</li>"
//    print(safe2)
//
//    let res = min(11.2, 12.2)
//    print("\(res)")

    let letters = "abcdefg"
    let batches = letters.split(batchSize: 3)
    print(batches)

}






















main()