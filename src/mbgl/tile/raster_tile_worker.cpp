#include <mbgl/tile/raster_tile_worker.hpp>
#include <mbgl/tile/raster_tile.hpp>
#include <mbgl/renderer/raster_bucket.cpp>
#include <mbgl/actor/actor.hpp>

namespace mbgl {

RasterTileWorker::RasterTileWorker(ActorRef<RasterTile> tile_)
    : tile(std::move(tile_)) {
}

void RasterTileWorker::parse(std::shared_ptr<const std::string> data) {
    if (!data) {
        tile.invoke(&RasterTile::onParsed, nullptr); // No data; empty tile.
        return;
    }

    auto bucket = std::make_unique<RasterBucket>();
    bucket->setImage(decodeImage(*data));
    tile.invoke(&RasterTile::onParsed, std::move(bucket));
}

} // namespace mbgl
