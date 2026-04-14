macroScript NeoDex_KeyframeOptimizer
buttonText:"Keyframe Optimizer"
category:"NeoDex Toolkit"
internalCategory:"NeoDex Toolkit"
(
    local scriptDir = (systemTools.getEnvVariable "APPDATA") + "\\Autodesk\\ApplicationPlugins\\NeoDex\\extra tools\\"
    local scriptFile = scriptDir + "Keyframe_Optimizer.ms"
    if doesFileExist scriptFile then
        fileIn scriptFile
    else
        messageBox ("Keyframe_Optimizer.ms not found:\n" + scriptFile) title:"NeoDex"
)
