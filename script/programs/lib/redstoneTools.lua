

local function ReadLabeledCableState(labeledCableStates, side)
    local compositeState = rs.getBundledInput(side);
    local newState = {};
    for name, colorBit in pairs(labeledCableStates) do
        newState[name] = (bit.band(bit.blshift(1, colorBit), compositeState)) ~= 0
    end
    return newState;
end

return {
    ReadLabeledCableState = ReadLabeledCableState,
}