#pragma once

#include <mbgl/map/mode.hpp>
#include <mbgl/tile/tile_id.hpp>
#include <mbgl/text/placement_config.hpp>
#include <mbgl/actor/actor_ref.hpp>
#include <mbgl/util/optional.hpp>

#include <atomic>
#include <memory>
#include <unordered_map>

namespace mbgl {

class GeometryTile;
class GeometryTileData;
class SpriteStore;
class GlyphAtlas;
class GlyphStore;
class SymbolLayout;

namespace style {
class Layer;
} // namespace style

class GeometryTileWorker {
public:
    GeometryTileWorker(OverscaledTileID,
                       SpriteStore&,
                       GlyphAtlas&,
                       GlyphStore&,
                       const std::atomic<bool>&,
                       const MapMode,
                       ActorRef<GeometryTile>);
    ~GeometryTileWorker();

    void setLayers(std::vector<std::unique_ptr<style::Layer>>);
    void setData(std::unique_ptr<const GeometryTileData>);
    void setPlacementConfig(PlacementConfig);

private:
    void redoLayout();
    void attemptPlacement();

    const OverscaledTileID id;
    SpriteStore& spriteStore;
    GlyphAtlas& glyphAtlas;
    GlyphStore& glyphStore;
    const std::atomic<bool>& obsolete;
    const MapMode mode;
    ActorRef<GeometryTile> tile;

    // Outer optional indicates whether we've received it or not.
    optional<std::vector<std::unique_ptr<style::Layer>>> layers;
    optional<std::unique_ptr<const GeometryTileData>> data;
    optional<PlacementConfig> placementConfig;

    std::vector<std::unique_ptr<SymbolLayout>> symbolLayouts;
};

} // namespace mbgl
