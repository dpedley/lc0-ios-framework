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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define GoParam_TimeInterval_NotUsed (-867.5309f)
#define GoParam_Integer_NotUsed -7734

@interface LCZero_GoParameters : NSObject
@property NSTimeInterval wtime;
@property NSTimeInterval btime;
@property NSTimeInterval winc;
@property NSTimeInterval binc;
@property NSInteger movestogo;
@property NSInteger depth;
@property NSInteger nodes;
@property NSTimeInterval movetime;
@property Boolean infinite;
@property NSArray *searchmoves;
@property Boolean ponder;
@end

@interface LCZero_BestMoveInfo : NSObject

@property (nonatomic, copy) NSString *bestmove;
@property (nonatomic, copy) NSString *ponder;
@property NSInteger player;
@property NSInteger game_id;
@property Boolean is_black;

@end

@interface LCZero_Thought : NSObject

@property (nonatomic, copy) NSArray *line; // Array of Move Strings 
@property NSInteger player;
@property NSInteger game_id;
@property Boolean is_black;
@property NSInteger depth;
@property NSInteger seldepth;
@property NSInteger time;
@property NSInteger nodes;
@property NSInteger score;
@property NSInteger hashfull;
@property NSInteger nps;
@property NSInteger tb_hits;
@property NSInteger multipv;

@end


NS_ASSUME_NONNULL_END
