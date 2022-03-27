return {
    FUEL_CHEST_COORDS_IN_CHUNK = vector.new(8, 13, 8),
    NAVIGATION_LAYER_ALLOCATION = 10,
    NAVIGATIONN_LAYER_MIN = 14,
    QUARRY_MIN = 5,
    MESH_LAYER_MIN = 11,
    MESH_LAYER_MAX = 14,
    INVENTORY_SLOTS = {
        -- inventory up to 10 is reserved for fuel
        -- data slot 1 and 2 are for flags
        FUEL_MAX_SLOT = 10,
        SUCC_PROTECTION_SLOT_BEGIN = 20,
        SUCC_PROTECTION_SLOT_END = 25,
        DATA_SLOT_1 = 26,
        DATA_SLOT_2 = 27
    },
    CHUNK_STATUS = {
        WILDERNESS = 0,
        FUELED = 1,
        MESH_QUARRIED=2,
        COMPLETELY_MINED = 20
    }
}