#pragma once

#include <mbgl/actor/actor_ref.hpp>

#include <memory>
#include <string>

namespace mbgl {

class RasterTile;

class RasterTileWorker {
public:
    RasterTileWorker(ActorRef<RasterTile>);

    void parse(std::shared_ptr<const std::string> data);

private:
    ActorRef<RasterTile> tile;
};

} // namespace mbgl
