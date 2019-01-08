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

#pragma once

#ifndef LeelaConnect_hpp
#define LeelaConnect_hpp

#include <stdio.h>
#include <vector>
#include <dispatch/dispatch.h>
#include "engine.h"
#include "chess/uciloop.h"
#include "mcts/search.h"
#include "neural/cache.h"
#include "neural/factory.h"
#include "neural/network.h"
#include "syzygy/syzygy.h"
#include "utils/mutex.h"
#include "utils/optional.h"
#include "utils/optionsparser.h"

namespace lczero {

class LeelaConnect : public UciLoop {
public:
    LeelaConnect();
    
    // We expose these vars because our block callbacks are parameterless.
    // Therefore they may get stale, they should only be used within the callbacks they are meant for.
    std::vector<ThinkingInfo> thinkingInfos;
    BestMoveInfo bestMoveInfo;
    
    void setBestMoveBlock(dispatch_block_t completion);
    void setThoughtBlock(dispatch_block_t completion);

    // Note we intentionally don't override the runloop, we are a library and the runloop should be implemented in the app's architechture.
//    void RunLoop() override;
    
    void SetupWeights(const std::string& weightsFilePath);
    void CmdUci() override;
    void CmdIsReady() override;
    void CmdSetOption(const std::string& name, const std::string& value,
                      const std::string& context) override;
    void CmdUciNewGame() override;
    void CmdPosition(const std::string& position,
                     const std::vector<std::string>& moves) override;
    void CmdGo(const GoParams& params) override;
    void CmdPonderHit() override;
    void CmdStop() override;
    
private:
    void BestMoveCallback(const BestMoveInfo& move);
    void InfoCallback(const std::vector<ThinkingInfo>& infos);
    dispatch_block_t thoughtBlock;
    dispatch_block_t bestMoveBlock;
    OptionsParser options_;
    EngineController engine_;
};

}  // namespace lczero

#endif /* LeelaConnect_hpp */
