#include <mbgl/tile/geometry_tile_worker.hpp>
#include <mbgl/tile/geometry_tile_data.hpp>
#include <mbgl/tile/geometry_tile.hpp>
#include <mbgl/text/collision_tile.hpp>
#include <mbgl/layout/symbol_layout.hpp>
#include <mbgl/style/bucket_parameters.hpp>
#include <mbgl/style/layers/symbol_layer.hpp>
#include <mbgl/style/layers/symbol_layer_impl.hpp>
#include <mbgl/sprite/sprite_atlas.hpp>
#include <mbgl/geometry/glyph_atlas.hpp>
#include <mbgl/renderer/symbol_bucket.hpp>
#include <mbgl/platform/log.hpp>
#include <mbgl/util/constants.hpp>
#include <mbgl/util/string.hpp>
#include <mbgl/util/exception.hpp>

#include <unordered_set>

namespace mbgl {

using namespace style;

GeometryTileWorker::GeometryTileWorker(OverscaledTileID id_,
                                       SpriteStore& spriteStore_,
                                       GlyphAtlas& glyphAtlas_,
                                       GlyphStore& glyphStore_,
                                       const std::atomic<bool>& obsolete_,
                                       const MapMode mode_,
                                       ActorRef<GeometryTile> tile_)
    : id(std::move(id_)),
      spriteStore(spriteStore_),
      glyphAtlas(glyphAtlas_),
      glyphStore(glyphStore_),
      obsolete(obsolete_),
      mode(mode_),
      tile(tile_) {
}

GeometryTileWorker::~GeometryTileWorker() {
    glyphAtlas.removeGlyphs(reinterpret_cast<uintptr_t>(this));
}

void GeometryTileWorker::setData(std::unique_ptr<const GeometryTileData> data_) {
    data = std::move(data_);
    redoLayout();
}

void GeometryTileWorker::setLayers(std::vector<std::unique_ptr<Layer>> layers_) {
    layers = std::move(layers_);
    redoLayout();
}

void GeometryTileWorker::setPlacementConfig(PlacementConfig placementConfig_) {
    if (placementConfig == placementConfig_) {
        return;
    }
    placementConfig = std::move(placementConfig_);
    attemptPlacement();
}

void GeometryTileWorker::redoLayout() {
    if (!data || !layers) {
        return;
    }

    // We're doing a fresh parse of the tile, because the underlying data or style has changed.
    symbolLayouts.clear();

    // We're storing a set of bucket names we've parsed to avoid parsing a bucket twice that is
    // referenced from more than one layer
    std::unordered_set<std::string> parsed;
    std::unordered_map<std::string, std::unique_ptr<Bucket>> buckets;
    auto featureIndex = std::make_unique<FeatureIndex>();

    for (auto i = layers->rbegin(); i != layers->rend(); i++) {
        if (obsolete) {
            return;
        }

        const Layer* layer = i->get();
        const std::string& bucketName = layer->baseImpl->bucketName();

        featureIndex->addBucketLayerName(bucketName, layer->baseImpl->id);

        if (parsed.find(bucketName) != parsed.end()) {
            continue;
        }

        parsed.emplace(bucketName);

        if (!*data) {
            continue; // Tile has no data.
        }

        auto geometryLayer = (*data)->getLayer(layer->baseImpl->sourceLayer);
        if (!geometryLayer) {
            continue;
        }

        BucketParameters parameters(id,
                                    *geometryLayer,
                                    obsolete,
                                    reinterpret_cast<uintptr_t>(this),
                                    spriteStore,
                                    glyphAtlas,
                                    glyphStore,
                                    *featureIndex,
                                    mode);

        if (layer->is<SymbolLayer>()) {
            symbolLayouts.push_back(layer->as<SymbolLayer>()->impl->createLayout(parameters));
        } else {
            std::unique_ptr<Bucket> bucket = layer->baseImpl->createBucket(parameters);
            if (bucket->hasData()) {
                buckets.emplace(layer->baseImpl->bucketName(), std::move(bucket));
            }
        }
    }

    tile.invoke(&GeometryTile::onLayout, GeometryTile::LayoutResult {
        std::move(buckets),
        std::move(featureIndex),
        *data ? (*data)->clone() : nullptr
    });

    attemptPlacement();
}

void GeometryTileWorker::attemptPlacement() {
    if (!data || !layers || !placementConfig) {
        return;
    }

    bool canPlace = true;

    // Prepare as many SymbolLayouts as possible.
    for (auto& symbolLayout : symbolLayouts) {
        if (obsolete) {
            return;
        }

        if (symbolLayout->state == SymbolLayout::Pending) {
            if (symbolLayout->canPrepare(glyphStore, spriteStore)) {
                symbolLayout->state = SymbolLayout::Prepared;
                symbolLayout->prepare(reinterpret_cast<uintptr_t>(this),
                                      glyphAtlas,
                                      glyphStore);
            } else {
                canPlace = false;
            }
        }
    }

    if (!canPlace) {
        return;
    }

    auto collisionTile = std::make_unique<CollisionTile>(*placementConfig);
    std::unordered_map<std::string, std::unique_ptr<Bucket>> buckets;

    for (auto& symbolLayout : symbolLayouts) {
        if (obsolete) {
            return;
        }

        symbolLayout->state = SymbolLayout::Placed;
        std::unique_ptr<Bucket> bucket = symbolLayout->place(*collisionTile);
        if (bucket->hasData() || symbolLayout->hasSymbolInstances()) {
            buckets.emplace(symbolLayout->bucketName, std::move(bucket));
        }
    }

    tile.invoke(&GeometryTile::onPlacement, GeometryTile::PlacementResult {
        std::move(buckets),
        std::move(collisionTile)
    });
}

} // namespace mbgl
