

ExposedMembers.hasEldenAPI = false

function InitializeEldenAPIGeneral()
    if not ExposedMembers.EldenAPI then ExposedMembers.EldenAPI = {} end
    ExposedMembers.EldenAPI.version = "0.1"
    ExposedMembers.hasEldenAPI = true
end

InitializeEldenAPIGeneral()