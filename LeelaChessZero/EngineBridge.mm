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

#import "EngineBridge.h"
#include "engine.h"
#include "LeelaConnect.hpp"
#include <dispatch/dispatch.h>
#include <vector>

@interface LCZero_EngineBridge ()

@property lczero::LeelaConnect *leela;

@end

@implementation LCZero_EngineBridge

- (instancetype)init
{
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        self.leela = new lczero::LeelaConnect();
        dispatch_block_t bestMoveBlock = ^{
            // This is the best move block
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                // TODO logging
//               NSLog(@"Best move: %@", strongSelf.leela->bestMoveInfo);
               if (strongSelf.bestMoveBlock) {
                   LCZero_BestMoveInfo *info = [[LCZero_BestMoveInfo alloc] init];
                   
                   info.bestmove = [NSString stringWithCString:strongSelf.leela->bestMoveInfo.bestmove.as_string().c_str() encoding:NSUTF8StringEncoding];
                   info.ponder = [NSString stringWithCString:strongSelf.leela->bestMoveInfo.ponder.as_string().c_str() encoding:NSUTF8StringEncoding];
                   info.game_id = strongSelf.leela->bestMoveInfo.game_id;
                   info.player = strongSelf.leela->bestMoveInfo.player;
                   info.is_black = strongSelf.leela->bestMoveInfo.is_black;
                   strongSelf.bestMoveBlock(info);
               }
            }
        };

        self.leela->setBestMoveBlock([bestMoveBlock copy]);

        dispatch_block_t thoughtBlock = ^{
            // This is the though info block
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                // TODO logging
                if (strongSelf.thoughtBlock) {
                    NSMutableArray *thoughts = [[NSMutableArray alloc] init];
                    for (const auto& thought : strongSelf.leela->thinkingInfos) {

                        LCZero_Thought *bridgeInfo = [[LCZero_Thought alloc] init];
                    
                        bridgeInfo.player = thought.player;
                        bridgeInfo.depth = thought.depth;
                        bridgeInfo.game_id = thought.game_id;
                        bridgeInfo.is_black = thought.is_black;
                        bridgeInfo.multipv = thought.multipv;
                        bridgeInfo.nodes = thought.nodes;
                        bridgeInfo.seldepth = thought.seldepth;
                        bridgeInfo.time = thought.time;
                        bridgeInfo.score = thought.score;
                        bridgeInfo.hashfull = thought.hashfull;
                        bridgeInfo.nps = thought.nps;
                        bridgeInfo.tb_hits = thought.tb_hits;
                        NSMutableArray *line = [[NSMutableArray alloc] init];
                        if (thought.pv.size()>0) {
                            for (int i=0; i<thought.pv.size(); i++) {
                                lczero::Move move = thought.pv.at(i);
                                NSString *moveString = [NSString stringWithCString:move.as_string().c_str() encoding:NSUTF8StringEncoding];
                                [line addObject:moveString];
                            }
                        }
                        [thoughts addObject:bridgeInfo];
                    }
                    strongSelf.thoughtBlock(thoughts);
                }
            }
        };
        
        self.leela->setThoughtBlock([thoughtBlock copy]);
    }
    return self;
}

-(void)dealloc {
    delete _leela;
}

// All the UCI send throughs
- (void)sendUCI { self.leela->CmdUci(); }
- (void)sendIsReady { self.leela->CmdIsReady(); }
- (void)sendNewGame { self.leela->CmdUciNewGame(); }
- (void)sendPonderHit { self.leela->CmdPonderHit(); }
- (void)sendStop { self.leela->CmdStop(); }
- (void)setupWeights:(NSString *)filePath {
    NSLog(@"Initializing with weight file: %@", filePath);
    std::string filePathString = std::string([filePath UTF8String]);
    self.leela->SetupWeights(filePathString);
}
- (void)sendSetOption:(NSString *)key value:(NSString *)value context:(NSString *)context {
    std::string keyString = std::string([key UTF8String]);
    std::string valueString = std::string([value UTF8String]);
    std::string contextString = std::string([context UTF8String]);
    self.leela->CmdSetOption(keyString, valueString, contextString);
}
- (void)sendPosition:(NSString *)FEN moves:(NSArray *)moveStrings {
    std::string fenString = std::string([FEN UTF8String]);
    // TODO: plumb moves
    std::vector<std::string> moves;
//    [moveStrings enumerateObjectsUsingBlock:^(NSString *move, NSUInteger idx, BOOL * _Nonnull stop) {
//        std::string moveString = std::string([move UTF8String]);
//        moves.insert(moves.back(), &moveString);
//    }];
    
    self.leela->CmdPosition(fenString, moves);
}

- (void)sendGo:(LCZero_GoParameters *)goParams {
    
    lczero::GoParams *bridgedParams = new lczero::GoParams;
    bridgedParams->infinite = goParams.infinite;
    bridgedParams->ponder = goParams.ponder;
    
    // We fake the optionals here
    if (goParams.wtime != GoParam_TimeInterval_NotUsed) { bridgedParams->wtime = goParams.wtime; }
    if (goParams.btime != GoParam_TimeInterval_NotUsed) { bridgedParams->btime = goParams.btime; }
    if (goParams.winc != GoParam_TimeInterval_NotUsed) { bridgedParams->winc = goParams.winc; }
    if (goParams.binc != GoParam_TimeInterval_NotUsed) { bridgedParams->binc = goParams.binc; }
    if (goParams.movetime != GoParam_TimeInterval_NotUsed) { bridgedParams->movetime = goParams.movetime; }
    if (goParams.movestogo != GoParam_Integer_NotUsed) { bridgedParams->movestogo = goParams.movestogo; }
    if (goParams.depth != GoParam_Integer_NotUsed) { bridgedParams->depth = goParams.depth; }
    if (goParams.nodes != GoParam_Integer_NotUsed) { bridgedParams->nodes = goParams.nodes; }

    // GoParam_Integer_NotUsed
    self.leela->CmdGo(*bridgedParams);
}

@end

@implementation LCZero_EngineBridge (CPPProperties)

-(void)setLeela:(lczero::LeelaConnect *)newLeela {
    @synchronized(self) {
        delete _leela;  // it's OK to delete a NULL pointer
        _leela = newLeela;
    }
}

-(lczero::LeelaConnect *)leela {
    return _leela;
}

@end
