# Leela Chess Zero swift framework for iOS

A framework built for iOS to allow use of LeelaChessZero (lc0) chess engine. 

See the project [lczero.org](https://lczero.org) code here: [GITHUB](https://github.com/LeelaChessZero/)

The majority of the work needed here was crossing the languange boundaries. 

 * Leela is in C++, so I used `uciloop.cc` as a template for binding to lc0 callbacks called `LeelaConnect`.
 * C++ doesn't play nice with Objective-C, so I used Objective-C++ as the pass through language. `EngineBridge.mm`
 * `LeelaSwift.swift` uses the EngineBridge gives a delegate interface for communication.
 
How it works.

This repo uses `lc0` as a submodule, make sure to recurse the submodules so you have all the code needed. This will place the `lc0` code where the `Xcode` project expects it.

 * There were 2 changes to the `lc0` and `lczero-commons`. They are in `lc0-ios.diff` and `lczero-common-ios.diff`. You can apply them by running these command from the project root directory.
 ```
 pushd submodules/lc0/libs/lczero-common; git apply ../../../../lczero-common-ios.diff; popd
 pushd submodules/lc0; git apply ../../lc0-ios.diff; popd
 ```
 * You'll have to trigger the generation of the proto/net.pb.cc, proto/net.pb.cc the script `build_proto.sh`


The other libraries that this framework rely on are `libz` and `libprotobuf-lite`

 * libz is included with iOS, just go to your app target -> build phases -> link with libraries and find `libz.tbd`
 * libprotobuf is a bit involved to build. My tip is to compile and install the mac libraries first so you can use the `protoc` built on the mac during the [cross compile](https://github.com/protocolbuffers/protobuf/blob/master/src/README.md).
 
 My protobuf configure (after installing the Mac built protobuf first)
 ```
 ./configure --with-sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk --with-protoc=/usr/local/bin/protoc --disable-shared --enable-static --host=arm-apple-darwin
 ```

 Assuming that all goes well, you should be able to open `LeelaChessZero.xcodeproj` and build LeelaChessZero.framework.
 
Here's a snippet to use Leela via the framework:
```
class TestLeela: LeelaChessZeroDelegate {
    var leelaEngine: lczero.UCICommandEngine?

    public init(weightsFile: String) {
        self.init()
        self.leelaEngine = lczero.UCICommandEngine(delegate: self)
        leelaEngine?.setupWeights(filePath: weightsFile)
    }

    func evaluatePosition(fen: String, moves: [String]) {
        self.leelaEngine?.sendCommand(.position(fen: fen, moves: moves))
        let params: lczero.UCIGoParams = lczero.UCIGoParams()
        self.leelaEngine?.sendCommand(.go(params: params))
    }
    
    public func leela(bestMove: LCZero_BestMoveInfo) {
        print("Best Move: \(bestMove)")
    }
    
    public func leela(thoughts: Array<LCZero_Thought>) {
        print("Thoughts: \(thoughts)")
    }
}

// Elsewhere in the app:
let testLeela = TestLeela(weightsFile: filePath)
testLeela.evaluatePosition("6r1/5k2/5p2/p2P1N1R/2Ppp3/1P6/4K3/4b2r w - - 7 50", [])
```
