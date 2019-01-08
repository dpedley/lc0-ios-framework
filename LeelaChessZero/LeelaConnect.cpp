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

#include "LeelaConnect.hpp"
#include <algorithm>
#include <cmath>
#include <functional>

#include "mcts/search.h"
#include "utils/configfile.h"
#include "utils/logging.h"

namespace lczero {
    
    LeelaConnect::LeelaConnect()
    : bestMoveInfo(Move{}), engine_(std::bind(&LeelaConnect::BestMoveCallback, this, std::placeholders::_1),
    std::bind(&LeelaConnect::InfoCallback, this, std::placeholders::_1),
              options_.GetOptionsDict()) {
        engine_.PopulateOptions(&options_);
        // TODO: Some TECHDEBT, logging
        //    options_.Add<StringOption>(kLogFileId);
    }
    
    void LeelaConnect::SetupWeights(const std::string& weightsFilePath) {
        if (!ConfigFile::Init(&options_) || !options_.ProcessAllFlags()) return;
        options_.GetMutableOptions()->Set(NetworkFactory::kWeightsId.GetId(), weightsFilePath);
//        Logging::Get().SetFilename(options_.GetOptionsDict().Get<std::string>(foo));
    }
    
    // Here are the move callbacks
    
    void LeelaConnect::BestMoveCallback(const BestMoveInfo& move) {
        
        // This string processing is only for logging
        std::string res = "bestmove " + move.bestmove.as_string();
        if (move.ponder) res += " ponder " + move.ponder.as_string();
        if (move.player != -1) res += " player " + std::to_string(move.player);
        if (move.game_id != -1) res += " gameid " + std::to_string(move.game_id);
        if (move.is_black)
            res += " side " + std::string(*move.is_black ? "black" : "white");
        SendResponse(res);
        
        // Send the best move back up the chain
        bestMoveInfo = move;
        if (bestMoveBlock)
            bestMoveBlock();
    }
    
    void LeelaConnect::InfoCallback(const std::vector<ThinkingInfo>& infos) {
        std::vector<std::string> reses;
        
        // This string processing is only for logging
        for (const auto& info : infos) {
            std::string res = "info";
            if (info.player != -1) res += " player " + std::to_string(info.player);
            if (info.game_id != -1) res += " gameid " + std::to_string(info.game_id);
            if (info.is_black)
                res += " side " + std::string(*info.is_black ? "black" : "white");
            if (info.depth >= 0) res += " depth " + std::to_string(info.depth);
            if (info.seldepth >= 0) res += " seldepth " + std::to_string(info.seldepth);
            if (info.time >= 0) res += " time " + std::to_string(info.time);
            if (info.nodes >= 0) res += " nodes " + std::to_string(info.nodes);
            if (info.score) res += " score cp " + std::to_string(*info.score);
            if (info.hashfull >= 0) res += " hashfull " + std::to_string(info.hashfull);
            if (info.nps >= 0) res += " nps " + std::to_string(info.nps);
            if (info.tb_hits >= 0) res += " tbhits " + std::to_string(info.tb_hits);
            if (info.multipv >= 0) res += " multipv " + std::to_string(info.multipv);
            
            if (!info.pv.empty()) {
                res += " pv";
                for (const auto& move : info.pv) res += " " + move.as_string();
            }
            if (!info.comment.empty()) res += " string " + info.comment;
            reses.push_back(std::move(res));
        }
        SendResponses(reses);
        
        // Send our raw responses up the chain.
        thinkingInfos = infos;
        if (thoughtBlock)
            thoughtBlock();
    }
    // Here are the engine command helpers
    
    void LeelaConnect::CmdUci() {
        SendId();
        for (const auto& option : options_.ListOptionsUci()) {
            SendResponse(option);
        }
        SendResponse("uciok");
    }
    
    void LeelaConnect::CmdIsReady() {
        engine_.EnsureReady();
        SendResponse("readyok");
    }
    
    void LeelaConnect::CmdSetOption(const std::string& name, const std::string& value,
                                    const std::string& context) {
        options_.SetUciOption(name, value, context);
        // Set the log filename for the case it was set in UCI option.
        // TODO: logging
//        Logging::Get().SetFilename(options_.GetOptionsDict().Get<std::string>(kLogFileId.GetId()));
    }
    
    void LeelaConnect::CmdUciNewGame() { engine_.NewGame(); }
    
    void LeelaConnect::CmdPosition(const std::string& position,
                                   const std::vector<std::string>& moves) {
        std::string fen = position;
        if (fen.empty()) fen = ChessBoard::kStartposFen;
        engine_.SetPosition(fen, moves);
    }
    
    void LeelaConnect::CmdGo(const GoParams& params) { engine_.Go(params); }
    
    void LeelaConnect::CmdPonderHit() { engine_.PonderHit(); }
    
    void LeelaConnect::CmdStop() { engine_.Stop(); }
    
    void LeelaConnect::setBestMoveBlock(dispatch_block_t completion) {
        bestMoveBlock = dispatch_block_create(DISPATCH_BLOCK_DETACHED, completion);
    }
    
    void LeelaConnect::setThoughtBlock(dispatch_block_t completion) {
        thoughtBlock = dispatch_block_create(DISPATCH_BLOCK_DETACHED, completion);
    }

}  // namespace lczero

