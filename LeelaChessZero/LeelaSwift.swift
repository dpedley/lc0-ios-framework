/*
 This file is part of Leela Chess Zero.
 Copyright (C) 2018 The LCZero Authors
 
 Leela Chess is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Leela Chess is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Leela Chess.  If not, see <http://www.gnu.org/licenses/>.
 
 Additional permission under GNU GPL version 3 section 7
 
 If you modify this Program, or any covered work, by linking or
 combining it with NVIDIA Corporation's libraries from the NVIDIA CUDA
 Toolkit and the NVIDIA CUDA Deep Neural Network library (or a
 modified version of those libraries), containing parts covered by the
 terms of the respective license agreement, the licensors of this
 Program grant you additional permission to convey the resulting work.
 */

import Foundation

public protocol LeelaChessZeroDelegate: class {
    func leela(bestMove: LCZero_BestMoveInfo)
    func leela(thoughts: Array<LCZero_Thought>)
}

public enum lczero {
    public struct UCIGoParams {
        public var wtime: TimeInterval?
        public var btime: TimeInterval?
        public var winc: TimeInterval?
        public var binc: TimeInterval?
        public var movestogo: Int?
        public var depth: Int?
        public var nodes: Int?
        public var movetime: TimeInterval?
        public var infinite = false
        public var searchmoves: [String] = []
        public var ponder = false
        public init() {}
    }

    public enum UCICommand {
        case UCI
        case isReady
        case setOption(key: String, value: String, context: String)
        case newGame
        case position(fen: String, moves: [String])
        case go(params: UCIGoParams)
        case ponderHit
        case stop
    }
    
    public class UCICommandEngine: NSObject {
        let leelaEngine: LCZero_EngineBridge = LCZero_EngineBridge()
        let delegate: LeelaChessZeroDelegate

        public required init(delegate: LeelaChessZeroDelegate) {
            self.delegate = delegate
            self.leelaEngine.bestMoveBlock = { (info: LCZero_BestMoveInfo) in
                delegate.leela(bestMove: info)
            }
            self.leelaEngine.thoughtBlock = { thoughts in
                guard let thoughts = thoughts as? Array<LCZero_Thought> else {
                    fatalError("Formatting problem in the language tools")
                }
                delegate.leela(thoughts: thoughts)
            }
        }
        
        public func setupWeights(filePath: String) {
            leelaEngine.setupWeights(filePath)
        }
        
        public func sendCommand(_ command: UCICommand) {
            switch command {
            case .UCI:
                leelaEngine.sendUCI()
                break
            case .isReady:
                leelaEngine.sendIsReady()
                break
            case .setOption(let key, let value, let context):
                leelaEngine.sendSetOption(key, value: value, context: context);
                break
            case .newGame:
                leelaEngine.sendNewGame()
                break
            case .position(let fen, let moves):
                leelaEngine.sendPosition(fen, moves: moves)
                break
            case .go(let params):
                // Create an objective c param object to bridge the gap
                let goParams = LCZero_GoParameters.from(swiftParams: params)
                leelaEngine.sendGo(goParams)
                break
            case .ponderHit:
                leelaEngine.sendPonderHit()
                break
            case .stop:
                leelaEngine.sendStop()
                break
            }
        }
    }
}

extension LCZero_GoParameters {
    static func from(swiftParams: lczero.UCIGoParams) -> LCZero_GoParameters {
        let params = LCZero_GoParameters()
        params.infinite = swiftParams.infinite
        params.ponder = swiftParams.ponder
        params.wtime = swiftParams.wtime ?? TimeInterval(GoParam_TimeInterval_NotUsed)
        params.btime = swiftParams.btime ?? TimeInterval(GoParam_TimeInterval_NotUsed)
        params.winc = swiftParams.winc ?? TimeInterval(GoParam_TimeInterval_NotUsed)
        params.binc = swiftParams.binc ?? TimeInterval(GoParam_TimeInterval_NotUsed)
        params.movestogo = swiftParams.movestogo ?? Int(GoParam_Integer_NotUsed)
        params.depth = swiftParams.depth ?? Int(GoParam_Integer_NotUsed)
        params.nodes = swiftParams.nodes ?? Int(GoParam_Integer_NotUsed)
        return params
    }
}

