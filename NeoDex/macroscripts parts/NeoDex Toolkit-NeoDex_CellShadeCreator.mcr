macroScript NeoDex_CellShadeCreator
buttonText:"Cell Shade Creator"
category:"NeoDex Toolkit"
internalCategory:"NeoDex Toolkit"
(
    local scriptDir = (systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\extra tools\\"
    local scriptFile = scriptDir + "Cell_Shade_Creator.ms"
    if doesFileExist scriptFile then
        fileIn scriptFile
    else
        messageBox ("Cell_Shade_Creator.ms not found:\n" + scriptFile) title:"NeoDex"
)
