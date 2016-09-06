#include <mbgl/tile/geometry_tile.hpp>
#include <mbgl/tile/geometry_tile_worker.hpp>
#include <mbgl/tile/geometry_tile_data.hpp>
#include <mbgl/tile/tile_observer.hpp>
#include <mbgl/style/update_parameters.hpp>
#include <mbgl/style/layer_impl.hpp>
#include <mbgl/style/layers/background_layer.hpp>
#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/storage/file_source.hpp>
#include <mbgl/geometry/feature_index.hpp>
#include <mbgl/text/collision_tile.hpp>
#include <mbgl/map/transform_state.hpp>
#include <mbgl/util/run_loop.hpp>

namespace mbgl {

using namespace style;

GeometryTile::GeometryTile(const OverscaledTileID& id_,
                           std::string sourceID_,
                           const style::UpdateParameters& parameters)
    : Tile(id_),
      sourceID(std::move(sourceID_)),
      style(parameters.style),
      self(*util::RunLoop::Get(), *this),
      worker(parameters.workerScheduler,
             id_,
             *parameters.style.spriteStore,
             *parameters.style.glyphAtlas,
             *parameters.style.glyphStore,
             obsolete,
             parameters.mode,
             self) {
}

GeometryTile::~GeometryTile() {
    cancel();
}

void GeometryTile::cancel() {
    obsolete = true;
}

void GeometryTile::setError(std::exception_ptr err) {
    availableData = DataAvailability::All;
    observer->onTileError(*this, err);
}

void GeometryTile::setData(std::unique_ptr<const GeometryTileData> data_) {
    // Mark the tile as pending again if it was complete before to prevent signaling a complete
    // state despite pending parse operations.
    if (availableData == DataAvailability::All) {
        availableData = DataAvailability::Some;
    }

    worker.invoke(&GeometryTileWorker::setData, std::move(data_));
    redoLayout();
}

void GeometryTile::setPlacementConfig(const PlacementConfig& config) {
    worker.invoke(&GeometryTileWorker::setPlacementConfig, config);
}

void GeometryTile::redoLayout() {
    // Mark the tile as pending again if it was complete before to prevent signaling a complete
    // state despite pending parse operations.
    if (availableData == DataAvailability::All) {
        availableData = DataAvailability::Some;
    }

    std::vector<std::unique_ptr<Layer>> copy;

    for (const Layer* layer : style.getLayers()) {
        // Avoid cloning and including irrelevant layers.
        if (layer->is<BackgroundLayer>() ||
            layer->is<CustomLayer>() ||
            layer->baseImpl->source != sourceID ||
            id.overscaledZ < std::floor(layer->baseImpl->minZoom) ||
            id.overscaledZ >= std::ceil(layer->baseImpl->maxZoom) ||
            layer->baseImpl->visibility == VisibilityType::None) {
            continue;
        }

        copy.push_back(layer->baseImpl->clone());
    }

    worker.invoke(&GeometryTileWorker::setLayers, std::move(copy));
}

void GeometryTile::onLayout(LayoutResult result) {
    availableData = DataAvailability::Some;
    buckets = std::move(result.buckets);
    featureIndex = std::move(result.featureIndex);
    data = std::move(result.tileData);
    observer->onTileChanged(*this);
}

void GeometryTile::onPlacement(PlacementResult result) {
    availableData = DataAvailability::All;
    for (auto& bucket : result.buckets) {
        buckets[bucket.first] = std::move(bucket.second);
    }
    featureIndex->setCollisionTile(std::move(result.collisionTile));
    observer->onTileChanged(*this);
}

Bucket* GeometryTile::getBucket(const Layer& layer) {
    const auto it = buckets.find(layer.baseImpl->bucketName());
    if (it == buckets.end()) {
        return nullptr;
    }

    assert(it->second);
    return it->second.get();
}

void GeometryTile::queryRenderedFeatures(
    std::unordered_map<std::string, std::vector<Feature>>& result,
    const GeometryCoordinates& queryGeometry,
    const TransformState& transformState,
    const optional<std::vector<std::string>>& layerIDs) {

    if (!featureIndex || !data) return;

    featureIndex->query(result,
                        { queryGeometry },
                        transformState.getAngle(),
                        util::tileSize * id.overscaleFactor(),
                        std::pow(2, transformState.getZoom() - id.overscaledZ),
                        layerIDs,
                        *data,
                        id.canonical,
                        style);
}

} // namespace mbgl
